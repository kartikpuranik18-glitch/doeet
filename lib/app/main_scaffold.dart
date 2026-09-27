import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../core/constants/app_colors.dart';
import '../features/auth/presentation/auth_provider.dart';
import '../features/voice/data/voice_executor.dart';
import '../features/voice/data/voice_parser.dart';
import '../features/voice/domain/voice_intent.dart';

class MainScaffold extends StatelessWidget {
  const MainScaffold({super.key, required this.child});
  final Widget child;

  static const _items = <_NavItem>[
    _NavItem('Learn', Icons.play_circle_outline_rounded, '/courses'),
    _NavItem('Dashboard', Icons.space_dashboard_outlined, '/home'),
    _NavItem('Notes', Icons.sticky_note_2_outlined, '/notes'),
    _NavItem('Progress', Icons.insights_outlined, '/analytics'),
    _NavItem('Settings', Icons.settings_outlined, '/settings'),
  ];
  static const _workspaceItems = <_NavItem>[
    _NavItem('Learn', Icons.play_circle_outline_rounded, '/courses'),
    _NavItem('Dashboard', Icons.space_dashboard_outlined, '/home'),
    _NavItem('Calendar', Icons.calendar_month_outlined, '/calendar'),
    _NavItem('Daily Tasks', Icons.checklist_rounded, '/tasks'),
    _NavItem('Goals', Icons.flag_outlined, '/goals'),
    _NavItem('Notes', Icons.sticky_note_2_outlined, '/notes'),
    _NavItem('Habits', Icons.local_fire_department_outlined, '/habits'),
    _NavItem('Analytics', Icons.insights_outlined, '/analytics'),
    _NavItem('Achievements', Icons.emoji_events_outlined, '/badges'),
    _NavItem('Settings', Icons.settings_outlined, '/settings'),
  ];
  static const _mobileMoreItems = <_NavItem>[
    _NavItem('Calendar', Icons.calendar_month_outlined, '/calendar'),
    _NavItem('Daily Tasks', Icons.checklist_rounded, '/tasks'),
    _NavItem('Goals', Icons.flag_outlined, '/goals'),
    _NavItem('Habits', Icons.local_fire_department_outlined, '/habits'),
    _NavItem('Achievements', Icons.emoji_events_outlined, '/badges'),
    _NavItem('Settings', Icons.settings_outlined, '/settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final width = MediaQuery.sizeOf(context).width;
    final desktop = width >= 900;
    final active = _activeIndex(location);
    final section = GoRouterState.of(context).uri.queryParameters['section'];
    if (!desktop) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        body: child,
        bottomNavigationBar: _MobileNav(activeIndex: active),
        floatingActionButton: const VoiceAssistantButton(compact: true),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Row(
        children: [
          SizedBox(
            width: 244,
            child: _Sidebar(location: location, section: section),
          ),
          Expanded(
            child: Column(
              children: [
                _Topbar(location: location),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static int _activeIndex(String location) {
    if (location.startsWith('/course') || location.startsWith('/player')) {
      return 0;
    }
    if (location.startsWith('/home')) return 1;
    if (location == '/calendar' ||
        location == '/tasks' ||
        location == '/goals' ||
        location == '/habits') return 1;
    if (location.startsWith('/note')) return 2;
    if (location.startsWith('/analytics')) return 3;
    return 4;
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.location, required this.section});
  final String location;
  final String? section;

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.bgCard,
          border: Border(right: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 20, 16, 28),
                child: Row(children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(.18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.check_rounded,
                        color: AppColors.primaryLight, size: 21),
                  ),
                  const SizedBox(width: 11),
                  const Text('doeet',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -.4,
                      )),
                ]),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 16, 9),
                child: Text('WORKSPACE',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    )),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    for (final item in MainScaffold._workspaceItems)
                      _SidebarItem(item: item, selected: _selected(item)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const _VoiceSheet(),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(13),
                      child: const Row(children: [
                        Icon(Icons.mic_none_rounded,
                            color: AppColors.secondary, size: 19),
                        SizedBox(width: 9),
                        Expanded(
                            child: Text('Talk to Doeet',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ))),
                        Icon(Icons.arrow_forward_ios_rounded,
                            color: AppColors.textMuted, size: 12),
                      ]),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  bool _selected(_NavItem item) {
    if (item.label == 'Achievements' &&
        (location == '/badges' || location == '/leaderboard')) {
      return true;
    }
    final uri = Uri.parse(item.route);
    return uri.path == location && uri.queryParameters['section'] == section;
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({required this.item, required this.selected});
  final _NavItem item;
  final bool selected;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        child: Material(
          color: selected
              ? AppColors.primary.withOpacity(.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          child: InkWell(
            borderRadius: BorderRadius.circular(9),
            onTap: () => context.go(item.route),
            child: SizedBox(
              height: 43,
              child: Row(children: [
                if (selected)
                  Container(
                    width: 3,
                    height: 20,
                    decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(3)),
                  )
                else
                  const SizedBox(width: 3),
                const SizedBox(width: 12),
                Icon(item.icon,
                    size: 19,
                    color: selected
                        ? AppColors.primaryLight
                        : AppColors.textSecondary),
                const SizedBox(width: 11),
                Text(item.label,
                    style: TextStyle(
                      color: selected
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    )),
              ]),
            ),
          ),
        ),
      );
}

class _Topbar extends StatelessWidget {
  const _Topbar({required this.location});
  final String location;

  @override
  Widget build(BuildContext context) {
    final requestedSection =
        GoRouterState.of(context).uri.queryParameters['section'];
    final title = switch (location) {
      '/tasks' => 'Daily Tasks',
      '/calendar' => 'Calendar',
      '/goals' => 'Goals',
      '/habits' => 'Habits',
      _ when location.startsWith('/home') => 'Dashboard',
      _ when location.startsWith('/course') || location.startsWith('/player') =>
        'Learn',
      _ when location.startsWith('/notes') => 'Notes',
      _ when location.startsWith('/analytics') => switch (requestedSection) {
          'calendar' => 'Calendar',
          'goals' => 'Goals',
          'habits' => 'Habits',
          _ => 'Progress',
        },
      '/badges' || '/leaderboard' => 'Achievements',
      _ when location.startsWith('/settings') => 'Settings',
      _ when location.startsWith('/ai-assistant') => 'Assistant',
      _ => 'Doeet',
    };
    final now = DateTime.now();
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(children: [
        Text(title,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600)),
        const Spacer(),
        Text('${months[now.month - 1]} ${now.day}, ${now.year}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            )),
        const SizedBox(width: 18),
        if (location.startsWith('/courses'))
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              onPressed: () => context.go('/import-course'),
              icon: const Icon(Icons.add_rounded, size: 17),
              label: const Text('Import course'),
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            ),
          ),
        const VoiceAssistantButton(),
      ]),
    );
  }
}

class _MobileNav extends StatelessWidget {
  const _MobileNav({required this.activeIndex});
  final int activeIndex;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(
            color: AppColors.bgCard,
            border: Border(top: BorderSide(color: AppColors.border))),
        child: SafeArea(
            top: false,
            child: SizedBox(
              height: 60,
              child: Row(children: [
                for (var i = 0; i < 5; i++)
                  Expanded(
                      child: InkWell(
                    onTap: i < 4
                        ? () => context.go(MainScaffold._items[i].route)
                        : () => showModalBottomSheet<void>(
                              context: context,
                              backgroundColor: AppColors.bgCard,
                              builder: (sheetContext) => SafeArea(
                                child: ListView(
                                  shrinkWrap: true,
                                  children: [
                                    for (final item
                                        in MainScaffold._mobileMoreItems)
                                      ListTile(
                                        leading: Icon(item.icon,
                                            color: AppColors.primary),
                                        title: Text(item.label),
                                        onTap: () {
                                          Navigator.pop(sheetContext);
                                          context.go(item.route);
                                        },
                                      ),
                                  ],
                                ),
                              ),
                            ),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                              i < 4
                                  ? MainScaffold._items[i].icon
                                  : Icons.more_horiz_rounded,
                              size: 20,
                              color: activeIndex == i
                                  ? AppColors.primaryLight
                                  : AppColors.textMuted),
                          const SizedBox(height: 3),
                          Text(i < 4 ? MainScaffold._items[i].label : 'More',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: activeIndex == i
                                      ? AppColors.primaryLight
                                      : AppColors.textSecondary)),
                        ]),
                  )),
              ]),
            )),
      );
}

class _NavItem {
  const _NavItem(this.label, this.icon, this.route);
  final String label;
  final IconData icon;
  final String route;
}

class VoiceAssistantButton extends ConsumerWidget {
  const VoiceAssistantButton({super.key, this.compact = false});
  final bool compact;
  @override
  Widget build(BuildContext context, WidgetRef ref) => compact
      ? FloatingActionButton.small(
          heroTag: 'doeet-voice',
          backgroundColor: AppColors.primary,
          onPressed: () => _open(context),
          child: const Icon(Icons.mic_none_rounded))
      : SizedBox(
          width: 150,
          child: OutlinedButton.icon(
              onPressed: () => _open(context),
              icon: const Icon(Icons.mic_none_rounded, size: 18),
              label: const Text('Talk to Doeet'),
              style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.border),
                  backgroundColor: AppColors.bgCard,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)))));
  void _open(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _VoiceSheet());
}

class _VoiceSheet extends ConsumerStatefulWidget {
  const _VoiceSheet();
  @override
  ConsumerState<_VoiceSheet> createState() => _VoiceSheetState();
}

class _VoiceSheetState extends ConsumerState<_VoiceSheet> {
  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();
  final VoiceIntentParser _parser = const VoiceIntentParser();
  final VoiceActionExecutor _executor = VoiceActionExecutor();
  final TextEditingController _commandController = TextEditingController();
  Future<bool>? _initializeFuture;
  bool _available = false, _listening = false, _working = false;
  String _heard = '';
  String _status = 'Try “task call the dentist” or “goal read 12 books”.';
  @override
  void initState() {
    super.initState();
    final initialize = _speech.initialize(
      onStatus: (value) {
        if (mounted) setState(() => _listening = value == 'listening');
      },
      onError: (error) {
        if (mounted)
          setState(() {
            _listening = false;
            _status = error.errorMsg.toLowerCase().contains('permission')
                ? 'Allow microphone access to use voice commands.'
                : 'Voice recognition is unavailable in this browser.';
          });
      },
    );
    _initializeFuture = initialize;
    initialize.then((available) {
      if (mounted)
        setState(() {
          _available = available;
          if (!available) _status = 'Voice recognition is not supported here.';
        });
    });
  }

  Future<void> _listen() async {
    if (_listening) {
      await _speech.stop();
      return;
    }
    if (!_available && _initializeFuture != null) {
      final ready = await _initializeFuture!;
      if (!mounted) return;
      setState(() => _available = ready);
    }
    if (!_available) {
      setState(() => _status = 'Allow microphone access and try again.');
      return;
    }
    setState(() {
      _heard = '';
      _status = 'Listening…';
    });
    await _speech.listen(
        listenFor: const Duration(seconds: 12),
        pauseFor: const Duration(seconds: 3),
        listenOptions: SpeechListenOptions(partialResults: true),
        onResult: (SpeechRecognitionResult result) {
          if (!mounted) return;
          setState(() => _heard = result.recognizedWords);
          if (result.finalResult && result.recognizedWords.trim().isNotEmpty)
            _run(result.recognizedWords.trim());
        });
  }

  Future<void> _run(String phrase) async {
    if (_working) return;
    setState(() {
      _working = true;
      _status = 'Understanding your request…';
    });
    try {
      final uid = ref.read(firebaseAuthStateProvider).value?.uid ?? '';
      final intent = _parser.parse(phrase);
      if (intent.needsConfirmation) {
        final confirmed =
            await _confirmDelete('task', intent.title ?? 'this item');
        if (!confirmed) {
          if (mounted) setState(() => _status = 'Nothing was deleted.');
          return;
        }
      }
      final result = await _executor.execute(uid, intent);
      await _tts.stop();
      await _tts.speak(result.message);
      if (!mounted) return;
      setState(() {
        _heard = phrase;
        _status = result.message;
      });
      if (result.route != null) {
        Navigator.of(context).pop();
        if (mounted) context.go(result.route!);
      }
    } on VoiceCommandException catch (error) {
      if (mounted) {
        setState(() => _status = error.message);
        await _tts.speak(error.message);
      }
    } catch (_) {
      if (mounted) {
        const message =
            'That action failed. Check your connection and try again.';
        setState(() => _status = message);
        await _tts.speak(message);
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  /* Legacy inline command executor removed in favor of VoiceActionExecutor.
  Future<void> _runLegacy(String phrase) async {
    if (_working) return;
    setState(() {
      _working = true;
      _status = 'Working on it…';
    });
    try {
      final text = phrase.trim();
      final lower = text.toLowerCase();
      final uid = ref.read(firebaseAuthStateProvider).value?.uid;
      final db = FirebaseFirestore.instance;
      const routes = <String, String>{
        'dashboard': '/home',
        'today': '/home',
        'home': '/home',
        'tasks': '/home?section=tasks',
        'courses': '/courses',
        'course': '/courses',
        'learn': '/courses',
        'notes': '/notes',
        'progress': '/analytics',
        'analytics': '/analytics',
        'settings': '/settings',
        'assistant': '/ai-assistant',
        'ai assistant': '/ai-assistant',
        'calendar': '/analytics?section=calendar',
        'goals': '/analytics?section=goals',
        'habits': '/analytics?section=habits',
        'achievements': '/badges',
      };
      final open = RegExp(r'^(?:open|show|go to|take me to)\s+(.+)$',
              caseSensitive: false)
          .firstMatch(text);
      if (open != null &&
          routes.containsKey(open.group(1)!.toLowerCase().trim())) {
        final route = routes[open.group(1)!.toLowerCase().trim()]!;
        if (mounted) Navigator.of(context).pop();
        if (mounted) context.go(route);
        return;
      }
      final addTask = RegExp(
              r'^(?:(?:add|create)\s+(?:a\s+)?task\s+(?:to\s+)?|task\s+)(.+)$',
              caseSensitive: false)
          .firstMatch(text);
      if (addTask != null) {
        if (uid == null) throw const _VoiceError('Sign in to add tasks.');
        var raw = addTask.group(1)!.trim();
        final phraseLower = raw.toLowerCase();
        DateTime? due;
        final now = DateTime.now();
        if (phraseLower.endsWith(' tomorrow')) {
          due = now.add(const Duration(days: 1));
          raw = raw.substring(0, raw.length - 9);
        } else if (phraseLower.endsWith(' next week')) {
          due = now.add(const Duration(days: 7));
          raw = raw.substring(0, raw.length - 10);
        } else if (phraseLower.endsWith(' today')) {
          due = now;
          raw = raw.substring(0, raw.length - 6);
        }
        final title = _clean(raw);
        if (title.isEmpty)
          throw const _VoiceError('Say the task after “add a task”.');
        await ref.read(taskActionsProvider.notifier).add(title, dueAt: due);
        _checkTaskAction();
        _say(due == null || _sameDate(due, now)
            ? 'Added “$title” to today.'
            : 'Added “$title” for ${DateFormat('MMMM d').format(due)}.');
        return;
      }
      final renameTask = RegExp(
              r'^(?:rename|change)\s+(?:the\s+)?task\s+(.+?)\s+to\s+(.+)$',
              caseSensitive: false)
          .firstMatch(text);
      if (renameTask != null) {
        final task = _findTask(_clean(renameTask.group(1)!));
        final title = _clean(renameTask.group(2)!);
        if (task == null || title.isEmpty) {
          throw const _VoiceError(
              'I couldn’t match that task. Say its full name and the new title.');
        }
        await ref.read(taskActionsProvider.notifier).rename(task, title);
        _checkTaskAction();
        _say('Renamed the task to “$title”.');
        return;
      }
      final reschedule = RegExp(
              r'^(?:reschedule|move)\s+(?:the\s+)?task\s+(.+?)\s+(?:to\s+)?(today|tomorrow|next week)$',
              caseSensitive: false)
          .firstMatch(text);
      if (reschedule != null) {
        final task = _findTask(_clean(reschedule.group(1)!));
        if (task == null)
          throw const _VoiceError(
              'I couldn’t find that task. Try its full name.');
        final day = reschedule.group(2)!.toLowerCase(), now = DateTime.now();
        final due = day == 'tomorrow'
            ? now.add(const Duration(days: 1))
            : day == 'next week'
                ? now.add(const Duration(days: 7))
                : now;
        await ref.read(taskActionsProvider.notifier).reschedule(task, due);
        _checkTaskAction();
        _say('Moved “${task.title}” to ${DateFormat('MMMM d').format(due)}.');
        return;
      }
      final addGoal = RegExp(
              r'^(?:(?:create|add)\s+(?:a\s+)?goal\s+|goal\s+)(.+)$',
              caseSensitive: false)
          .firstMatch(text);
      if (addGoal != null) {
        if (uid == null) throw const _VoiceError('Sign in to manage goals.');
        final title = _clean(addGoal.group(1)!);
        if (title.isEmpty) {
          throw const _VoiceError('Say the goal name after “goal”.');
        }
        await db.collection('users').doc(uid).collection('goals').add({
          'title': title,
          'target': 10,
          'progress': 0,
          'createdAt': FieldValue.serverTimestamp()
        });
        _say('Added the goal “$title”.');
        return;
      }
      final goalTarget = RegExp(
              r'^(?:set|change)\s+(?:the\s+)?goal\s+(.+?)\s+target\s+to\s+(\d+)$',
              caseSensitive: false)
          .firstMatch(text);
      if (goalTarget != null) {
        if (uid == null) throw const _VoiceError('Sign in to manage goals.');
        final title = _clean(goalTarget.group(1)!);
        final target = int.parse(goalTarget.group(2)!);
        final docs =
            await db.collection('users').doc(uid).collection('goals').get();
        final matches = docs.docs
            .where((doc) =>
                (doc.data()['title'] as String? ?? '').toLowerCase() ==
                title.toLowerCase())
            .toList();
        if (matches.length != 1)
          throw const _VoiceError(
              'I couldn’t find one matching goal. Say its full name.');
        await matches.single.reference.update({'target': target});
        _say('Updated the target for “$title” to $target.');
        return;
      }
      final addHabit = RegExp(r'^(?:create|add)\s+(?:a\s+)?habit\s+(.+)$',
              caseSensitive: false)
          .firstMatch(text);
      if (addHabit != null) {
        if (uid == null) throw const _VoiceError('Sign in to manage habits.');
        final title = _clean(addHabit.group(1)!);
        await db.collection('users').doc(uid).collection('habits').add({
          'title': title,
          'completedDates': <String>[],
          'createdAt': FieldValue.serverTimestamp()
        });
        _say('Added the habit “$title”.');
        return;
      }
      final habitDone = RegExp(
              r'^(?:complete|finish|mark)\s+(?:the\s+)?habit\s+(.+?)(?:\s+(?:done|complete))?$',
              caseSensitive: false)
          .firstMatch(text);
      if (habitDone != null) {
        if (uid == null) throw const _VoiceError('Sign in to manage habits.');
        final title = _clean(habitDone.group(1)!);
        final docs =
            await db.collection('users').doc(uid).collection('habits').get();
        final matches = docs.docs
            .where((doc) =>
                (doc.data()['title'] as String? ?? '').toLowerCase() ==
                title.toLowerCase())
            .toList();
        if (matches.length != 1)
          throw const _VoiceError(
              'I couldn’t find one matching habit. Say its full name.');
        final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
        await matches.single.reference.update({
          'completedDates': FieldValue.arrayUnion([today])
        });
        _say('Marked “$title” complete for today.');
        return;
      }
      final goalProgress = RegExp(
              r'^(?:log|add)\s+(?:progress|a step)\s+(?:for|to)\s+(.+)$',
              caseSensitive: false)
          .firstMatch(text);
      if (goalProgress != null) {
        if (uid == null) throw const _VoiceError('Sign in to manage goals.');
        final title = _clean(goalProgress.group(1)!);
        final docs =
            await db.collection('users').doc(uid).collection('goals').get();
        final matches = docs.docs
            .where((doc) =>
                (doc.data()['title'] as String? ?? '').toLowerCase() ==
                title.toLowerCase())
            .toList();
        if (matches.length != 1)
          throw const _VoiceError(
              'I couldn’t find one matching goal. Say its full name.');
        await matches.single.reference
            .update({'progress': FieldValue.increment(1)});
        _say('Logged progress for “$title”.');
        return;
      }
      final renameItem = RegExp(
              r'^(?:rename|change)\s+(?:the\s+)?(note|goal|habit)\s+(.+?)\s+to\s+(.+)$',
              caseSensitive: false)
          .firstMatch(text);
      if (renameItem != null) {
        if (uid == null) throw const _VoiceError('Sign in to edit that item.');
        final kind = renameItem.group(1)!.toLowerCase();
        final collection = kind == 'note' ? 'notes' : '${kind}s';
        final oldTitle = _clean(renameItem.group(2)!);
        final newTitle = _clean(renameItem.group(3)!);
        final docs =
            await db.collection('users').doc(uid).collection(collection).get();
        final matches = docs.docs
            .where((doc) =>
                (doc.data()['title'] as String? ?? '').toLowerCase() ==
                oldTitle.toLowerCase())
            .toList();
        if (matches.length != 1 || newTitle.isEmpty)
          throw _VoiceError(
              'I couldn’t match that $kind. Say its full name and the new title.');
        await matches.single.reference.update({
          'title': newTitle,
          if (kind == 'note') 'updatedAt': FieldValue.serverTimestamp()
        });
        _say('Renamed the $kind to “$newTitle”.');
        return;
      }
      final editNote = RegExp(
              r'^(?:edit|update)\s+(?:the\s+)?note\s+(.+?)\s+to\s+(.+)$',
              caseSensitive: false)
          .firstMatch(text);
      if (editNote != null) {
        if (uid == null) throw const _VoiceError('Sign in to edit notes.');
        final title = _clean(editNote.group(1)!);
        final body = editNote.group(2)!.trim();
        final docs =
            await db.collection('users').doc(uid).collection('notes').get();
        final matches = docs.docs
            .where((doc) =>
                (doc.data()['title'] as String? ?? '').toLowerCase() ==
                title.toLowerCase())
            .toList();
        if (matches.length != 1 || body.isEmpty)
          throw const _VoiceError(
              'I couldn’t match that note. Say its full title and the new text.');
        await matches.single.reference.update(
            {'content': body, 'updatedAt': FieldValue.serverTimestamp()});
        _say('Updated the note “$title”.');
        return;
      }
      final deleteItem = RegExp(
              r'^(?:delete|remove)\s+(?:the\s+)?(task|note|goal|habit)\s+(.+)$',
              caseSensitive: false)
          .firstMatch(text);
      if (deleteItem != null) {
        final kind = deleteItem.group(1)!.toLowerCase(),
            title = _clean(deleteItem.group(2)!);
        if (uid == null)
          throw const _VoiceError('Sign in to remove that item.');
        final collection = switch (kind) {
          'task' => 'tasks',
          'note' => 'notes',
          'goal' => 'goals',
          _ => 'habits'
        };
        final docs =
            await db.collection('users').doc(uid).collection(collection).get();
        if (!mounted) return;
        final matches = docs.docs
            .where((doc) =>
                (doc.data()['title'] as String? ?? '').toLowerCase() ==
                title.toLowerCase())
            .toList();
        if (matches.length != 1)
          throw _VoiceError(
              'I couldn’t find one matching $kind. Say its full name.');
        final yes = await _confirmDelete(kind, title);
        if (!mounted) return;
        if (yes) {
          await matches.single.reference.delete();
          _say('Deleted “$title”.');
        } else {
          _say('Kept “$title”.');
        }
        return;
      }
      final taskDone = RegExp(
              r'^(?:complete|finish|mark)\s+(?:the\s+)?(?:task\s+)?(.+?)(?:\s+(?:done|complete))?$',
              caseSensitive: false)
          .firstMatch(text);
      if (taskDone != null) {
        final task = _findTask(_clean(taskDone.group(1)!));
        if (task == null)
          throw const _VoiceError(
              'I couldn’t find that task. Try its full name.');
        await ref.read(taskActionsProvider.notifier).setCompleted(task, true);
        _checkTaskAction();
        _say('Marked “${task.title}” complete.');
        return;
      }
      final note = RegExp(
              r'^(?:create|save|write)\s+(?:a\s+)?note\s+(?:that\s+)?(.+)$',
              caseSensitive: false)
          .firstMatch(text);
      if (note != null) {
        final body = note.group(1)!.trim(),
            title = body.length > 52 ? '${body.substring(0, 49)}…' : body;
        final id = await ref
            .read(notesNotifierProvider.notifier)
            .saveNote(courseId: 'general', title: title, content: body);
        if (id == null) throw const _VoiceError('The note could not be saved.');
        _say('Saved your note.');
        return;
      }
      if (lower.contains('how many') && lower.contains('task')) {
        final count =
            (ref.read(tasksProvider).valueOrNull ?? const <TaskModel>[])
                .where((t) => !t.isCompleted)
                .length;
        _say('You have $count open ${count == 1 ? 'task' : 'tasks'}.');
        return;
      }
      if (lower == 'sign out' || lower == 'log out') {
        final yes = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
                    backgroundColor: AppColors.bgCard,
                    title: const Text('Sign out of Doeet?'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Stay signed in')),
                      FilledButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Sign out'))
                    ]));
        if (!mounted || yes != true) return;
        await ref.read(authNotifierProvider.notifier).signOut();
        if (mounted) Navigator.of(context).pop();
        return;
      }
      final dailyGoal = RegExp(
              r'^(?:set|change)\s+(?:my\s+)?daily goal\s+to\s+(\d+)\s*(?:minutes?|mins?)?$',
              caseSensitive: false)
          .firstMatch(text);
      if (dailyGoal != null) {
        if (uid == null)
          throw const _VoiceError('Sign in to change your daily goal.');
        final minutes = int.parse(dailyGoal.group(1)!);
        await ref
            .read(authRepositoryProvider)
            .updateUser(uid, {'dailyGoalMinutes': minutes});
        _say('Set your daily goal to $minutes minutes.');
        return;
      }
      throw const _VoiceError(
          'I didn’t recognize that. Try a task, note, goal, habit, or “open calendar”.');
    } on _VoiceError catch (error) {
      if (mounted) setState(() => _status = error.message);
    } catch (_) {
      if (mounted)
        setState(() => _status =
            'That action failed. Check your connection and try again.');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  */

  Future<bool> _confirmDelete(String kind, String title) async =>
      await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
                  backgroundColor: AppColors.bgCard,
                  title: Text('Delete this $kind?'),
                  content: Text('Remove “$title”?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Keep it')),
                    FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Delete'))
                  ])) ??
      false;
  void _say(String text) {
    if (mounted) setState(() => _status = text);
  }

  @override
  void dispose() {
    _speech.cancel();
    _tts.stop();
    _commandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
          child: Padding(
        padding: EdgeInsets.fromLTRB(
            22, 12, 22, 22 + MediaQuery.viewInsetsOf(context).bottom),
        child: Container(
            width: 520,
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
            decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.border)),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AppColors.textMuted,
                      borderRadius: BorderRadius.circular(8))),
              const SizedBox(height: 24),
              Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _listening
                          ? AppColors.primary.withOpacity(.2)
                          : AppColors.bgElevated,
                      border: Border.all(
                          color: _listening
                              ? AppColors.primary
                              : AppColors.border)),
                  child: Icon(
                      _listening
                          ? Icons.graphic_eq_rounded
                          : Icons.mic_none_rounded,
                      color: _listening
                          ? AppColors.primaryLight
                          : AppColors.textSecondary,
                      size: 31)),
              const SizedBox(height: 18),
              const Text('Talk to Doeet',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 7),
              Text(_status,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.5)),
              if (_heard.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                        color: AppColors.bg,
                        borderRadius: BorderRadius.circular(10)),
                    child: Text('“$_heard”',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: AppColors.textPrimary, fontSize: 14)))
              ],
              const SizedBox(height: 22),
              SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: FilledButton.icon(
                      onPressed: _working ? null : _listen,
                      icon: Icon(
                          _listening ? Icons.stop_rounded : Icons.mic_rounded),
                      label: Text(
                          _listening ? 'Stop listening' : 'Start speaking'),
                      style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary))),
              const SizedBox(height: 16),
              TextField(
                controller: _commandController,
                textInputAction: TextInputAction.send,
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    _commandController.clear();
                    _run(value.trim());
                  }
                },
                decoration: InputDecoration(
                  hintText: 'Or type: task call the dentist',
                  suffixIcon: IconButton(
                    tooltip: 'Run command',
                    onPressed: _working
                        ? null
                        : () {
                            final command = _commandController.text.trim();
                            if (command.isNotEmpty) {
                              _commandController.clear();
                              _run(command);
                            }
                          },
                    icon: const Icon(Icons.send_rounded),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                  'Say “task call the dentist” or “goal read 12 books”. Try “open calendar” to navigate.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: AppColors.textMuted, fontSize: 11, height: 1.5)),
            ])),
      ));
}

class _VoiceError implements Exception {
  const _VoiceError(this.message);
  final String message;
}
