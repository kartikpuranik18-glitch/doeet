import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../tasks/data/task_model.dart';
import '../../tasks/presentation/task_metrics.dart';
import '../../tasks/presentation/tasks_provider.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../../core/constants/app_colors.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key, this.initialSection});

  final String? initialSection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksProvider);
    final section = initialSection ??
        GoRouterState.of(context).uri.queryParameters['section'];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: MediaQuery.sizeOf(context).width < 900
          ? AppBar(
              backgroundColor: AppColors.bg,
              title: const Text('Progress'),
            )
          : null,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1060),
          child: tasksAsync.when(
            loading: () => const Center(
              child: SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primaryLight,
                ),
              ),
            ),
            error: (_, __) => _ProgressError(
              onRetry: () => ref.invalidate(tasksProvider),
            ),
            data: (tasks) => _ProgressContent(
              tasks: tasks,
              today: today,
              uid: ref.watch(firebaseAuthStateProvider).value?.uid ?? '',
              initialSection: section,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressContent extends StatelessWidget {
  const _ProgressContent(
      {required this.tasks,
      required this.today,
      required this.uid,
      this.initialSection});

  static final goalsKey = GlobalKey();
  static final habitsKey = GlobalKey();
  static final calendarKey = GlobalKey();
  static final _scrollController = ScrollController();
  static String? _lastAutoScrollSection;

  final List<TaskModel> tasks;
  final DateTime today;
  final String uid;
  final String? initialSection;

  @override
  Widget build(BuildContext context) {
    final dueToday =
        tasks.where((task) => _sameDay(task.dueAt, today)).toList();
    final completedToday = dueToday.where((task) => task.isCompleted).length;
    final remainingToday = tasks
        .where((task) => !task.isCompleted && !task.dueAt.isAfter(today))
        .toList();
    final metrics = TaskMetrics.fromTasks(tasks, DateTime.now());
    final activeDays = metrics.days.where((count) => count > 0).length;
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final hasHistory = tasks.any((task) => task.createdAt.isBefore(weekStart));
    final progress = dueToday.isEmpty ? 0.0 : completedToday / dueToday.length;

    if (initialSection == null) _lastAutoScrollSection = null;
    if (initialSection != null && _lastAutoScrollSection != initialSection) {
      _lastAutoScrollSection = initialSection;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final key = switch (initialSection) {
          'goals' => goalsKey,
          'habits' => habitsKey,
          'calendar' => calendarKey,
          _ => null,
        };
        if (key != null) _revealProgressSection(key, _scrollController);
      });
    }
    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      children: [
        const Text(
          'A clear look at what you’ve done.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 30),
        const _SectionEyebrow('TODAY'),
        const SizedBox(height: 8),
        Text(
          dueToday.isEmpty
              ? 'No tasks today.'
              : '$completedToday of ${dueToday.length} completed',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 25,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
        if (dueToday.isNotEmpty) ...[
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: AppColors.bgElevated,
              valueColor: const AlwaysStoppedAnimation(AppColors.secondary),
            ),
          ),
        ],
        const SizedBox(height: 30),
        const Divider(color: AppColors.border, height: 1),
        const SizedBox(height: 22),
        const _SectionEyebrow('FOCUS'),
        const SizedBox(height: 10),
        if (remainingToday.isEmpty)
          Text(
            dueToday.isEmpty
                ? 'Add a task when something needs your attention.'
                : 'You’re clear for today.',
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          )
        else
          ...remainingToday.take(4).map(
                (task) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.circle_outlined,
                        color: AppColors.textMuted,
                        size: 17,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          task.title,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        if (remainingToday.length > 4)
          Text(
            '${remainingToday.length - 4} more to focus on today',
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        const SizedBox(height: 28),
        const Divider(color: AppColors.border, height: 1),
        const SizedBox(height: 22),
        const _SectionEyebrow('MOMENTUM'),
        const SizedBox(height: 7),
        Text(
          '${metrics.completedThisWeek} ${metrics.completedThisWeek == 1 ? 'task' : 'tasks'} completed this week',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          activeDays == 0
              ? 'Your week will take shape as you complete tasks.'
              : 'You showed up on $activeDays ${activeDays == 1 ? 'day' : 'days'} this week.',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        if (hasHistory) ...[
          const SizedBox(height: 5),
          Text(
            'At this point last week: ${metrics.completedLastWeekToDate} completed',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
        const SizedBox(height: 20),
        _WeekBars(days: metrics.days, today: today),
        if (tasks.isEmpty) ...[
          const SizedBox(height: 32),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () => context.go('/home'),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add your first task'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryLight,
                side: const BorderSide(color: AppColors.border),
                minimumSize: const Size(48, 44),
              ),
            ),
          ),
        ],
      ],
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _WeekBars extends StatelessWidget {
  const _WeekBars({required this.days, required this.today});

  final List<int> days;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final maxCount =
        days.fold<int>(0, (max, value) => value > max ? value : max);
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Semantics(
      label: 'Tasks completed each day this week: ${days.join(', ')}',
      child: SizedBox(
        height: 112,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: List.generate(days.length, (index) {
            final count = days[index];
            final isToday = today.weekday - 1 == index;
            final fraction = maxCount == 0 ? 0.0 : count / maxCount;
            return Expanded(
              child: Tooltip(
                message:
                    '${DateFormat('EEEE').format(today.subtract(Duration(days: today.weekday - 1 - index)))}: $count ${count == 1 ? 'task' : 'tasks'}',
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 7),
                  child: Column(
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: FractionallySizedBox(
                            heightFactor: fraction,
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: isToday
                                    ? AppColors.secondary
                                    : AppColors.primary.withOpacity(0.6),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(3),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 9),
                      Text(
                        labels[index],
                        style: TextStyle(
                          color: isToday
                              ? AppColors.textPrimary
                              : AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

Future<void> _revealProgressSection(
    GlobalKey key, ScrollController controller) async {
  for (var attempt = 0; attempt < 18; attempt++) {
    await Future<void>.delayed(const Duration(milliseconds: 35));
    final target = key.currentContext;
    if (target != null) {
      await Scrollable.ensureVisible(target,
          duration: const Duration(milliseconds: 250), alignment: 0.06);
      return;
    }
    if (controller.hasClients) {
      final position = controller.position;
      final next = attempt == 0
          ? position.maxScrollExtent
          : position.pixels - position.viewportDimension * 0.72;
      controller.jumpTo(next.clamp(0.0, position.maxScrollExtent).toDouble());
    }
  }
}

class _SectionEyebrow extends StatelessWidget {
  const _SectionEyebrow(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 11,
          letterSpacing: 1.1,
          fontWeight: FontWeight.w600,
        ),
      );
}

class _ProgressError extends StatelessWidget {
  const _ProgressError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Couldn’t load progress. Check your connection and try again.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              TextButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      );
}

final _goalsProvider = StreamProvider.family<
    List<QueryDocumentSnapshot<Map<String, dynamic>>>, String>((ref, uid) {
  if (uid.isEmpty) return Stream.value(const []);
  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('goals')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs);
});

final _habitsProvider = StreamProvider.family<
    List<QueryDocumentSnapshot<Map<String, dynamic>>>, String>((ref, uid) {
  if (uid.isEmpty) return Stream.value(const []);
  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('habits')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs);
});

class _GoalsSection extends ConsumerWidget {
  const _GoalsSection({super.key, required this.uid});
  final String uid;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_goalsProvider(uid));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Expanded(child: _SectionEyebrow('GOALS')),
        TextButton.icon(
            onPressed: () => _addGoal(context, uid),
            icon: const Icon(Icons.add_rounded, size: 17),
            label: const Text('Add goal')),
      ]),
      const SizedBox(height: 8),
      async.when(
        loading: () => const LinearProgressIndicator(minHeight: 2),
        error: (_, __) => const Text('Goals are unavailable right now.',
            style: TextStyle(color: AppColors.textSecondary)),
        data: (goals) => goals.isEmpty
            ? const Text('Set one outcome you want to move forward this month.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13))
            : Column(
                children: goals.map((doc) {
                final data = doc.data();
                final target = (data['target'] as num?)?.toInt() ?? 1;
                final progress = (data['progress'] as num?)?.toInt() ?? 0;
                final ratio = (progress / target).clamp(0.0, 1.0);
                return Container(
                  margin: const EdgeInsets.only(bottom: 9),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border)),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Expanded(
                              child: Text(data['title'] as String? ?? 'Goal',
                                  style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w600))),
                          Text('$progress / $target',
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12)),
                          IconButton(
                              tooltip: 'Log progress',
                              onPressed: progress >= target
                                  ? null
                                  : () => FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(uid)
                                          .collection('goals')
                                          .doc(doc.id)
                                          .update({
                                        'progress': FieldValue.increment(1)
                                      }),
                              icon: const Icon(Icons.add_circle_outline,
                                  size: 19, color: AppColors.primaryLight)),
                        ]),
                        const SizedBox(height: 7),
                        ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                                value: ratio,
                                minHeight: 4,
                                backgroundColor: AppColors.bgElevated,
                                color: AppColors.primary)),
                      ]),
                );
              }).toList()),
      ),
    ]);
  }

  Future<void> _addGoal(BuildContext context, String uid) async {
    final title = TextEditingController();
    final target = TextEditingController(text: '10');
    final result = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
              backgroundColor: AppColors.bgCard,
              title: const Text('Add a goal'),
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(
                    controller: title,
                    autofocus: true,
                    decoration: const InputDecoration(
                        labelText: 'What do you want to achieve?')),
                TextField(
                    controller: target,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: 'Target count')),
              ]),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel')),
                FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Add goal'))
              ],
            ));
    final name = title.text.trim();
    final count = int.tryParse(target.text) ?? 10;
    title.dispose();
    target.dispose();
    if (result == true && name.isNotEmpty && count > 0) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('goals')
          .add({
        'title': name,
        'target': count,
        'progress': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }
}

class _HabitsSection extends ConsumerWidget {
  const _HabitsSection({super.key, required this.uid});
  final String uid;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_habitsProvider(uid));
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Expanded(child: _SectionEyebrow('HABITS')),
        TextButton.icon(
            onPressed: () => _addHabit(context, uid),
            icon: const Icon(Icons.add_rounded, size: 17),
            label: const Text('Add habit'))
      ]),
      const SizedBox(height: 8),
      async.when(
        loading: () => const LinearProgressIndicator(minHeight: 2),
        error: (_, __) => const Text('Habits are unavailable right now.',
            style: TextStyle(color: AppColors.textSecondary)),
        data: (habits) => habits.isEmpty
            ? const Text('Small routines make progress easier to repeat.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13))
            : Wrap(
                spacing: 9,
                runSpacing: 9,
                children: habits.map((doc) {
                  final data = doc.data();
                  final done =
                      (data['completedDates'] as List<dynamic>? ?? const [])
                          .contains(today);
                  return InkWell(
                      borderRadius: BorderRadius.circular(11),
                      onTap: () => FirebaseFirestore.instance
                              .collection('users')
                              .doc(uid)
                              .collection('habits')
                              .doc(doc.id)
                              .update({
                            'completedDates': done
                                ? FieldValue.arrayRemove([today])
                                : FieldValue.arrayUnion([today])
                          }),
                      child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 11),
                          decoration: BoxDecoration(
                              color: done
                                  ? AppColors.success.withOpacity(.12)
                                  : AppColors.bgCard,
                              borderRadius: BorderRadius.circular(11),
                              border: Border.all(
                                  color: done
                                      ? AppColors.success.withOpacity(.35)
                                      : AppColors.border)),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(
                                done
                                    ? Icons.check_circle
                                    : Icons.circle_outlined,
                                size: 17,
                                color: done
                                    ? AppColors.success
                                    : AppColors.textMuted),
                            const SizedBox(width: 8),
                            Text(data['title'] as String? ?? 'Habit',
                                style: const TextStyle(
                                    color: AppColors.textPrimary, fontSize: 13))
                          ])));
                }).toList()),
      ),
    ]);
  }

  Future<void> _addHabit(BuildContext context, String uid) async {
    final title = TextEditingController();
    final result = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
              backgroundColor: AppColors.bgCard,
              title: const Text('Add a habit'),
              content: TextField(
                  controller: title,
                  autofocus: true,
                  decoration: const InputDecoration(
                      labelText: 'What do you want to repeat?')),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel')),
                FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Add habit'))
              ],
            ));
    final name = title.text.trim();
    title.dispose();
    if (result == true && name.isNotEmpty)
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('habits')
          .add({
        'title': name,
        'completedDates': <String>[],
        'createdAt': FieldValue.serverTimestamp()
      });
  }
}

class _CalendarSection extends ConsumerStatefulWidget {
  const _CalendarSection({super.key, required this.tasks, required this.uid});
  final List<TaskModel> tasks;
  final String uid;
  @override
  ConsumerState<_CalendarSection> createState() => _CalendarSectionState();
}

class _CalendarSectionState extends ConsumerState<_CalendarSection> {
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  late DateTime _selected =
      DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  bool _same(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final firstWeekday = DateTime(_month.year, _month.month, 1).weekday - 1;
    final days = DateTime(_month.year, _month.month + 1, 0).day;
    final selectedTasks =
        widget.tasks.where((t) => _same(t.dueAt, _selected)).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Expanded(child: _SectionEyebrow('CALENDAR')),
        IconButton(
            onPressed: () => setState(() {
                  _month = DateTime(_month.year, _month.month - 1);
                  _selected = DateTime(_month.year, _month.month, 1);
                }),
            icon: const Icon(Icons.chevron_left)),
        Text(DateFormat('MMMM yyyy').format(_month),
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
        IconButton(
            onPressed: () => setState(() {
                  _month = DateTime(_month.year, _month.month + 1);
                  _selected = DateTime(_month.year, _month.month, 1);
                }),
            icon: const Icon(Icons.chevron_right)),
      ]),
      const SizedBox(height: 8),
      Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: AppColors.border)),
          child: Column(children: [
            Row(
                children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                    .map((d) => Expanded(
                        child: Center(
                            child: Text(d,
                                style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 11)))))
                    .toList()),
            const SizedBox(height: 7),
            for (var row = 0; row < ((firstWeekday + days + 6) ~/ 7); row++)
              Row(children: [
                for (var col = 0; col < 7; col++)
                  _dayCell(row * 7 + col - firstWeekday + 1, days),
              ]),
          ])),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(
            child: Text(DateFormat('EEEE, d MMM').format(_selected),
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600))),
        TextButton.icon(
            onPressed: _addTask,
            icon: const Icon(Icons.add_rounded, size: 17),
            label: const Text('Add task'))
      ]),
      if (selectedTasks.isEmpty)
        const Text('No tasks scheduled for this day.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13))
      else
        ...selectedTasks.map((task) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(children: [
              Checkbox(
                value: task.isCompleted,
                onChanged: (value) => ref
                    .read(taskActionsProvider.notifier)
                    .setCompleted(task, value ?? false),
                visualDensity: VisualDensity.compact,
                activeColor: AppColors.success,
              ),
              const SizedBox(width: 4),
              Expanded(
                  child: Text(task.title,
                      style: TextStyle(
                          color: task.isCompleted
                              ? AppColors.textMuted
                              : AppColors.textPrimary,
                          decoration: task.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          fontSize: 13)))
            ]))),
    ]);
  }

  Widget _dayCell(int day, int daysInMonth) {
    if (day < 1 || day > daysInMonth)
      return const Expanded(child: SizedBox(height: 38));
    final date = DateTime(_month.year, _month.month, day);
    final selected = _same(date, _selected);
    final hasTasks = widget.tasks.any((task) => _same(task.dueAt, date));
    return Expanded(
        child: InkWell(
            borderRadius: BorderRadius.circular(9),
            onTap: () => setState(() => _selected = date),
            child: SizedBox(
                height: 38,
                child: Stack(alignment: Alignment.center, children: [
                  if (selected)
                    Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(9))),
                  Text('$day',
                      style: TextStyle(
                          color:
                              selected ? Colors.white : AppColors.textSecondary,
                          fontSize: 12)),
                  if (hasTasks)
                    Positioned(
                        bottom: 2,
                        child: Container(
                            width: 4,
                            height: 4,
                            decoration: const BoxDecoration(
                                color: AppColors.secondary,
                                shape: BoxShape.circle))),
                ]))));
  }

  Future<void> _addTask() async {
    final title = TextEditingController();
    final result = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
              backgroundColor: AppColors.bgCard,
              title: Text('Add for ${DateFormat('MMM d').format(_selected)}'),
              content: TextField(
                  controller: title,
                  autofocus: true,
                  decoration: const InputDecoration(
                      labelText: 'What needs to be done?')),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel')),
                FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Add task'))
              ],
            ));
    final text = title.text.trim();
    title.dispose();
    if (result == true && text.isNotEmpty)
      await ref.read(taskActionsProvider.notifier).add(text, dueAt: _selected);
  }
}
