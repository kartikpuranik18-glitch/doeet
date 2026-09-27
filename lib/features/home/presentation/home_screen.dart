import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../auth/presentation/auth_provider.dart';
import '../../tasks/data/task_model.dart';
import '../../tasks/presentation/tasks_provider.dart';
import '../../../core/constants/app_colors.dart';
import 'widgets/weekly_chart.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key, this.initialSection});

  final String? initialSection;

  static final _tasksKey = GlobalKey();
  static String? _lastAutoScrollSection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    final tasksAsync = ref.watch(tasksProvider);
    final firstName = user?.firstName.trim().split(' ').first;
    final greetingName = firstName?.isNotEmpty == true ? firstName! : 'there';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final section = initialSection ??
      GoRouterState.of(context).uri.queryParameters['section'];
    if (section == null) _lastAutoScrollSection = null;
    if (section == 'tasks' && _lastAutoScrollSection != section) {
      _lastAutoScrollSection = section;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final target = _tasksKey.currentContext;
        if (target != null) {
          Scrollable.ensureVisible(target,
              duration: const Duration(milliseconds: 250), alignment: 0.05);
        }
      });
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1060),
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      Text(
                        DateFormat('EEEE, d MMMM').format(now),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Good ${_greeting()}, $greetingName.',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 29,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.8,
                        ),
                      ),
                      const SizedBox(height: 34),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Expanded(
                            child: Text(
                              'Today',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 21,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => _showAddTask(context, ref),
                            icon: const Icon(Icons.add_rounded, size: 19),
                            label: const Text('Add task'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primaryLight,
                              minimumSize: const Size(48, 44),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      KeyedSubtree(
                        key: _tasksKey,
                        child: tasksAsync.when(
                          loading: () => const _TaskLoading(),
                          error: (_, __) => _TaskError(
                            onRetry: () => ref.invalidate(tasksProvider),
                          ),
                          data: (tasks) {
                            final dueToday = tasks
                                .where((task) => _sameDay(task.dueAt, today))
                                .toList();
                            final completedToday = dueToday
                                .where((task) => task.isCompleted)
                                .length;
                            final remaining = tasks
                                .where((task) =>
                                    !task.isCompleted &&
                                    !task.dueAt.isAfter(today))
                                .toList();
                            final completed = dueToday
                                .where((task) => task.isCompleted)
                                .toList();
                            final visibleTasks = [...remaining, ...completed];
                            final progress = dueToday.isEmpty
                                ? 0.0
                                : completedToday / dueToday.length;
                            final openTasks =
                                tasks.where((task) => !task.isCompleted).length;
                            final weekStart = today.subtract(
                              Duration(days: today.weekday - 1),
                            );
                            final completedThisWeek = tasks.where((task) {
                              final completedAt = task.completedAt;
                              return task.isCompleted &&
                                  completedAt != null &&
                                  !completedAt.isBefore(weekStart);
                            }).length;
                            final activeDays = tasks
                                .where((task) =>
                                    task.isCompleted &&
                                    task.completedAt != null &&
                                    !task.completedAt!.isBefore(weekStart))
                                .map((task) => DateTime(
                                      task.completedAt!.year,
                                      task.completedAt!.month,
                                      task.completedAt!.day,
                                    ))
                                .toSet()
                                .length;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final columns = constraints.maxWidth >= 700
                                        ? 4
                                        : constraints.maxWidth >= 400
                                            ? 2
                                            : 1;
                                    final cardWidth = columns == 1
                                        ? constraints.maxWidth
                                        : (constraints.maxWidth -
                                                (columns - 1) * 12) /
                                            columns;
                                    return Wrap(
                                      spacing: 12,
                                      runSpacing: 12,
                                      children: [
                                        _OverviewMetric(
                                          width: cardWidth,
                                          label: 'TODAY',
                                          value:
                                              '$completedToday/${dueToday.length}',
                                          detail: 'tasks completed',
                                          icon: Icons
                                              .check_circle_outline_rounded,
                                          color: AppColors.primaryLight,
                                        ),
                                        _OverviewMetric(
                                          width: cardWidth,
                                          label: 'OPEN TASKS',
                                          value: '$openTasks',
                                          detail: 'across your list',
                                          icon: Icons.pending_actions_rounded,
                                          color: AppColors.secondary,
                                        ),
                                        _OverviewMetric(
                                          width: cardWidth,
                                          label: 'THIS WEEK',
                                          value: '$completedThisWeek',
                                          detail: 'tasks completed',
                                          icon: Icons.trending_up_rounded,
                                          color: AppColors.success,
                                        ),
                                        _OverviewMetric(
                                          width: cardWidth,
                                          label: 'ACTIVE DAYS',
                                          value: '$activeDays',
                                          detail: 'this week',
                                          icon: Icons.calendar_today_outlined,
                                          color: AppColors.warning,
                                        ),
                                      ],
                                    );
                                  },
                                ),
                                const SizedBox(height: 30),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        dueToday.isEmpty
                                            ? 'Nothing scheduled yet.'
                                            : '$completedToday of ${dueToday.length} completed',
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    if (dueToday.isNotEmpty)
                                      Text(
                                        '${(progress * 100).round()}%',
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 13,
                                          fontFeatures: [
                                            FontFeature.tabularFigures()
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                                if (dueToday.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: progress,
                                      minHeight: 4,
                                      backgroundColor: AppColors.bgElevated,
                                      valueColor: const AlwaysStoppedAnimation(
                                        AppColors.secondary,
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 18),
                                if (visibleTasks.isEmpty)
                                  const _EmptyTasks()
                                else
                                  ...visibleTasks.map((task) => _TaskRow(
                                        task: task,
                                        isFromEarlier:
                                            task.dueAt.isBefore(today),
                                        onChanged: (value) => _setCompleted(
                                            context, ref, task, value),
                                        onDelete: () =>
                                            _deleteTask(context, ref, task),
                                      )),
                                if (remaining.isEmpty &&
                                    dueToday.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  const Text(
                                    'You’re clear for today.',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 34),
                                const Divider(
                                    color: AppColors.border, height: 1),
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    const Expanded(
                                      child: Text(
                                        'Keep learning',
                                        style: TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () => context.go('/courses'),
                                      child: const Text('Your courses →'),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Study time',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const WeeklyChart(),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'evening';
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _setCompleted(
    BuildContext context,
    WidgetRef ref,
    TaskModel task,
    bool completed,
  ) async {
    await ref.read(taskActionsProvider.notifier).setCompleted(task, completed);
    final result = ref.read(taskActionsProvider);
    if (!context.mounted || !result.hasError) return;
    _showError(context,
        'Couldn’t update that task. Check your connection and try again.');
  }

  Future<void> _deleteTask(
    BuildContext context,
    WidgetRef ref,
    TaskModel task,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgSurface,
        title: const Text('Delete this task?'),
        content: Text('“${task.title}” will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep it'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await ref.read(taskActionsProvider.notifier).delete(task.id);
    if (ref.read(taskActionsProvider).hasError && context.mounted) {
      _showError(context, 'Couldn’t delete that task. Try again.');
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showAddTask(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) {
        var isSaving = false;
        String? error;

        Future<void> submit(StateSetter setSheetState) async {
          final title = controller.text.trim();
          if (title.isEmpty) {
            setSheetState(() => error = 'Add a short title first.');
            return;
          }
          setSheetState(() {
            isSaving = true;
            error = null;
          });
          await ref.read(taskActionsProvider.notifier).add(title);
          final result = ref.read(taskActionsProvider);
          if (!sheetContext.mounted) return;
          if (result.hasError) {
            setSheetState(() {
              isSaving = false;
              error =
                  'Couldn’t save this task. Check your connection and try again.';
            });
            return;
          }
          Navigator.pop(sheetContext);
        }

        return StatefulBuilder(
          builder: (sheetContext, setSheetState) => Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              24,
              20,
              MediaQuery.of(sheetContext).viewInsets.bottom + 20,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'What do you want to get done?',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    maxLength: 240,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => submit(setSheetState),
                    decoration: InputDecoration(
                      hintText: 'Add a task',
                      errorText: error,
                      counterText: '',
                      filled: true,
                      fillColor: AppColors.bg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: isSaving ? null : () => submit(setSheetState),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(48, 48),
                    ),
                    child: isSaving
                        ? const SizedBox.square(
                            dimension: 19,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Add to today'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ).whenComplete(controller.dispose);
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({
    required this.task,
    required this.isFromEarlier,
    required this.onChanged,
    required this.onDelete,
  });

  final TaskModel task;
  final bool isFromEarlier;
  final ValueChanged<bool> onChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final label = task.isCompleted
        ? 'Completed: ${task.title}'
        : 'Mark ${task.title} complete';
    return Semantics(
      label: label,
      child: Container(
        constraints: const BoxConstraints(minHeight: 58),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            Checkbox(
              value: task.isCompleted,
              onChanged: (value) => onChanged(value ?? false),
              activeColor: AppColors.secondary,
              side: const BorderSide(color: AppColors.textMuted),
              semanticLabel: label,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      color: task.isCompleted
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                      fontSize: 15,
                      decoration:
                          task.isCompleted ? TextDecoration.lineThrough : null,
                      decorationColor: AppColors.textMuted,
                    ),
                  ),
                  if (isFromEarlier)
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Text(
                        'From earlier',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              onPressed: onDelete,
              tooltip: 'Delete ${task.title}',
              icon: const Icon(Icons.delete_outline_rounded, size: 20),
              color: AppColors.textMuted,
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyTasks extends StatelessWidget {
  const _EmptyTasks();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(0, 22, 0, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nothing scheduled yet.',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Add something you want to get done.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      );
}

class _TaskLoading extends StatelessWidget {
  const _TaskLoading();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 36),
        child: Center(
          child: SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primaryLight,
            ),
          ),
        ),
      );
}

class _TaskError extends StatelessWidget {
  const _TaskError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 22),
        child: Row(
          children: [
            const Expanded(
              child: Text(
                'Couldn’t load your tasks. Check your connection and try again.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      );
}

class _OverviewMetric extends StatelessWidget {
  const _OverviewMetric({
    required this.width,
    required this.label,
    required this.value,
    required this.detail,
    required this.icon,
    required this.color,
  });

  final double width;
  final String label;
  final String value;
  final String detail;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 15),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, color: color, size: 17),
              const SizedBox(width: 8),
              Text(label,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .8,
                  )),
            ]),
            const SizedBox(height: 14),
            Text(value,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 25,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -.6,
                )),
            const SizedBox(height: 2),
            Text(detail,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                )),
          ],
        ),
      );
}
