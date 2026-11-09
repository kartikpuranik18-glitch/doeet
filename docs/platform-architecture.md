# DOEET platform architecture

DOEET remains a Flutter client deployed as a static web build on GitHub Pages.
Firebase is the service layer; GitHub Pages must never host service credentials,
payment keys, an OpenAI key, or any privileged business logic.

## Workspace boundaries

| Workspace | Who can enter | Data boundary |
| --- | --- | --- |
| Learner | learner, job seeker, employee, mentor, instructor | private user document and user subcollections |
| Company | employer, recruiter, agency, institution, company admin | company membership and company subcollections |
| Administration | platform admin | `/platform/**` only |

The client uses `UserModel.roles` only for navigation. Firebase custom claims
and Firestore rules remain the enforcement mechanism. Roles must be assigned by
a trusted Admin SDK service, never by a browser or Flutter client.

## Firestore collections

```text
users/{uid}
  tasks, goals, habits, notes, courses, dailyStats             existing
  careerProfiles, resumes, portfolios, projects, applications  new private data
  savedJobs, certificates, skillEvidence, careerRoadmaps

companies/{companyId}
  members/{uid}          server-created verified membership
  jobs/{jobId}
  applications/{id}      server-validated submissions
  candidates/{id}        consented candidate projections only

certificateVerifications/{certificateId}  public minimal verification record
platform/**                              platform-admin configuration/auditing
```

## Required server functions

Implement these as Firebase Cloud Functions (or a separately authenticated API)
before enabling the matching UI in production:

1. `assignRole` — verifies an operator, writes Firebase custom claims and an
   audited role change.
2. `issueCertificate` — validates lessons, assessment, project, score and
   course requirements, then creates the private certificate and public
   verification record atomically.
3. `submitApplication` — validates applicant consent, writes the learner's
   application and the employer's hiring-pipeline copy atomically.
4. `publishCandidateProfile` — creates/removes minimal, consented talent-search
   projections; never exposes private notes or unrelated profile information.
5. `createCompany` / `verifyCompany` — creates company membership only after
   verification and records an audit event.
6. `aiAction` — securely proxies model requests, performs action validation,
   rate limiting and audit logging. Browser clients must not contain AI secrets.

## GitHub Pages deployment

Build with `flutter build web --base-href /doeet/` and publish `build/web` to
the existing repository's Pages branch/workflow. Add
`kartikpuranik18-glitch.github.io` to Firebase Authentication's authorized
domains. Configure Firebase Hosting or Cloud Functions separately for HTTPS
callables/API endpoints; GitHub Pages only serves the Flutter frontend.

Before deploying the updated rules, use the Firebase Emulator Suite to exercise
learner, recruiter and admin authorization scenarios, then deploy with:

```bash
firebase deploy --only firestore:rules,firestore:indexes
```
