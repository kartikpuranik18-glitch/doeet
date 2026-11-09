import { initializeApp } from 'firebase-admin/app';
import { FieldValue, Timestamp, getFirestore } from 'firebase-admin/firestore';
import { getAuth } from 'firebase-admin/auth';
import { HttpsError, onCall } from 'firebase-functions/v2/https';

initializeApp();
const db = getFirestore();

const allowedRoles = new Set([
  'learner', 'job_seeker', 'employee', 'mentor', 'instructor', 'employer',
  'recruiter', 'agency', 'institution', 'company_admin', 'platform_admin',
]);

function requireAuth(uid: string | undefined): asserts uid is string {
  if (!uid) throw new HttpsError('unauthenticated', 'Sign in is required.');
}

function requirePlatformAdmin(roles: unknown): void {
  if (!Array.isArray(roles) || !roles.includes('platform_admin')) {
    throw new HttpsError('permission-denied', 'Platform administrator access is required.');
  }
}

/**
 * Privileged role grants can only happen from a trusted environment. The
 * function updates both the identity claim and profile document atomically
 * enough for Firestore rules and the Flutter navigator to agree on access.
 */
export const assignRole = onCall(async (request) => {
  requireAuth(request.auth?.uid);
  requirePlatformAdmin(request.auth?.token.roles);
  const uid = request.data?.uid;
  const role = request.data?.role;
  if (typeof uid !== 'string' || !allowedRoles.has(role)) {
    throw new HttpsError('invalid-argument', 'A valid user ID and role are required.');
  }

  const userRef = db.collection('users').doc(uid);
  const profile = await userRef.get();
  if (!profile.exists) throw new HttpsError('not-found', 'DOEET profile not found.');
  const roles = new Set<string>(Array.isArray(profile.data()?.roles)
    ? profile.data()!.roles as string[] : ['learner']);
  roles.add(role);
  const nextRoles = [...roles];
  await Promise.all([
    getAuth().setCustomUserClaims(uid, { roles: nextRoles }),
    userRef.update({ roles: nextRoles, updatedAt: FieldValue.serverTimestamp() }),
    db.collection('auditLogs').add({
      action: 'role_assigned', actorUid: request.auth!.uid, subjectUid: uid,
      role, createdAt: FieldValue.serverTimestamp(),
    }),
  ]);
  return { roles: nextRoles };
});

/** Issues a certificate only after persisted course evidence satisfies policy. */
export const issueCertificate = onCall(async (request) => {
  requireAuth(request.auth?.uid);
  const courseId = request.data?.courseId;
  if (typeof courseId !== 'string' || courseId.isEmpty) {
    throw new HttpsError('invalid-argument', 'A course ID is required.');
  }
  const uid = request.auth!.uid;
  const courseRef = db.collection('users').doc(uid).collection('courses').doc(courseId);
  const course = await courseRef.get();
  if (!course.exists) throw new HttpsError('not-found', 'Course not found.');
  const data = course.data()!;
  const finalScore = Number(data.finalAssessmentScore ?? 0);
  const eligible = data.progress === 1 && data.assignmentsComplete === true &&
    data.projectComplete === true && data.finalAssessmentPassed === true && finalScore >= 60;
  if (!eligible) {
    throw new HttpsError('failed-precondition',
      'Complete lessons, assignment, project, and passing final assessment first.');
  }

  const certificateId = `DOEET-${new Date().getUTCFullYear()}-${courseId.slice(-6).toUpperCase()}-${uid.slice(-6).toUpperCase()}`;
  const certificateRef = db.collection('users').doc(uid).collection('certificates').doc(certificateId);
  const verificationRef = db.collection('certificateVerifications').doc(certificateId);
  await db.runTransaction(async (transaction) => {
    if ((await transaction.get(certificateRef)).exists) return;
    const certificate = {
      certificateId, courseId, courseTitle: String(data.title ?? 'DOEET course'),
      skills: Array.isArray(data.skills) ? data.skills : [], score: finalScore,
      issuedAt: Timestamp.now(), verificationPath: `/certificate/${certificateId}`,
    };
    transaction.set(certificateRef, certificate);
    transaction.set(verificationRef, {
      certificateId, courseTitle: certificate.courseTitle, issuedAt: certificate.issuedAt,
      status: 'valid',
    });
    transaction.update(courseRef, {
      certificateId, completedAt: FieldValue.serverTimestamp(), status: 'completed',
    });
    transaction.set(db.collection('users').doc(uid).collection('skillEvidence').doc(courseId), {
      source: 'certificate', courseId, certificateId, skills: certificate.skills,
      score: finalScore, createdAt: FieldValue.serverTimestamp(),
    });
  });
  return { certificateId };
});

/**
 * Creates matching learner/company application records after consent checks.
 * The client never writes directly into a company's hiring pipeline.
 */
export const submitApplication = onCall(async (request) => {
  requireAuth(request.auth?.uid);
  const companyId = request.data?.companyId;
  const jobId = request.data?.jobId;
  if (typeof companyId !== 'string' || typeof jobId !== 'string') {
    throw new HttpsError('invalid-argument', 'Company and job IDs are required.');
  }
  const uid = request.auth!.uid;
  const [job, careerProfile] = await Promise.all([
    db.collection('companies').doc(companyId).collection('jobs').doc(jobId).get(),
    db.collection('users').doc(uid).collection('careerProfiles').doc('primary').get(),
  ]);
  if (!job.exists || job.data()?.status !== 'published') {
    throw new HttpsError('not-found', 'This job is not accepting applications.');
  }
  if (careerProfile.data()?.applicationConsent !== true) {
    throw new HttpsError('failed-precondition',
      'Review your career profile and explicitly consent before applying.');
  }
  const applicationRef = db.collection('companies').doc(companyId).collection('applications').doc();
  const applicantRef = db.collection('users').doc(uid).collection('applications').doc(applicationRef.id);
  const application = {
    applicationId: applicationRef.id, companyId, jobId, applicantUid: uid,
    status: 'applied', createdAt: FieldValue.serverTimestamp(), updatedAt: FieldValue.serverTimestamp(),
  };
  const batch = db.batch();
  batch.set(applicationRef, application);
  batch.set(applicantRef, application);
  await batch.commit();
  return { applicationId: applicationRef.id, status: 'applied' };
});
