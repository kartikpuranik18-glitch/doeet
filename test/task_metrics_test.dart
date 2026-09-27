import 'package:doeet/features/tasks/data/task_model.dart';
import 'package:doeet/features/tasks/presentation/task_metrics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TaskMetrics', () {
    final sunday = DateTime(2026, 9, 27, 14);

    test('counts only completed tasks from the current Monday-based week', () {
      final tasks = [
        _task('monday', DateTime(2026, 9, 21, 9)),
        _task('saturday', DateTime(2026, 9, 26, 11)),
        _task('previous week', DateTime(2026, 9, 20, 18)),
        _task('still open', null, completed: false),
      ];

      final metrics = TaskMetrics.fromTasks(tasks, sunday);

      expect(metrics.days, [1, 0, 0, 0, 0, 1, 0]);
      expect(metrics.completedThisWeek, 2);
      expect(metrics.completedLastWeekToDate, 1);
    });

    test('does not count dates in the future', () {
      final metrics = TaskMetrics.fromTasks(
        [_task('future', DateTime(2026, 9, 28))],
        sunday,
      );

      expect(metrics.completedThisWeek, 0);
    });
  });
}

TaskModel _task(String id, DateTime? completedAt, {bool completed = true}) {
  final created = DateTime(2026, 9, 1);
  return TaskModel(
    id: id,
    title: id,
    dueAt: created,
    createdAt: created,
    updatedAt: created,
    completedAt: completedAt,
    isCompleted: completed,
  );
}
