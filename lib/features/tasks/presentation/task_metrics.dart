import '../data/task_model.dart';

class TaskMetrics {
  const TaskMetrics({
    required this.days,
    required this.completedThisWeek,
    required this.completedLastWeekToDate,
  });

  final List<int> days;
  final int completedThisWeek;
  final int completedLastWeekToDate;

  static TaskMetrics fromTasks(List<TaskModel> tasks, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final start = today.subtract(Duration(days: today.weekday - 1));
    final days = List<int>.filled(7, 0);
    var completedLastWeekToDate = 0;

    for (final task in tasks) {
      final completedAt = task.completedAt;
      if (!task.isCompleted || completedAt == null) continue;
      final date =
          DateTime(completedAt.year, completedAt.month, completedAt.day);
      final offset = date.difference(start).inDays;
      if (offset >= 0 && offset < days.length) {
        days[offset]++;
      } else if (offset >= -7 && offset < 0 && offset + 7 < today.weekday) {
        completedLastWeekToDate++;
      }
    }

    return TaskMetrics(
      days: days,
      completedThisWeek: days.fold(0, (total, count) => total + count),
      completedLastWeekToDate: completedLastWeekToDate,
    );
  }
}
