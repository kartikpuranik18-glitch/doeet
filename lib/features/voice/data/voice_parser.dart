import '../domain/voice_intent.dart';

class VoiceIntentParser {
  const VoiceIntentParser();

  VoiceIntent parse(String input, {DateTime? now}) {
    final text = _clean(input);
    final lower = text.toLowerCase();
    final current = now ?? DateTime.now();

    const routes = <String, String>{
      'dashboard': '/home',
      'today': '/tasks',
      'tasks': '/tasks',
      'daily tasks': '/tasks',
      'courses': '/courses',
      'course': '/courses',
      'learn': '/courses',
      'notes': '/notes',
      'progress': '/analytics',
      'analytics': '/analytics',
      'settings': '/settings',
      'calendar': '/calendar',
      'goals': '/goals',
      'habits': '/habits',
      'achievements': '/badges',
    };
    final navigation =
        RegExp(r'^(?:open|show|go to|take me to)\s+(.+)$', caseSensitive: false)
            .firstMatch(text);
    if (navigation != null) {
      final route = routes[navigation.group(1)!.toLowerCase().trim()];
      if (route != null)
        return VoiceIntent(type: VoiceIntentType.unknown, route: route);
    }

    if ((lower.contains('what') || lower.contains('show')) &&
      (lower.contains('task') || lower.contains('left for'))) {
      return const VoiceIntent(type: VoiceIntentType.listTasks);
    }
    if (lower.contains('show') && lower.contains('goal'))
      return const VoiceIntent(type: VoiceIntentType.listGoals);
    if (lower.contains('show') && lower.contains('habit'))
      return const VoiceIntent(type: VoiceIntentType.listHabits);
    if ((lower.contains('show') || lower.contains('search')) &&
        lower.contains('note')) {
      final query = _afterPhrase(text, ['for', 'about']);
      return VoiceIntent(
          type: lower.contains('search')
              ? VoiceIntentType.searchNotes
              : VoiceIntentType.listNotes,
          title: query);
    }
    if (lower.contains('calendar') || lower.contains('scheduled')) {
      return VoiceIntent(
          type: VoiceIntentType.listEvents, date: _dateFrom(lower, current));
    }

    final completeTask = RegExp(
            r'^(?:mark|complete|finish)\s+(?:the\s+)?(?:task\s+)?(.+?)(?:\s+(?:as\s+)?(?:complete|done))?$',
            caseSensitive: false)
        .firstMatch(text);
    if (completeTask != null && !lower.contains('habit'))
      return VoiceIntent(
          type: VoiceIntentType.completeTask,
          title: _clean(completeTask.group(1)!));
    final deleteTask = RegExp(
            r'^(?:delete|remove)\s+(?:my\s+)?(?:the\s+)?task\s+(.+)$',
            caseSensitive: false)
        .firstMatch(text);
    if (deleteTask != null)
      return VoiceIntent(
          type: VoiceIntentType.deleteTask,
          title: _clean(deleteTask.group(1)!));

    final task = RegExp(
            r'^(?:add|create|put|schedule|remind me(?:\s+at\s+[^ ]+(?:\s+(?:am|pm))?)?\s+to|i need to|don.t let me forget to)\s+(?:a\s+)?(?:task\s+to\s+)?(.+)$',
            caseSensitive: false)
        .firstMatch(text);
    if (task != null &&
        !lower.contains('goal') &&
        !lower.contains('habit') &&
        !lower.contains('note')) {
      final parsed = _splitDateTime(task.group(1)!, current);
      return VoiceIntent(
          type: lower.startsWith('schedule')
              ? VoiceIntentType.createEvent
              : lower.startsWith('remind')
                  ? VoiceIntentType.createReminder
                  : VoiceIntentType.createTask,
          title: parsed.text,
          date: parsed.date,
          time: parsed.time);
    }

    final goal = RegExp(r'^(?:create|add)\s+(?:a\s+)?goal\s+(?:to\s+)?(.+)$',
            caseSensitive: false)
        .firstMatch(text);
    if (goal != null)
      return VoiceIntent(
          type: VoiceIntentType.createGoal, title: _clean(goal.group(1)!));
    final goalProgress = RegExp(
            r'^(?:update|set)\s+(?:my\s+)?goal\s+(.+?)\s+(?:to\s+)?(\d+)\s*%?$',
            caseSensitive: false)
        .firstMatch(text);
    if (goalProgress != null)
      return VoiceIntent(
          type: VoiceIntentType.updateGoal,
          title: _clean(goalProgress.group(1)!),
          target: int.parse(goalProgress.group(2)!));
    final completeGoal = RegExp(
            r'^(?:mark|complete)\s+(?:my\s+)?goal\s+(.+?)(?:\s+as\s+completed)?$',
            caseSensitive: false)
        .firstMatch(text);
    if (completeGoal != null)
      return VoiceIntent(
          type: VoiceIntentType.completeGoal,
          title: _clean(completeGoal.group(1)!));

    final habit = RegExp(r'^(?:create|add)\s+(?:a\s+)?habit\s+(?:of\s+)?(.+)$',
            caseSensitive: false)
        .firstMatch(text);
    if (habit != null)
      return VoiceIntent(
          type: VoiceIntentType.createHabit,
          title: _clean(habit.group(1)!),
          recurrence: lower.contains('monday') ? 'weekly:monday' : 'daily');
    final completeHabit = RegExp(
            r'^(?:mark|complete)\s+(?:my\s+)?habit\s+(.+?)(?:\s+complete|\s+done)?$',
            caseSensitive: false)
        .firstMatch(text);
    if (completeHabit != null)
      return VoiceIntent(
          type: VoiceIntentType.completeHabit,
          title: _clean(completeHabit.group(1)!));

    final note = RegExp(
            r'^(?:create|save|write)\s+(?:a\s+)?note\s+(?:called\s+)?(.+)$',
            caseSensitive: false)
        .firstMatch(text);
    final takeNote = RegExp(r'^take a note[:\s]+(.+)$', caseSensitive: false)
        .firstMatch(text);
    if (note != null || takeNote != null) {
      final body = _clean((note ?? takeNote)!.group(1)!);
      return VoiceIntent(
          type: VoiceIntentType.createNote,
          title: body.length > 52 ? body.substring(0, 52) : body,
          content: body);
    }

    throw const VoiceCommandException(
        'I didn’t recognize that. Try “add a task to study tomorrow”, “create a goal”, or “take a note”.');
  }

  String _clean(String value) => value
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp(r'[.!?]+$'), '')
      .trim();

  String? _afterPhrase(String value, List<String> phrases) {
    final lower = value.toLowerCase();
    for (final phrase in phrases) {
      final index = lower.indexOf(' $phrase ');
      if (index != -1)
        return _clean(value.substring(index + phrase.length + 2));
    }
    return null;
  }

  DateTime? _dateFrom(String lower, DateTime now) {
    if (lower.contains('tomorrow'))
      return DateTime(now.year, now.month, now.day + 1);
    if (lower.contains('today')) return DateTime(now.year, now.month, now.day);
    final hours = RegExp(r'in (\d+) hours?').firstMatch(lower);
    if (hours != null)
      return now.add(Duration(hours: int.parse(hours.group(1)!)));
    return _weekdayDate(lower, now);
  }

  _ParsedText _splitDateTime(String value, DateTime now) {
    var text = _clean(value);
    DateTime? date;
    DateTime? time;
    final lower = text.toLowerCase();
    if (lower.contains('tomorrow')) {
      date = DateTime(now.year, now.month, now.day + 1);
      text =
          text.replaceFirst(RegExp(r'\s+tomorrow', caseSensitive: false), '');
    } else if (lower.contains('today')) {
      date = DateTime(now.year, now.month, now.day);
      text = text.replaceFirst(
          RegExp(r'\s+today(?:.s)?(?:\s+tasks?)?', caseSensitive: false), '');
    }
    final relativeHours =
        RegExp(r'\bin (\d+) hours?\b', caseSensitive: false).firstMatch(text);
    if (relativeHours != null) {
      date = now.add(Duration(hours: int.parse(relativeHours.group(1)!)));
      text = text.replaceFirst(relativeHours.group(0)!, '');
    }
    final weekday = _weekdayDate(text.toLowerCase(), now);
    if (weekday != null) {
      date = weekday;
      text = text.replaceFirst(
          RegExp(
              r'\b(?:on\s+)?(?:next\s+)?(?:monday|tuesday|wednesday|thursday|friday|saturday|sunday)\b',
              caseSensitive: false),
          '');
    }
    final timeMatch = RegExp(
            r'\b(?:at|around)\s+(\d{1,2})(?::(\d{2}))?\s*(am|pm)?\b',
            caseSensitive: false)
        .firstMatch(text);
    if (timeMatch != null) {
      var hour = int.parse(timeMatch.group(1)!);
      final minute = int.tryParse(timeMatch.group(2) ?? '0') ?? 0;
      final meridiem = timeMatch.group(3)?.toLowerCase();
      if (meridiem == 'pm' && hour < 12) hour += 12;
      if (meridiem == 'am' && hour == 12) hour = 0;
      time = DateTime(now.year, now.month, now.day, hour, minute);
      text = text.replaceFirst(timeMatch.group(0)!, '');
    }
    if (time == null && lower.contains('tonight')) {
      time = DateTime(now.year, now.month, now.day, 20);
      text = text.replaceFirst(RegExp(r'\s+tonight', caseSensitive: false), '');
    } else if (time == null && lower.contains('this evening')) {
      time = DateTime(now.year, now.month, now.day, 18);
      text = text.replaceFirst(
          RegExp(r'\s+this evening', caseSensitive: false), '');
    }
    return _ParsedText(_clean(text), date, time);
  }

  DateTime? _weekdayDate(String text, DateTime now) {
    const names = <String, int>{
      'monday': DateTime.monday,
      'tuesday': DateTime.tuesday,
      'wednesday': DateTime.wednesday,
      'thursday': DateTime.thursday,
      'friday': DateTime.friday,
      'saturday': DateTime.saturday,
      'sunday': DateTime.sunday,
    };
    for (final entry in names.entries) {
      if (!text.contains(entry.key)) continue;
      var delta = (entry.value - now.weekday) % 7;
      if (delta == 0 || text.contains('next ${entry.key}')) delta += 7;
      return DateTime(now.year, now.month, now.day + delta);
    }
    return null;
  }
}

class _ParsedText {
  const _ParsedText(this.text, this.date, this.time);
  final String text;
  final DateTime? date;
  final DateTime? time;
}
