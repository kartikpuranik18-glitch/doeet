// lib/core/constants/app_strings.dart
/// Doeet — App String Constants
class AppStrings {
  AppStrings._();

  static const String appName = 'Doeet';
  static const String tagline = 'Learn Smarter. Go Further.';

  // Onboarding
  static const List<Map<String, String>> onboardingSlides = [
    {
      'title': 'Learn Without Limits',
      'subtitle': 'Import any YouTube playlist and turn it into a structured course — with progress tracking, notes, and AI assistance.',
      'animation': 'assets/animations/onboard_1.json',
    },
    {
      'title': 'AI-Powered Insights',
      'subtitle': 'Get instant summaries, flashcards, quizzes, and a personal AI tutor for every video you watch.',
      'animation': 'assets/animations/onboard_2.json',
    },
    {
      'title': 'Stay Consistent',
      'subtitle': 'Build daily streaks, earn XP, unlock badges, and climb the leaderboard as you grow smarter.',
      'animation': 'assets/animations/onboard_3.json',
    },
  ];

  // Auth
  static const String welcomeBack = 'Welcome back 👋';
  static const String createAccount = 'Create Account';
  static const String signIn = 'Sign In';
  static const String signInGoogle = 'Continue with Google';
  static const String continueGuest = 'Continue as Guest';
  static const String emailHint = 'Email address';
  static const String passwordHint = 'Password';
  static const String nameHint = 'Full name';
  static const String forgotPassword = 'Forgot password?';
  static const String dontHaveAccount = "Don't have an account? ";
  static const String alreadyHaveAccount = 'Already have an account? ';
  static const String registerNow = 'Register';
  static const String loginNow = 'Login';

  // Home
  static const String goodMorning = 'Good morning';
  static const String goodAfternoon = 'Good afternoon';
  static const String goodEvening = 'Good evening';
  static const String continueLearning = 'Continue Learning';
  static const String yourCourses = 'Your Courses';
  static const String dailyGoal = 'Daily Goal';
  static const String weeklyProgress = 'Weekly Progress';
  static const String totalHours = 'Total Hours';
  static const String streak = 'Streak';
  static const String xpPoints = 'XP Points';

  // Errors
  static const String genericError = 'Something went wrong. Please try again.';
  static const String networkError = 'No internet connection.';
  static const String authError = 'Authentication failed. Check your credentials.';
}
