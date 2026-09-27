// lib/app/router.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_colors.dart';
import '../features/auth/presentation/auth_provider.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../features/auth/presentation/onboarding_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/courses/presentation/courses_screen.dart';
import '../features/courses/presentation/import_course_screen.dart';
import '../features/courses/presentation/course_detail_screen.dart';
import '../features/player/presentation/player_screen.dart';
import '../features/notes/presentation/notes_screen.dart';
import '../features/notes/presentation/note_editor_screen.dart';
import '../features/notes/data/note_model.dart';
import '../features/ai/presentation/ai_assistant_screen.dart';
import '../features/ai/presentation/flashcards_screen.dart';
import '../features/ai/presentation/quiz_screen.dart';
import '../features/gamification/presentation/leaderboard_screen.dart';
import '../features/gamification/presentation/badges_screen.dart';
import '../features/analytics/presentation/analytics_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/workspace/presentation/workspace_screens.dart';
import 'main_scaffold.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(firebaseAuthStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isLoading = authState.isLoading;
      if (isLoading) return '/splash';

      final isLoggedIn = authState.value != null;
      final isOnAuth = state.matchedLocation.startsWith('/login') ||
          state.matchedLocation.startsWith('/register') ||
          state.matchedLocation.startsWith('/onboarding');
      final isOnSplash = state.matchedLocation == '/splash';

      if (isOnSplash) return null;
      if (!isLoggedIn && !isOnAuth) return '/onboarding';
      if (isLoggedIn && isOnAuth) return '/home';
      return null;
    },
    routes: [
      // ── Auth ──────────────────────────────────────────────────────────────
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(
          path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),

      // ── Main App (shell with bottom nav) ──────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/courses', builder: (_, __) => const CoursesScreen()),
          GoRoute(
              path: '/analytics', builder: (_, __) => const AnalyticsScreen()),
          GoRoute(
            path: '/goals',
            builder: (_, __) => const GoalsScreen(),
          ),
          GoRoute(
            path: '/calendar',
            builder: (_, __) => const CalendarScreen(),
          ),
          GoRoute(
            path: '/tasks',
            builder: (_, __) => const DailyTasksScreen(),
          ),
          GoRoute(path: '/habits', builder: (_, __) => const HabitsScreen()),
          GoRoute(path: '/notes', builder: (_, __) => const NotesScreen()),
          GoRoute(
            path: '/ai-assistant',
            builder: (_, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return AiAssistantScreen(
                courseContext: extra?['courseContext'] ?? 'General learning',
                courseTitle: extra?['courseTitle'] ?? 'Your Course',
              );
            },
          ),
          GoRoute(
              path: '/settings', builder: (_, __) => const SettingsScreen()),
          GoRoute(
              path: '/leaderboard',
              builder: (_, __) => const LeaderboardScreen()),
          GoRoute(path: '/badges', builder: (_, __) => const BadgesScreen()),
        ],
      ),

      // ── Course flows ───────────────────────────────────────────────────────
      GoRoute(
          path: '/import-course',
          builder: (_, __) => const ImportCourseScreen()),
      GoRoute(
        path: '/course/:courseId',
        builder: (_, state) =>
            CourseDetailScreen(courseId: state.pathParameters['courseId']!),
      ),

      // ── Player ────────────────────────────────────────────────────────────
      GoRoute(
        path: '/player/:courseId/:videoId',
        builder: (_, state) => PlayerScreen(
          courseId: state.pathParameters['courseId']!,
          videoId: state.pathParameters['videoId']!,
        ),
      ),

      // ── Note Editor (push on top of any screen) ───────────────────────────
      GoRoute(
        path: '/notes/editor',
        builder: (_, state) {
          // extra can be a NoteModel (edit) or a Map (new note with context)
          final extra = state.extra;
          if (extra is NoteModel) {
            return NoteEditorScreen(existingNote: extra);
          }
          if (extra is Map<String, dynamic>) {
            return NoteEditorScreen(
              courseId: extra['courseId'] as String?,
              videoId: extra['videoId'] as String?,
              videoTimestamp: extra['timestamp'] as int?,
            );
          }
          return const NoteEditorScreen();
        },
      ),

      // ── AI tools ──────────────────────────────────────────────────────────
      GoRoute(
        path: '/flashcards',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return FlashcardsScreen(
            topic: extra['topic'] as String? ?? 'General',
            content: extra['content'] as String? ?? '',
          );
        },
      ),
      GoRoute(
        path: '/quiz',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return QuizScreen(
            topic: extra['topic'] as String? ?? 'General',
            content: extra['content'] as String? ?? '',
          );
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('404',
                style: TextStyle(fontSize: 48, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Text('Page not found: ${state.uri}',
                style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
});
