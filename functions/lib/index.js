"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.updateApplicationStage = exports.createJob = exports.createCompany = exports.submitApplication = exports.issueCertificate = exports.approveCompanyAccess = exports.requestCompanyAccess = exports.assignRole = void 0;
const app_1 = require("firebase-admin/app");
const firestore_1 = require("firebase-admin/firestore");
const auth_1 = require("firebase-admin/auth");
const https_1 = require("firebase-functions/v2/https");
(0, app_1.initializeApp)();
const db = (0, firestore_1.getFirestore)();
const allowedRoles = new Set([
    'learner', 'job_seeker', 'employee', 'mentor', 'instructor', 'employer',
    'recruiter', 'agency', 'institution', 'company_admin', 'platform_admin',
]);
function requireAuth(uid) {
    if (!uid)
        throw new https_1.HttpsError('unauthenticated', 'Sign in is required.');
}
function requirePlatformAdmin(roles) {
    if (!Array.isArray(roles) || !roles.includes('platform_admin')) {
        throw new https_1.HttpsError('permission-denied', 'Platform administrator access is required.');
    }
}
const companyRoles = new Set(['employer', 'recruiter', 'agency', 'institution', 'company_admin']);
function requireCompanyRole(roles) {
    if (!Array.isArray(roles) || !roles.some((role) => companyRoles.has(role))) {
        throw new https_1.HttpsError('permission-denied', 'Company role approval is required.');
    }
}
async function requireCompanyManager(uid, companyId) {
    const member = await db.collection('companies').doc(companyId).collection('members').doc(uid).get();
    if (!member.exists || !['owner', 'admin', 'recruiter'].includes(member.data()?.role)) {
        throw new https_1.HttpsError('permission-denied', 'Company manager access is required.');
    }
}
/**
 * Privileged role grants can only happen from a trusted environment. The
 * function updates both the identity claim and profile document atomically
 * enough for Firestore rules and the Flutter navigator to agree on access.
 */
exports.assignRole = (0, https_1.onCall)(async (request) => {
    requireAuth(request.auth?.uid);
    requirePlatformAdmin(request.auth?.token.roles);
    const uid = request.data?.uid;
    const role = request.data?.role;
    if (typeof uid !== 'string' || !allowedRoles.has(role)) {
        throw new https_1.HttpsError('invalid-argument', 'A valid user ID and role are required.');
    }
    const userRef = db.collection('users').doc(uid);
    const profile = await userRef.get();
    if (!profile.exists)
        throw new https_1.HttpsError('not-found', 'DOEET profile not found.');
    const roles = new Set(Array.isArray(profile.data()?.roles)
        ? profile.data().roles : ['learner']);
    roles.add(role);
    const nextRoles = [...roles];
    await Promise.all([
        (0, auth_1.getAuth)().setCustomUserClaims(uid, { roles: nextRoles }),
        userRef.update({ roles: nextRoles, updatedAt: firestore_1.FieldValue.serverTimestamp() }),
        db.collection('auditLogs').add({
            action: 'role_assigned', actorUid: request.auth.uid, subjectUid: uid,
            role, createdAt: firestore_1.FieldValue.serverTimestamp(),
        }),
    ]);
    return { roles: nextRoles };
});
exports.requestCompanyAccess = (0, https_1.onCall)(async (request) => {
    requireAuth(request.auth?.uid);
    const role = request.data?.role;
    if (!['employer', 'recruiter', 'agency', 'institution', 'company_admin'].includes(role)) {
        throw new https_1.HttpsError('invalid-argument', 'A valid company role is required.');
    }
    const uid = request.auth.uid;
    await db.collection('companyAccessRequests').doc(uid).set({
        uid,
        requestedRole: role,
        status: 'pending',
        requestedAt: firestore_1.FieldValue.serverTimestamp(),
    });
    await db.collection('auditLogs').add({
        action: 'company_access_requested',
        actorUid: uid,
        role,
        createdAt: firestore_1.FieldValue.serverTimestamp(),
    });
    return { status: 'pending' };
});
exports.approveCompanyAccess = (0, https_1.onCall)(async (request) => {
    requireAuth(request.auth?.uid);
    requirePlatformAdmin(request.auth?.token.roles);
    const uid = request.data?.uid;
    const role = request.data?.role;
    if (typeof uid !== 'string' ||
        !['employer', 'recruiter', 'agency', 'institution', 'company_admin'].includes(role)) {
        throw new https_1.HttpsError('invalid-argument', 'A valid user and company role are required.');
    }
    const userRef = db.collection('users').doc(uid);
    const profile = await userRef.get();
    if (!profile.exists)
        throw new https_1.HttpsError('not-found', 'DOEET profile not found.');
    const roles = new Set(Array.isArray(profile.data()?.roles)
        ? profile.data().roles : ['learner']);
    roles.add(role);
    const nextRoles = [...roles];
    await Promise.all([
        (0, auth_1.getAuth)().setCustomUserClaims(uid, { roles: nextRoles }),
        userRef.update({
            roles: nextRoles,
            activeWorkspace: 'company',
            updatedAt: firestore_1.FieldValue.serverTimestamp(),
        }),
        db.collection('companyAccessRequests').doc(uid).set({
            uid,
            requestedRole: role,
            status: 'approved',
            approvedBy: request.auth.uid,
            approvedAt: firestore_1.FieldValue.serverTimestamp(),
        }, { merge: true }),
    ]);
    return { roles: nextRoles };
});
/** Issues a certificate only after persisted course evidence satisfies policy. */
exports.issueCertificate = (0, https_1.onCall)(async (request) => {
    requireAuth(request.auth?.uid);
    const courseId = request.data?.courseId;
    if (typeof courseId !== 'string' || courseId.trim().length === 0) {
        throw new https_1.HttpsError('invalid-argument', 'A course ID is required.');
    }
    const uid = request.auth.uid;
    const courseRef = db.collection('users').doc(uid).collection('courses').doc(courseId);
    const course = await courseRef.get();
    if (!course.exists)
        throw new https_1.HttpsError('not-found', 'Course not found.');
    const data = course.data();
    const finalScore = Number(data.finalAssessmentScore ?? 0);
    const eligible = data.progress === 1 && data.assignmentsComplete === true &&
        data.projectComplete === true && data.finalAssessmentPassed === true && finalScore >= 60;
    if (!eligible) {
        throw new https_1.HttpsError('failed-precondition', 'Complete lessons, assignment, project, and passing final assessment first.');
    }
    const certificateId = `DOEET-${new Date().getUTCFullYear()}-${courseId.slice(-6).toUpperCase()}-${uid.slice(-6).toUpperCase()}`;
    const certificateRef = db.collection('users').doc(uid).collection('certificates').doc(certificateId);
    const verificationRef = db.collection('certificateVerifications').doc(certificateId);
    await db.runTransaction(async (transaction) => {
        if ((await transaction.get(certificateRef)).exists)
            return;
        const certificate = {
            certificateId, courseId, courseTitle: String(data.title ?? 'DOEET course'),
            skills: Array.isArray(data.skills) ? data.skills : [], score: finalScore,
            issuedAt: firestore_1.Timestamp.now(), verificationPath: `/certificate/${certificateId}`,
        };
        transaction.set(certificateRef, certificate);
        transaction.set(verificationRef, {
            certificateId, courseTitle: certificate.courseTitle, issuedAt: certificate.issuedAt,
            status: 'valid',
        });
        transaction.update(courseRef, {
            certificateId, completedAt: firestore_1.FieldValue.serverTimestamp(), status: 'completed',
        });
        transaction.set(db.collection('users').doc(uid).collection('skillEvidence').doc(courseId), {
            source: 'certificate', courseId, certificateId, skills: certificate.skills,
            score: finalScore, createdAt: firestore_1.FieldValue.serverTimestamp(),
        });
    });
    return { certificateId };
});
/**
 * Creates matching learner/company application records after consent checks.
 * The client never writes directly into a company's hiring pipeline.
 */
exports.submitApplication = (0, https_1.onCall)(async (request) => {
    requireAuth(request.auth?.uid);
    const companyId = request.data?.companyId;
    const jobId = request.data?.jobId;
    if (typeof companyId !== 'string' || typeof jobId !== 'string') {
        throw new https_1.HttpsError('invalid-argument', 'Company and job IDs are required.');
    }
    const uid = request.auth.uid;
    const [job, careerProfile] = await Promise.all([
        db.collection('companies').doc(companyId).collection('jobs').doc(jobId).get(),
        db.collection('users').doc(uid).collection('careerProfiles').doc('primary').get(),
    ]);
    if (!job.exists || job.data()?.status !== 'published') {
        throw new https_1.HttpsError('not-found', 'This job is not accepting applications.');
    }
    if (careerProfile.data()?.applicationConsent !== true) {
        throw new https_1.HttpsError('failed-precondition', 'Review your career profile and explicitly consent before applying.');
    }
    const applicationRef = db.collection('companies').doc(companyId).collection('applications').doc();
    const applicantRef = db.collection('users').doc(uid).collection('applications').doc(applicationRef.id);
    const application = {
        applicationId: applicationRef.id, companyId, jobId, applicantUid: uid,
        status: 'applied', createdAt: firestore_1.FieldValue.serverTimestamp(), updatedAt: firestore_1.FieldValue.serverTimestamp(),
    };
    const batch = db.batch();
    batch.set(applicationRef, application);
    batch.set(applicantRef, application);
    await batch.commit();
    return { applicationId: applicationRef.id, status: 'applied' };
});
exports.createCompany = (0, https_1.onCall)(async (request) => {
    requireAuth(request.auth?.uid);
    requireCompanyRole(request.auth?.token.roles);
    const name = typeof request.data?.name === 'string' ? request.data.name.trim() : '';
    const industry = typeof request.data?.industry === 'string' ? request.data.industry.trim() : '';
    if (name.length < 2 || name.length > 160) {
        throw new https_1.HttpsError('invalid-argument', 'Enter a valid company name.');
    }
    const uid = request.auth.uid;
    const existing = await db.collection('companies').where('ownerUid', '==', uid).limit(1).get();
    if (!existing.empty) {
        throw new https_1.HttpsError('already-exists', 'A company profile already exists for this account.');
    }
    const companyRef = db.collection('companies').doc();
    await db.runTransaction(async (transaction) => {
        transaction.set(companyRef, {
            name,
            industry: industry || 'Technology',
            ownerUid: uid,
            verificationStatus: 'pending',
            createdAt: firestore_1.FieldValue.serverTimestamp(),
            updatedAt: firestore_1.FieldValue.serverTimestamp(),
        });
        transaction.set(companyRef.collection('members').doc(uid), {
            uid,
            role: 'owner',
            addedAt: firestore_1.FieldValue.serverTimestamp(),
        });
    });
    return { companyId: companyRef.id };
});
exports.createJob = (0, https_1.onCall)(async (request) => {
    requireAuth(request.auth?.uid);
    requireCompanyRole(request.auth?.token.roles);
    const companyId = request.data?.companyId;
    const title = typeof request.data?.title === 'string' ? request.data.title.trim() : '';
    const location = typeof request.data?.location === 'string' ? request.data.location.trim() : '';
    const skills = Array.isArray(request.data?.skills)
        ? request.data.skills.filter((value) => typeof value === 'string').slice(0, 30)
        : [];
    if (typeof companyId !== 'string' || title.length < 3 || title.length > 160) {
        throw new https_1.HttpsError('invalid-argument', 'A valid company and job title are required.');
    }
    await requireCompanyManager(request.auth.uid, companyId);
    const jobRef = db.collection('companies').doc(companyId).collection('jobs').doc();
    await jobRef.set({
        title,
        location: location || 'Remote',
        skills,
        employmentType: 'Full-time',
        status: 'published',
        createdBy: request.auth.uid,
        createdAt: firestore_1.FieldValue.serverTimestamp(),
        updatedAt: firestore_1.FieldValue.serverTimestamp(),
    });
    return { jobId: jobRef.id };
});
exports.updateApplicationStage = (0, https_1.onCall)(async (request) => {
    requireAuth(request.auth?.uid);
    requireCompanyRole(request.auth?.token.roles);
    const companyId = request.data?.companyId;
    const applicationId = request.data?.applicationId;
    const status = request.data?.status;
    const allowed = new Set([
        'applied', 'screening', 'shortlisted', 'assessment',
        'interview', 'final_round', 'offer', 'hired', 'rejected', 'withdrawn',
    ]);
    if (typeof companyId !== 'string' || typeof applicationId !== 'string' ||
        typeof status !== 'string' || !allowed.has(status)) {
        throw new https_1.HttpsError('invalid-argument', 'A valid company, application, and stage are required.');
    }
    await requireCompanyManager(request.auth.uid, companyId);
    const companyAppRef = db.collection('companies').doc(companyId).collection('applications').doc(applicationId);
    const companyApp = await companyAppRef.get();
    if (!companyApp.exists)
        throw new https_1.HttpsError('not-found', 'Application not found.');
    const applicantUid = companyApp.data()?.applicantUid;
    if (typeof applicantUid !== 'string') {
        throw new https_1.HttpsError('failed-precondition', 'Applicant identity is missing.');
    }
    await db.runTransaction(async (transaction) => {
        transaction.update(companyAppRef, {
            status,
            updatedAt: firestore_1.FieldValue.serverTimestamp(),
        });
        transaction.update(db.collection('users').doc(applicantUid).collection('applications').doc(applicationId), { status, updatedAt: firestore_1.FieldValue.serverTimestamp() });
    });
    await db.collection('auditLogs').add({
        action: 'application_stage_changed',
        actorUid: request.auth.uid,
        companyId,
        applicationId,
        status,
        createdAt: firestore_1.FieldValue.serverTimestamp(),
    });
    return { status };
});
