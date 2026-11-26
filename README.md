# dooet

> Finish what you started. Import a YouTube playlist and follow it in a calm, distraction-free course workspace.

## Two separate paths

- **Learning** is for playlist-based courses, notes, progress, global course discovery, and webinars.
- **Employment** is a separate profile and job-search workspace for resumes, certificates, job applications, and interview progress.

Learning data stays in the existing learner profile and course collections.
Employment data stays in `careerProfiles`, `resumes`, `applications`, and related career collections. Company hiring is isolated in the separate Company workspace and protected by Firebase role and membership rules.

## Features

| Module | Description |
|---|---|
| 🔐 Auth | Email/password, Google Sign-In, Guest mode |
| ✅ Today | Add and complete personal tasks; see an honest count of today’s work |
| 📺 Course Import | Paste YouTube playlist URL → auto-fetch all videos |
| ▶️ Player | YouTube player with playback speed, focus mode, auto-progress |
| 📝 Notes | Rich note editor with auto-save, per-video timestamps |
| 🤖 Gemini Tutor | Gemini-powered doubt chat, notes, quizzes, and flashcards |
| 🃏 Flashcards | AI-generated 3D flip flashcards |
| 🧠 Quiz | AI-generated MCQ quiz with explanations |
| 📊 Progress | Task completions by day and this week’s completion count |
| 🏆 Gamification | Leaderboard with podium, 12 achievement badges |
| ⚙️ Settings | Account and app settings |

## Tech Stack

- **Flutter** (Dart) — mobile-first, Android + iOS
- **Riverpod** — state management
- **GoRouter** — navigation with shell routes
- **Firebase** — Auth, Firestore, Storage
- **Google Gemini Flash** — AI tutor and learning features, securely proxied through Firebase Functions
- **YouTube Data API v3** — playlist import

---

## Setup Instructions

### 1. Install dependencies

```bash
cd C:\Users\Kartik VP\Downloads\doeet
flutter pub get
```

### 2. Set up Firebase

```bash
# Install FlutterFire CLI (if not already installed)
dart pub global activate flutterfire_cli

# Configure Firebase for your project
flutterfire configure
```

Firebase is already initialized in this project through `lib/firebase_options.dart`. Avoid adding a second initialization call.

For Android and iOS, generate the platform-specific Firebase options after
installing and signing in to the FlutterFire CLI:

```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=doeetapp-c1e87 --platforms=android,ios,web
```

The generated `google-services.json`, `GoogleService-Info.plist`, and updated
`lib/firebase_options.dart` must match the Firebase project used for login and
Firestore. Enable Google as a sign-in provider in Firebase Authentication and
add the Android SHA-1/SHA-256 fingerprints before testing Google login.

### 3. Configure external services

#### YouTube Data API v3
1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Enable **YouTube Data API v3**
3. Create an API key
4. Keep the API key on a server, or restrict a development key by application and API in Google Cloud Console. Do not commit a production key or embed an unrestricted key in the Flutter app.

#### Gemini API key
1. Create a Gemini API key in [Google AI Studio](https://aistudio.google.com/app/apikey).
2. Store it as a Firebase Functions secret — never add it to a Flutter `--dart-define` or commit it to the repository:

```bash
firebase functions:secrets:set GEMINI_API_KEY
firebase deploy --only functions
```

The `geminiTutor` callable function keeps the secret on the server and provides chat, notes, quizzes, and flashcards to authenticated learners. For local development only, pass restricted development keys at launch without committing them:

```bash
flutter run --dart-define=YOUTUBE_API_KEY=your_key
```

The app intentionally fails with a clear configuration message when these values are absent. Never embed production secrets in a Flutter web or mobile build.

> **Security note**: `--dart-define` is suitable for local development only. Use a backend proxy for production secrets.

### 4. Firestore Setup

1. In Firebase Console → Firestore Database → Create database
2. Deploy the checked-in security rules before using task sync or the leaderboard:
```bash
firebase deploy --only firestore:rules
firebase deploy --only firestore:indexes
```

Deploy these rules after every rules change; local builds cannot deploy or
verify a Firebase project without your Firebase CLI credentials.

### 5. Enable Google Sign-In

In Firebase Console → Authentication → Sign-in method → Enable Google.
Add your SHA-1 fingerprint for Android:
```bash
cd android
./gradlew signingReport
```

### 6. Run the app

```bash
flutter run
```

---

## Project Structure

```
lib/
├── app/
│   ├── app.dart              # Root widget (Riverpod + GoRouter + Theme)
│   ├── main_scaffold.dart    # Bottom nav shell
│   └── router.dart           # GoRouter config
├── core/
│   ├── constants/            # AppColors, AppSizes, AppStrings
│   ├── theme/                # AppTheme (dark mode)
│   └── widgets/              # GlassCard, GradientButton, ShimmerLoader, XPBadge
└── features/
    ├── auth/                 # Login, Register, Onboarding, Splash
    ├── home/                 # Dashboard, stats widgets
    ├── courses/              # Import, Detail, Course cards
    ├── player/               # YouTube player screen
    ├── notes/                # Notes list + editor
    ├── ai/                   # Doubt chat, Flashcards, Quiz
    ├── analytics/            # Progress charts
    ├── gamification/         # Leaderboard + Badges
    └── settings/             # Settings + profile
```

---

## Firestore Schema

```
users/{uid}
  ├── displayName, email, xp, level, streak, longestStreak
  ├── dailyGoalMinutes, totalMinutesWatched, isPremium
  ├── courses/{courseId}
  │   ├── title, thumbnailUrl, progress, completedCount ...
  │   └── videos/{videoId}  ← per-video progress
  ├── notes/{noteId}
  │   ├── courseId, videoId, title, content, timestamp
  ├── tasks/{taskId}
  │   ├── title, dueAt, isCompleted, completedAt, createdAt, updatedAt
  └── dailyStats/{YYYY-MM-DD}
      ├── minutesWatched, videosCompleted

leaderboard/{uid}
  └── Public projection only: uid, displayName, photoURL, xp, level, streak
```

User profile documents and task data are private to their owner. The leaderboard uses a separate limited projection so profile email and other private fields are never queried for public rankings.

---

## XP & Gamification System

| Action | XP Earned |
|---|---|
| Watch a video to completion | +10 XP |
| Complete a course | +50 XP |
| Maintain a daily streak | +5 XP/day |
| Create a note | +2 XP |
| Score 100% on a quiz | +20 XP |

Level formula: `Level N requires N × 500 XP`
