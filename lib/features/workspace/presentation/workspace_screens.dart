import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../auth/presentation/auth_provider.dart';
import '../../tasks/data/task_model.dart';
import '../../tasks/presentation/tasks_provider.dart';
import '../../../core/constants/app_colors.dart';

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

class WorkspaceHeader extends StatelessWidget {
  const WorkspaceHeader(
      {super.key,
      required this.title,
      required this.subtitle,
      required this.actionLabel,
      required this.onAction});
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 29,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 7),
                Text(subtitle,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 14)),
              ])),
          FilledButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(actionLabel)),
        ]),
      );
}

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(firebaseAuthStateProvider).value?.uid ?? '';
    final goals = ref.watch(_goalsProvider(uid));
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: MediaQuery.sizeOf(context).width < 900
          ? AppBar(title: const Text('Goals'))
          : null,
      body: Center(
          child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1060),
              child: Column(children: [
                WorkspaceHeader(
                    title: 'Goals',
                    subtitle: 'Turn your bigger ambitions into clear outcomes.',
                    actionLabel: 'New Goal',
                    onAction: () => _addGoal(context, uid)),
                Expanded(
                    child: goals.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const _WorkspaceMessage(
                      'Goals are unavailable right now.'),
                  data: (items) => items.isEmpty
                      ? const _WorkspaceMessage(
                          'No goals yet. Add one clear outcome to begin.')
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                          itemCount: items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (_, index) =>
                              _GoalCard(doc: items[index], uid: uid)),
                )),
              ]))),
    );
  }

  Future<void> _addGoal(BuildContext context, String uid) async {
    if (uid.isEmpty) return;
    final title = TextEditingController();
    final description = TextEditingController();
    final target = TextEditingController(text: '5');
    final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('New Goal'),
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(
                    controller: title,
                    autofocus: true,
                    decoration: const InputDecoration(labelText: 'Goal title')),
                TextField(
                    controller: description,
                    decoration:
                        const InputDecoration(labelText: 'Description')),
                TextField(
                    controller: target,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Milestones')),
              ]),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel')),
                FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Create'))
              ],
            ));
    final name = title.text.trim();
    final count = int.tryParse(target.text) ?? 5;
    if (result == true && name.isNotEmpty && count > 0) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('goals')
          .add({
        'title': name,
        'description': description.text.trim(),
        'target': count,
        'progress': 0,
        'category': 'General',
        'status': 'Active',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    title.dispose();
    description.dispose();
    target.dispose();
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.doc, required this.uid});
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final String uid;

  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    final progress = (data['progress'] as num?)?.toInt() ?? 0;
    final target = (data['target'] as num?)?.toInt() ?? 1;
    final ratio = (progress / target).clamp(0.0, 1.0);
    return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: AppColors.bgCard,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(14)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
                child: Text(data['title'] as String? ?? 'Goal',
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w700))),
            Text(data['status'] as String? ?? 'Active',
                style: const TextStyle(color: AppColors.success, fontSize: 12))
          ]),
          if ((data['description'] as String? ?? '').isNotEmpty) ...[
            const SizedBox(height: 7),
            Text(data['description'] as String,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13))
          ],
          const SizedBox(height: 18),
          Row(children: [
            const Expanded(
                child: Text('Milestone progress',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12))),
            Text('$progress of $target',
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12))
          ]),
          const SizedBox(height: 8),
          LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              borderRadius: BorderRadius.circular(4),
              color: AppColors.primary,
              backgroundColor: AppColors.bgElevated),
          const SizedBox(height: 14),
          Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                  onPressed: progress >= target
                      ? null
                      : () => doc.reference
                          .update({'progress': FieldValue.increment(1)}),
                  icon: const Icon(Icons.flag_outlined, size: 17),
                  label: const Text('Log milestone'))),
        ]));
  }
}

class HabitsScreen extends ConsumerWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(firebaseAuthStateProvider).value?.uid ?? '';
    final habits = ref.watch(_habitsProvider(uid));
    return Scaffold(
        backgroundColor: AppColors.bg,
        appBar: MediaQuery.sizeOf(context).width < 900
            ? AppBar(title: const Text('Habits'))
            : null,
        body: Center(
            child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1060),
                child: Column(children: [
                  WorkspaceHeader(
                      title: 'Habits',
                      subtitle: 'Build routines that compound over time.',
                      actionLabel: 'New Habit',
                      onAction: () => _addHabit(context, uid)),
                  Expanded(
                      child: habits.when(
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (_, __) => const _WorkspaceMessage(
                              'Habits are unavailable right now.'),
                          data: (items) => items.isEmpty
                              ? const _WorkspaceMessage(
                                  'No habits yet. Add a routine you want to repeat.')
                              : ListView.separated(
                                  padding:
                                      const EdgeInsets.fromLTRB(24, 0, 24, 32),
                                  itemCount: items.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 12),
                                  itemBuilder: (_, index) =>
                                      _HabitCard(doc: items[index])))),
                ]))));
  }

  Future<void> _addHabit(BuildContext context, String uid) async {
    if (uid.isEmpty) return;
    final title = TextEditingController();
    final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                title: const Text('New Habit'),
                content: TextField(
                    controller: title,
                    autofocus: true,
                    decoration: const InputDecoration(labelText: 'Habit name')),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Create'))
                ]));
    final name = title.text.trim();
    if (result == true && name.isNotEmpty)
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('habits')
          .add({
        'title': name,
        'frequency': 'Every day',
        'completedDates': <String>[],
        'createdAt': FieldValue.serverTimestamp()
      });
    title.dispose();
  }
}

class _HabitCard extends StatelessWidget {
  const _HabitCard({required this.doc});
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final dates = List<String>.from(data['completedDates'] ?? const <String>[]);
    final done = dates.contains(today);
    final week = List.generate(
            7, (index) => DateTime.now().subtract(Duration(days: 6 - index)))
        .map((date) => DateFormat('yyyy-MM-dd').format(date))
        .toList();
    return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: AppColors.bgCard,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(14)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
                child: Text(data['title'] as String? ?? 'Habit',
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w700))),
            Text(data['frequency'] as String? ?? 'Every day',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12))
          ]),
          const SizedBox(height: 18),
          Row(
              children: week
                  .map((date) => Expanded(
                          child: Column(children: [
                        Text(
                            DateFormat('E')
                                .format(DateTime.parse(date))
                                .substring(0, 1),
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 11)),
                        const SizedBox(height: 8),
                        Icon(
                            dates.contains(date)
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                            color: dates.contains(date)
                                ? AppColors.success
                                : AppColors.textMuted,
                            size: 21)
                      ])))
                  .toList()),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
                child: Text('${dates.length} completed days',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13))),
            OutlinedButton.icon(
                onPressed: () => doc.reference.update({
                      'completedDates': done
                          ? FieldValue.arrayRemove([today])
                          : FieldValue.arrayUnion([today])
                    }),
                icon: Icon(done ? Icons.check : Icons.add_task, size: 17),
                label: Text(done ? 'Completed' : 'Mark complete'))
          ]),
        ]));
  }
}

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});
  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selected =
      DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  bool _same(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(tasksProvider);
    return Scaffold(
        backgroundColor: AppColors.bg,
        appBar: MediaQuery.sizeOf(context).width < 900
            ? AppBar(title: const Text('Calendar'))
            : null,
        body: tasks.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const _WorkspaceMessage(
                'Calendar data is unavailable right now.'),
            data: (items) => _calendarBody(context, items)));
  }

  Widget _calendarBody(BuildContext context, List<TaskModel> tasks) {
    final first = DateTime(_month.year, _month.month, 1).weekday - 1;
    final count = DateTime(_month.year, _month.month + 1, 0).day;
    final selected =
        tasks.where((task) => _same(task.dueAt, _selected)).toList();
    final weekdays = <Widget>[
      for (final label in ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
        Expanded(
            child: Center(
                child: Text(label,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 11)))),
    ];
    final calendarRows = <Widget>[
      for (var row = 0; row < (first + count + 6) ~/ 7; row++)
        Row(children: [
          for (var col = 0; col < 7; col++)
            _dayCell(row * 7 + col - first + 1, count, tasks),
        ]),
    ];
    final selectedWidgets = selected.isEmpty
        ? <Widget>[
            const Text('No scheduled tasks for this date.',
                style: TextStyle(color: AppColors.textSecondary)),
          ]
        : <Widget>[
            for (final task in selected)
              ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                      task.isCompleted ? Icons.check_circle : Icons.event_note,
                      color: task.isCompleted
                          ? AppColors.success
                          : AppColors.primary),
                  title: Text(task.title),
                  subtitle:
                      Text(task.isCompleted ? 'Completed' : 'Scheduled task')),
          ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
      children: [
        Row(children: [
          const Expanded(
              child: Text('Calendar',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 29,
                      fontWeight: FontWeight.w700))),
          TextButton(
              onPressed: () => setState(() {
                    _month =
                        DateTime(DateTime.now().year, DateTime.now().month);
                    _selected = DateTime.now();
                  }),
              child: const Text('Today')),
          IconButton(
              onPressed: () => setState(
                  () => _month = DateTime(_month.year, _month.month - 1)),
              icon: const Icon(Icons.chevron_left)),
          Text(DateFormat('MMMM yyyy').format(_month),
              style: const TextStyle(
                  color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
          IconButton(
              onPressed: () => setState(
                  () => _month = DateTime(_month.year, _month.month + 1)),
              icon: const Icon(Icons.chevron_right)),
        ]),
        const SizedBox(height: 18),
        Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: AppColors.bgCard,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(14)),
            child: Column(children: [
              Row(children: weekdays),
              const SizedBox(height: 8),
              ...calendarRows
            ])),
        const SizedBox(height: 22),
        Text(DateFormat('EEEE, d MMMM').format(_selected),
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        ...selectedWidgets,
        const SizedBox(height: 12),
        Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
                onPressed: () => _addTask(context),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Schedule task'))),
      ],
    );
  }

  Widget _dayCell(int day, int daysInMonth, List<TaskModel> tasks) {
    if (day < 1 || day > daysInMonth)
      return const Expanded(child: SizedBox(height: 42));
    final date = DateTime(_month.year, _month.month, day);
    final selected = _same(date, _selected);
    final hasTask = tasks.any((task) => _same(task.dueAt, date));
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selected = date),
        child: SizedBox(
          height: 42,
          child: Stack(alignment: Alignment.center, children: [
            if (selected)
              Container(
                  width: 31,
                  height: 31,
                  decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(9))),
            Text('$day',
                style: TextStyle(
                    color: selected ? Colors.white : AppColors.textSecondary)),
            if (hasTask)
              const Positioned(
                  bottom: 2,
                  child:
                      Icon(Icons.circle, size: 4, color: AppColors.secondary)),
          ]),
        ),
      ),
    );
  }

  Future<void> _addTask(BuildContext context) async {
    final controller = TextEditingController();
    final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                title: const Text('Schedule task'),
                content: TextField(
                    controller: controller,
                    autofocus: true,
                    decoration: InputDecoration(
                        labelText:
                            'For ${DateFormat('MMM d').format(_selected)}')),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Add'))
                ]));
    final title = controller.text.trim();
    controller.dispose();
    if (result == true && title.isNotEmpty)
      await ref.read(taskActionsProvider.notifier).add(title, dueAt: _selected);
  }
}

class DailyTasksScreen extends ConsumerWidget {
  const DailyTasksScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(tasksProvider);
    return Scaffold(
        backgroundColor: AppColors.bg,
        appBar: MediaQuery.sizeOf(context).width < 900
            ? AppBar(title: const Text('Daily Tasks'))
            : null,
        body: Center(
            child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1060),
                child: Column(children: [
                  WorkspaceHeader(
                      title: 'Daily Tasks',
                      subtitle: 'Keep today clear, concrete, and moving.',
                      actionLabel: 'New Task',
                      onAction: () => _addTask(context, ref)),
                  Expanded(
                      child: tasks.when(
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (_, __) => const _WorkspaceMessage(
                              'Tasks are unavailable right now.'),
                          data: (items) => items.isEmpty
                              ? const _WorkspaceMessage(
                                  'No tasks yet. Add the next thing that needs your attention.')
                              : ListView.separated(
                                  padding:
                                      const EdgeInsets.fromLTRB(24, 0, 24, 32),
                                  itemCount: items.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 8),
                                  itemBuilder: (_, index) =>
                                      _TaskRow(task: items[index], ref: ref))))
                ]))));
  }

  Future<void> _addTask(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                title: const Text('New Task'),
                content: TextField(
                    controller: controller,
                    autofocus: true,
                    decoration: const InputDecoration(
                        labelText: 'What needs to be done?')),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Add'))
                ]));
    final title = controller.text.trim();
    controller.dispose();
    if (result == true && title.isNotEmpty)
      await ref.read(taskActionsProvider.notifier).add(title);
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({required this.task, required this.ref});
  final TaskModel task;
  final WidgetRef ref;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
          color: AppColors.bgCard,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(11)),
      child: Row(children: [
        Checkbox(
            value: task.isCompleted,
            onChanged: (value) => ref
                .read(taskActionsProvider.notifier)
                .setCompleted(task, value ?? false),
            activeColor: AppColors.success),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(task.title,
              style: TextStyle(
                  color: task.isCompleted
                      ? AppColors.textMuted
                      : AppColors.textPrimary,
                  decoration:
                      task.isCompleted ? TextDecoration.lineThrough : null,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 3),
          Text(DateFormat('EEE, d MMM').format(task.dueAt),
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12))
        ])),
        IconButton(
            tooltip: 'Delete task',
            onPressed: () =>
                ref.read(taskActionsProvider.notifier).delete(task.id),
            icon: const Icon(Icons.delete_outline,
                color: AppColors.textMuted, size: 19))
      ]));
}

class _WorkspaceMessage extends StatelessWidget {
  const _WorkspaceMessage(this.message);
  final String message;
  @override
  Widget build(BuildContext context) => Center(
      child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary))));
}
