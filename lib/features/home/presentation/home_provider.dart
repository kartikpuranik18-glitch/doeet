// lib/features/home/presentation/home_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../courses/presentation/courses_provider.dart';

// ── Daily stats model ─────────────────────────────────────────────────────────
class DailyStats {
  final int minutesWatched;
  final int videosCompleted;
  final DateTime date;

  const DailyStats({
    required this.minutesWatched,
    required this.videosCompleted,
    required this.date,
  });

  factory DailyStats.fromJson(Map<String, dynamic> json, DateTime date) => DailyStats(
        minutesWatched: (json['minutesWatched'] as num?)?.toInt() ?? 0,
        videosCompleted: (json['videosCompleted'] as num?)?.toInt() ?? 0,
        date: date,
      );
}

// ── Weekly stats provider ─────────────────────────────────────────────────────
final weeklyStatsProvider = FutureProvider<List<DailyStats>>((ref) async {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return List.generate(7, (i) => DailyStats(minutesWatched: 0, videosCompleted: 0, date: DateTime.now().subtract(Duration(days: 6 - i))));

  final db = FirebaseFirestore.instance;
  final now = DateTime.now();
  final stats = <DailyStats>[];

  for (int i = 6; i >= 0; i--) {
    final date = now.subtract(Duration(days: i));
    final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final doc = await db.collection('users').doc(user.uid).collection('dailyStats').doc(dateKey).get();
    if (doc.exists) {
      stats.add(DailyStats.fromJson(doc.data()!, date));
    } else {
      stats.add(DailyStats(minutesWatched: 0, videosCompleted: 0, date: date));
    }
  }
  return stats;
});

// ── Total study minutes today ────────────────────────────────────────────────
final todayMinutesProvider = Provider<int>((ref) {
  return ref.watch(weeklyStatsProvider).maybeWhen(
        data: (stats) => stats.isNotEmpty ? stats.last.minutesWatched : 0,
        orElse: () => 0,
      );
});

// ── Daily goal provider (minutes) ────────────────────────────────────────────
final dailyGoalProvider = Provider<int>((ref) {
  final user = ref.watch(currentUserProvider).value;
  return user?.dailyGoalMinutes ?? 30;
});

// ── Daily goal progress (0.0 to 1.0) ─────────────────────────────────────────
final dailyGoalProgressProvider = Provider<double>((ref) {
  final today = ref.watch(todayMinutesProvider);
  final goal = ref.watch(dailyGoalProvider);
  if (goal == 0) return 0.0;
  return (today / goal).clamp(0.0, 1.0);
});

// ── In-progress courses (courses with >0% <100% progress) ────────────────────
final inProgressCoursesProvider = Provider((ref) {
  return ref.watch(coursesStreamProvider).maybeWhen(
        data: (courses) => courses.where((c) => c.progressPercent > 0 && c.progressPercent < 100).toList(),
        orElse: () => [],
      );
});
