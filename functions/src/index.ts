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

const companyRoles = new Set(['employer', 'recruiter', 'agency', 'institution', 'company_admin']);

function requireCompanyRole(roles: unknown): void {
  if (!Array.isArray(roles) || !roles.some((role) => companyRoles.has(role))) {
    throw new HttpsError('permission-denied', 'Company role approval is required.');
  }
}

async function requireCompanyManager(uid: string, companyId: string): Promise<void> {
  const member = await db.collection('companies').doc(companyId).collection('members').doc(uid).get();
  if (!member.exists || !['owner', 'admin', 'recruiter'].includes(member.data()?.role)) {
    throw new HttpsError('permission-denied', 'Company manager access is required.');
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

export const requestCompanyAccess = onCall(async (request) => {
  requireAuth(request.auth?.uid);
  const role = request.data?.role;
  if (!['employer', 'recruiter', 'agency', 'institution', 'company_admin'].includes(role)) {
    throw new HttpsError('invalid-argument', 'A valid company role is required.');
  }
  const uid = request.auth!.uid;
  await db.collection('companyAccessRequests').doc(uid).set({
    uid,
    requestedRole: role,
    status: 'pending',
    requestedAt: FieldValue.serverTimestamp(),
  });
  await db.collection('auditLogs').add({
    action: 'company_access_requested',
    actorUid: uid,
    role,
    createdAt: FieldValue.serverTimestamp(),
  });
  return { status: 'pending' };
});

export const approveCompanyAccess = onCall(async (request) => {
  requireAuth(request.auth?.uid);
  requirePlatformAdmin(request.auth?.token.roles);
  const uid = request.data?.uid;
  const role = request.data?.role;
  if (typeof uid !== 'string' ||
      !['employer', 'recruiter', 'agency', 'institution', 'company_admin'].includes(role)) {
    throw new HttpsError('invalid-argument', 'A valid user and company role are required.');
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
    userRef.update({
      roles: nextRoles,
      activeWorkspace: 'company',
      updatedAt: FieldValue.serverTimestamp(),
    }),
    db.collection('companyAccessRequests').doc(uid).set({
      uid,
      requestedRole: role,
      status: 'approved',
      approvedBy: request.auth!.uid,
      approvedAt: FieldValue.serverTimestamp(),
    }, { merge: true }),
  ]);
  return { roles: nextRoles };
});

/** Issues a certificate only after persisted course evidence satisfies policy. */
export const issueCertificate = onCall(async (request) => {
  requireAuth(request.auth?.uid);
  const courseId = request.data?.courseId;
  if (typeof courseId !== 'string' || courseId.trim().length === 0) {
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

export const createCompany = onCall(async (request) => {
  requireAuth(request.auth?.uid);
  requireCompanyRole(request.auth?.token.roles);
  const name = typeof request.data?.name === 'string' ? request.data.name.trim() : '';
  const industry = typeof request.data?.industry === 'string' ? request.data.industry.trim() : '';
  if (name.length < 2 || name.length > 160) {
    throw new HttpsError('invalid-argument', 'Enter a valid company name.');
  }
  const uid = request.auth!.uid;
  const existing = await db.collection('companies').where('ownerUid', '==', uid).limit(1).get();
  if (!existing.empty) {
    throw new HttpsError('already-exists', 'A company profile already exists for this account.');
  }
  const companyRef = db.collection('companies').doc();
  await db.runTransaction(async (transaction) => {
    transaction.set(companyRef, {
      name,
      industry: industry || 'Technology',
      ownerUid: uid,
      verificationStatus: 'pending',
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
    transaction.set(companyRef.collection('members').doc(uid), {
      uid,
      role: 'owner',
      addedAt: FieldValue.serverTimestamp(),
    });
  });
  return { companyId: companyRef.id };
});

export const createJob = onCall(async (request) => {
  requireAuth(request.auth?.uid);
  requireCompanyRole(request.auth?.token.roles);
  const companyId = request.data?.companyId;
  const title = typeof request.data?.title === 'string' ? request.data.title.trim() : '';
  const location = typeof request.data?.location === 'string' ? request.data.location.trim() : '';
  const skills = Array.isArray(request.data?.skills)
    ? request.data.skills.filter((value: unknown) => typeof value === 'string').slice(0, 30)
    : [];
  if (typeof companyId !== 'string' || title.length < 3 || title.length > 160) {
    throw new HttpsError('invalid-argument', 'A valid company and job title are required.');
  }
  await requireCompanyManager(request.auth!.uid, companyId);
  const jobRef = db.collection('companies').doc(companyId).collection('jobs').doc();
  await jobRef.set({
    title,
    location: location || 'Remote',
    skills,
    employmentType: 'Full-time',
    status: 'published',
    createdBy: request.auth!.uid,
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });
  return { jobId: jobRef.id };
});

export const updateApplicationStage = onCall(async (request) => {
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
    throw new HttpsError('invalid-argument', 'A valid company, application, and stage are required.');
  }
  await requireCompanyManager(request.auth!.uid, companyId);
  const companyAppRef = db.collection('companies').doc(companyId).collection('applications').doc(applicationId);
  const companyApp = await companyAppRef.get();
  if (!companyApp.exists) throw new HttpsError('not-found', 'Application not found.');
  const applicantUid = companyApp.data()?.applicantUid;
  if (typeof applicantUid !== 'string') {
    throw new HttpsError('failed-precondition', 'Applicant identity is missing.');
  }
  await db.runTransaction(async (transaction) => {
    transaction.update(companyAppRef, {
      status,
      updatedAt: FieldValue.serverTimestamp(),
    });
    transaction.update(
      db.collection('users').doc(applicantUid).collection('applications').doc(applicationId),
      { status, updatedAt: FieldValue.serverTimestamp() },
    );
  });
  await db.collection('auditLogs').add({
    action: 'application_stage_changed',
    actorUid: request.auth!.uid,
    companyId,
    applicationId,
    status,
    createdAt: FieldValue.serverTimestamp(),
  });
  return { status };
});

// ── Phase 1B: AI Mentor — Server-Side Proxy + Firestore Persistence ──────────

/**
 * Proxies chat messages to OpenAI GPT-4o and persists the full conversation
 * in Firestore so history survives page refreshes and the API key stays
 * server-side. Accepts { courseContext, message, chatId? }.
 */
export const chatWithMentor = onCall(async (request) => {
  requireAuth(request.auth?.uid);
  const uid = request.auth!.uid;

  const courseContext = typeof request.data?.courseContext === 'string'
    ? request.data.courseContext.trim() : '';
  const message = typeof request.data?.message === 'string'
    ? request.data.message.trim() : '';
  const incomingChatId: string | undefined = typeof request.data?.chatId === 'string'
    ? request.data.chatId : undefined;

  if (message.length === 0) {
    throw new HttpsError('invalid-argument', 'A non-empty message is required.');
  }
  if (message.length > 4000) {
    throw new HttpsError('invalid-argument', 'Message is too long (max 4000 characters).');
  }

  const apiKey = process.env.OPENAI_API_KEY;
  if (!apiKey) {
    throw new HttpsError('internal', 'OpenAI API key is not configured.');
  }

  const userRef = db.collection('users').doc(uid);
  const interactionsRef = userRef.collection('aiInteractions');

  // Resolve or create the chat document
  let chatId: string;
  let chatRef;
  if (incomingChatId) {
    chatRef = interactionsRef.doc(incomingChatId);
    const chatSnap = await chatRef.get();
    if (!chatSnap.exists) {
      throw new HttpsError('not-found', 'Chat session not found.');
    }
    chatId = incomingChatId;
  } else {
    chatRef = interactionsRef.doc();
    chatId = chatRef.id;
    await chatRef.set({
      courseContext,
      createdAt: FieldValue.serverTimestamp(),
    });
  }

  const messagesRef = chatRef.collection('messages');

  // Load last 10 persisted messages for context
  const historySnap = await messagesRef
    .orderBy('createdAt', 'desc')
    .limit(10)
    .get();
  const historyMessages: Array<{ role: string; content: string }> = historySnap.docs
    .reverse()
    .map((doc) => ({
      role: doc.data().role as string,
      content: doc.data().content as string,
    }));

  // Build request to OpenAI
  const systemPrompt =
    `You are DOEET AI Mentor, an expert educational assistant. ` +
    (courseContext
      ? `Context: ${courseContext}. `
      : '') +
    `Help the student learn by giving clear, concise, and accurate explanations. ` +
    `When appropriate, use examples, analogies, and step-by-step breakdowns.`;

  const openaiMessages = [
    { role: 'system', content: systemPrompt },
    ...historyMessages,
    { role: 'user', content: message },
  ];

  // Call OpenAI
  const openaiResponse = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${apiKey}`,
    },
    body: JSON.stringify({
      model: 'gpt-4o',
      messages: openaiMessages,
      max_tokens: 1500,
      temperature: 0.7,
    }),
  });

  if (!openaiResponse.ok) {
    const errText = await openaiResponse.text();
    console.error('OpenAI error:', errText);
    throw new HttpsError('internal', 'Failed to get a response from the AI model.');
  }

  const openaiData = await openaiResponse.json() as {
    choices: Array<{ message: { content: string } }>;
  };
  const reply = openaiData.choices?.[0]?.message?.content?.trim() ?? '';
  if (!reply) {
    throw new HttpsError('internal', 'Empty response from AI model.');
  }

  // Persist user message + assistant reply atomically
  const userMsgRef = messagesRef.doc();
  const assistantMsgRef = messagesRef.doc();
  const batch = db.batch();
  batch.set(userMsgRef, {
    role: 'user',
    content: message,
    createdAt: FieldValue.serverTimestamp(),
  });
  batch.set(assistantMsgRef, {
    role: 'assistant',
    content: reply,
    createdAt: FieldValue.serverTimestamp(),
  });
  await batch.commit();

  return { reply, chatId, messageId: assistantMsgRef.id };
});

// ── Phase 1C: Final Assessment Flow ──────────────────────────────────────────

/**
 * Grades a final assessment submission. Questions are loaded server-side from
 * either the user's course sub-collection or the platform question bank, so
 * correct answers are never exposed to the client.
 * Accepts { courseId, answers: Array<{questionId: string, selectedOption: number}> }
 */
export const submitFinalAssessment = onCall(async (request) => {
  requireAuth(request.auth?.uid);
  const uid = request.auth!.uid;

  const courseId = typeof request.data?.courseId === 'string'
    ? request.data.courseId.trim() : '';
  const answers: Array<{ questionId: string; selectedOption: number }> =
    Array.isArray(request.data?.answers) ? request.data.answers : [];

  if (courseId.length === 0) {
    throw new HttpsError('invalid-argument', 'A course ID is required.');
  }
  if (answers.length === 0) {
    throw new HttpsError('invalid-argument', 'At least one answer is required.');
  }

  // Load questions: try user-specific finalAssessment first, then platform bank
  const userAssessmentRef = db
    .collection('users').doc(uid)
    .collection('courses').doc(courseId)
    .collection('finalAssessment').doc('questions');
  const platformAssessmentRef = db
    .collection('platform')
    .doc('assessments')
    .collection(courseId).doc('questions');

  let questionsData: FirebaseFirestore.DocumentData | undefined;
  const userAssessmentSnap = await userAssessmentRef.get();
  if (userAssessmentSnap.exists) {
    questionsData = userAssessmentSnap.data();
  } else {
    const platformSnap = await platformAssessmentRef.get();
    if (platformSnap.exists) {
      questionsData = platformSnap.data();
    }
  }

  if (!questionsData || !Array.isArray(questionsData.questions)) {
    throw new HttpsError('not-found', 'Assessment questions not found for this course.');
  }

  const questions: Array<{ id: string; correctOption: number }> = questionsData.questions;
  const total = questions.length;

  // Grade
  const questionMap = new Map(questions.map((q) => [q.id, q.correctOption]));
  let correct = 0;
  for (const answer of answers) {
    const correctOption = questionMap.get(answer.questionId);
    if (correctOption !== undefined && answer.selectedOption === correctOption) {
      correct++;
    }
  }

  const score = total > 0 ? Math.round((correct / total) * 100) : 0;
  const passed = score >= 60;

  // Store attempt
  const courseRef = db.collection('users').doc(uid).collection('courses').doc(courseId);
  const attemptRef = courseRef.collection('assessmentAttempts').doc();
  const batch = db.batch();
  batch.set(attemptRef, {
    score,
    answers,
    gradedAt: FieldValue.serverTimestamp(),
    passed,
    correctCount: correct,
    totalQuestions: total,
  });

  // Update course doc if passed
  if (passed) {
    batch.update(courseRef, {
      finalAssessmentPassed: true,
      finalAssessmentScore: score,
      updatedAt: FieldValue.serverTimestamp(),
    });
  }

  await batch.commit();

  return { score, passed, correctCount: correct, totalQuestions: total };
});

// ── Phase 1C: Job Readiness Score Calculation ─────────────────────────────────

/**
 * Calculates a 0-100 job readiness score from multiple signals in the user's
 * Firestore sub-collections and stores the result back on careerProfiles/primary.
 */
export const calculateJobReadiness = onCall(async (request) => {
  requireAuth(request.auth?.uid);
  const uid = request.auth!.uid;

  const userRef = db.collection('users').doc(uid);

  // Fetch all required data in parallel
  const [
    certsSnap,
    careerProfileSnap,
    resumesSnap,
    coursesSnap,
  ] = await Promise.all([
    userRef.collection('certificates').get(),
    userRef.collection('careerProfiles').doc('primary').get(),
    userRef.collection('resumes').get(),
    userRef.collection('courses').get(),
  ]);

  const careerData = careerProfileSnap.data() ?? {};

  // Count metrics
  const certCount = certsSnap.size;
  const skillsList: unknown[] = Array.isArray(careerData.skills) ? careerData.skills : [];
  const skillsCount = skillsList.length;
  const hasGoal = typeof careerData.careerGoal === 'string' && careerData.careerGoal.trim().length > 0;
  const hasConsent = careerData.applicationConsent === true;

  const completedCourses = coursesSnap.docs.filter((d) => d.data().progress === 1).length;

  const hasCompletedResume = resumesSnap.docs.some(
    (d) => d.data().status !== 'Draft' && d.data().status !== undefined,
  );

  // Score calculation (max 100)
  const certPoints = Math.min(certCount * 10, 30);        // up to 30
  const skillPoints = Math.min(skillsCount * 2, 20);       // up to 20
  const coursePoints = Math.min(completedCourses * 5, 20); // up to 20
  const resumePoints = hasCompletedResume ? 15 : 0;        // 15
  const goalPoints = hasGoal ? 10 : 0;                     // 10
  const consentPoints = hasConsent ? 5 : 0;                // 5

  const score = certPoints + skillPoints + coursePoints + resumePoints + goalPoints + consentPoints;

  const breakdown = {
    certificates: { count: certCount, points: certPoints, maxPoints: 30 },
    skills: { count: skillsCount, points: skillPoints, maxPoints: 20 },
    completedCourses: { count: completedCourses, points: coursePoints, maxPoints: 20 },
    resumeCompleted: { achieved: hasCompletedResume, points: resumePoints, maxPoints: 15 },
    careerGoalSet: { achieved: hasGoal, points: goalPoints, maxPoints: 10 },
    applicationConsent: { achieved: hasConsent, points: consentPoints, maxPoints: 5 },
  };

  // Persist readiness score
  await userRef.collection('careerProfiles').doc('primary').set(
    {
      readinessScore: score,
      readinessCalculatedAt: FieldValue.serverTimestamp(),
    },
    { merge: true },
  );

  return { score, breakdown };
});

// ── AI Notes Generation (called by flutter-learning agent's AiNotesScreen) ───

/**
 * Generates structured study notes using OpenAI based on a topic + note type.
 * Accepts { topic, noteType, sourceContent? }
 */
export const generateAiNotes = onCall(async (request) => {
  requireAuth(request.auth?.uid);

  const topic = typeof request.data?.topic === 'string' ? request.data.topic.trim() : '';
  const noteType = typeof request.data?.noteType === 'string' ? request.data.noteType.trim() : 'Detailed Notes';
  const sourceContent = typeof request.data?.sourceContent === 'string'
    ? request.data.sourceContent.trim() : '';

  if (topic.length === 0) {
    throw new HttpsError('invalid-argument', 'A topic is required.');
  }

  const apiKey = process.env.OPENAI_API_KEY;
  if (!apiKey) {
    throw new HttpsError('internal', 'OpenAI API key is not configured.');
  }

  const noteTypePrompts: Record<string, string> = {
    'Detailed Notes': 'Create comprehensive, well-structured detailed notes with headings, subheadings, explanations, and examples.',
    'Revision Notes': 'Create concise revision notes with key points, bullet lists, and important formulas or definitions.',
    'Exam Notes': 'Create exam-focused notes highlighting the most important concepts, common question patterns, and tips.',
    'Interview Notes': 'Create interview preparation notes with common questions, expected answers, and key talking points.',
    'Flashcard Set': 'Create a set of flashcards in the format "Q: [question] A: [answer]", one per line, covering key concepts.',
    'Summary': 'Create a brief, clear summary covering the most essential points.',
  };

  const instruction = noteTypePrompts[noteType] ?? noteTypePrompts['Detailed Notes'];
  const userContent = sourceContent
    ? `Topic: ${topic}\n\nSource material to base notes on:\n${sourceContent.slice(0, 3000)}`
    : `Topic: ${topic}`;

  const openaiResponse = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${apiKey}`,
    },
    body: JSON.stringify({
      model: 'gpt-4o',
      messages: [
        {
          role: 'system',
          content: `You are DOEET AI, an expert educational content creator. ${instruction} Format your response in clean Markdown.`,
        },
        { role: 'user', content: userContent },
      ],
      max_tokens: 2000,
      temperature: 0.6,
    }),
  });

  if (!openaiResponse.ok) {
    const errText = await openaiResponse.text();
    console.error('OpenAI error:', errText);
    throw new HttpsError('internal', 'Failed to generate notes.');
  }

  const openaiData = await openaiResponse.json() as {
    choices: Array<{ message: { content: string } }>;
  };
  const generatedNotes = openaiData.choices?.[0]?.message?.content?.trim() ?? '';

  return { notes: generatedNotes, topic, noteType };
});

// ── Interview Scheduling ────────────────────────────────────────────────────

/**
 * Schedules an interview for a job application.
 * Input: { companyId, applicationId, scheduledAt (ISO string), mode, notes? }
 * - Creates interview record under companies/{id}/applications/{id}/interviews
 * - Creates a copy under users/{candidateUid}/interviews/{interviewId}
 * - Updates application status to 'interview'
 */
export const scheduleInterview = onCall(async (request) => {
  requireAuth(request.auth?.uid);
  const uid = request.auth!.uid;

  const { companyId, applicationId, scheduledAt, mode, notes } = request.data ?? {};
  if (!companyId || !applicationId || !scheduledAt || !mode) {
    throw new HttpsError('invalid-argument', 'companyId, applicationId, scheduledAt and mode are required.');
  }

  await requireCompanyManager(uid, companyId);

  const appRef = db.collection('companies').doc(companyId)
    .collection('applications').doc(applicationId);
  const appDoc = await appRef.get();
  if (!appDoc.exists) {
    throw new HttpsError('not-found', 'Application not found.');
  }
  const candidateUid: string = appDoc.data()?.candidateUid;
  if (!candidateUid) {
    throw new HttpsError('internal', 'Application has no candidate UID.');
  }

  const interviewData = {
    companyId,
    applicationId,
    candidateUid,
    scheduledBy: uid,
    scheduledAt: Timestamp.fromDate(new Date(scheduledAt as string)),
    mode,
    notes: notes ?? '',
    status: 'scheduled',
    createdAt: FieldValue.serverTimestamp(),
  };

  // Write to company side
  const interviewRef = appRef.collection('interviews').doc();
  await interviewRef.set(interviewData);

  // Write to candidate side
  await db.collection('users').doc(candidateUid)
    .collection('interviews').doc(interviewRef.id)
    .set(interviewData);

  // Update application stage
  await appRef.update({ status: 'interview', updatedAt: FieldValue.serverTimestamp() });

  return { interviewId: interviewRef.id };
});

// ── Create Offer ─────────────────────────────────────────────────────────────

/**
 * Creates a job offer for a shortlisted candidate.
 * Input: { companyId, applicationId, ctc, joiningDate (ISO), role, message? }
 */
export const createOffer = onCall(async (request) => {
  requireAuth(request.auth?.uid);
  const uid = request.auth!.uid;

  const { companyId, applicationId, ctc, joiningDate, role, message } = request.data ?? {};
  if (!companyId || !applicationId || !ctc || !joiningDate || !role) {
    throw new HttpsError('invalid-argument', 'companyId, applicationId, ctc, joiningDate, and role are required.');
  }

  await requireCompanyManager(uid, companyId);

  const appRef = db.collection('companies').doc(companyId)
    .collection('applications').doc(applicationId);
  const appDoc = await appRef.get();
  if (!appDoc.exists) throw new HttpsError('not-found', 'Application not found.');
  const candidateUid: string = appDoc.data()?.candidateUid;

  const offerData = {
    companyId,
    applicationId,
    candidateUid,
    createdBy: uid,
    ctc,
    role,
    joiningDate: Timestamp.fromDate(new Date(joiningDate as string)),
    message: message ?? '',
    status: 'pending',
    createdAt: FieldValue.serverTimestamp(),
  };

  const offerRef = appRef.collection('offers').doc();
  await offerRef.set(offerData);

  // Mirror to candidate
  await db.collection('users').doc(candidateUid)
    .collection('offers').doc(offerRef.id)
    .set(offerData);

  // Update application status
  await appRef.update({ status: 'offer', offerId: offerRef.id, updatedAt: FieldValue.serverTimestamp() });

  return { offerId: offerRef.id };
});

// ── Accept Offer ─────────────────────────────────────────────────────────────

/**
 * Candidate accepts a job offer.
 * Input: { companyId, applicationId, offerId }
 * - Updates offer status to 'accepted'
 * - Updates application status to 'hired'
 * - Creates employee workspace record
 */
export const acceptOffer = onCall(async (request) => {
  requireAuth(request.auth?.uid);
  const candidateUid = request.auth!.uid;

  const { companyId, applicationId, offerId } = request.data ?? {};
  if (!companyId || !applicationId || !offerId) {
    throw new HttpsError('invalid-argument', 'companyId, applicationId, and offerId are required.');
  }

  const offerRef = db.collection('companies').doc(companyId)
    .collection('applications').doc(applicationId)
    .collection('offers').doc(offerId);
  const offerDoc = await offerRef.get();
  if (!offerDoc.exists) throw new HttpsError('not-found', 'Offer not found.');
  if (offerDoc.data()?.candidateUid !== candidateUid) {
    throw new HttpsError('permission-denied', 'This offer does not belong to you.');
  }

  const batch = db.batch();

  // Update company-side offer
  batch.update(offerRef, { status: 'accepted', respondedAt: FieldValue.serverTimestamp() });

  // Update candidate-side offer
  const candidateOfferRef = db.collection('users').doc(candidateUid)
    .collection('offers').doc(offerId);
  batch.update(candidateOfferRef, { status: 'accepted', respondedAt: FieldValue.serverTimestamp() });

  // Update application status
  const appRef = db.collection('companies').doc(companyId)
    .collection('applications').doc(applicationId);
  batch.update(appRef, { status: 'hired', updatedAt: FieldValue.serverTimestamp() });

  // Create employee record
  const employeeRef = db.collection('companies').doc(companyId)
    .collection('employees').doc(candidateUid);
  const offerData = offerDoc.data()!;
  batch.set(employeeRef, {
    uid: candidateUid,
    role: offerData.role,
    ctc: offerData.ctc,
    joiningDate: offerData.joiningDate,
    status: 'active',
    hiredAt: FieldValue.serverTimestamp(),
  });

  // Update user role to 'employee' using custom claim
  await db.collection('users').doc(candidateUid).set(
    { roles: FieldValue.arrayUnion('employee') },
    { merge: true }
  );

  await batch.commit();

  return { success: true };
});

// ── Decline Offer ─────────────────────────────────────────────────────────────

/**
 * Candidate declines a job offer.
 * Input: { companyId, applicationId, offerId, reason? }
 */
export const declineOffer = onCall(async (request) => {
  requireAuth(request.auth?.uid);
  const candidateUid = request.auth!.uid;

  const { companyId, applicationId, offerId, reason } = request.data ?? {};
  if (!companyId || !applicationId || !offerId) {
    throw new HttpsError('invalid-argument', 'companyId, applicationId, and offerId are required.');
  }

  const offerRef = db.collection('companies').doc(companyId)
    .collection('applications').doc(applicationId)
    .collection('offers').doc(offerId);
  const offerDoc = await offerRef.get();
  if (!offerDoc.exists) throw new HttpsError('not-found', 'Offer not found.');
  if (offerDoc.data()?.candidateUid !== candidateUid) {
    throw new HttpsError('permission-denied', 'This offer does not belong to you.');
  }

  const declineData = {
    status: 'declined',
    declineReason: reason ?? '',
    respondedAt: FieldValue.serverTimestamp(),
  };

  await Promise.all([
    offerRef.update(declineData),
    db.collection('users').doc(candidateUid)
      .collection('offers').doc(offerId)
      .update(declineData),
    db.collection('companies').doc(companyId)
      .collection('applications').doc(applicationId)
      .update({ status: 'rejected', updatedAt: FieldValue.serverTimestamp() }),
  ]);

  return { success: true };
});

// ── Talent Search (company-side) ─────────────────────────────────────────────

/**
 * Returns candidates who have opted in to job discovery.
 * Input: { skills?: string[], limit?: number }
 * Only accessible by users with a company role.
 */
export const searchTalent = onCall(async (request) => {
  requireAuth(request.auth?.uid);
  requireCompanyRole(request.auth?.token.roles);

  const skills: string[] = Array.isArray(request.data?.skills) ? request.data.skills : [];
  const limitCount = typeof request.data?.limit === 'number' ? Math.min(request.data.limit, 50) : 20;

  // Query users who have set applicationConsent = true in their careerProfiles/primary
  // We store a denormalized copy in a public 'talentPool' collection for scalable search
  let query: FirebaseFirestore.Query = db.collection('talentPool')
    .where('applicationConsent', '==', true)
    .limit(limitCount);

  if (skills.length > 0) {
    // Filter by any matching skill (Firestore array-contains-any supports up to 10)
    query = query.where('skills', 'array-contains-any', skills.slice(0, 10));
  }

  const snap = await query.get();
  const results = snap.docs.map((doc) => {
    const d = doc.data();
    return {
      uid: doc.id,
      displayName: d.displayName ?? 'Anonymous',
      skills: d.skills ?? [],
      certCount: d.certCount ?? 0,
      completedCourses: d.completedCourses ?? 0,
      careerGoal: d.careerGoal ?? '',
      readinessScore: d.readinessScore ?? 0,
      xp: d.xp ?? 0,
      level: d.level ?? 1,
    };
  });

  return { candidates: results };
});
