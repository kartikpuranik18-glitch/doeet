import 'package:doeet/features/voice/data/voice_parser.dart';
import 'package:doeet/features/voice/domain/voice_intent.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = VoiceIntentParser();
  final now = DateTime(2026, 9, 27, 12);

  test('parses a natural task with a relative date', () {
    final action =
        parser.parse('Add a task to study Python tomorrow', now: now);
    expect(action.type, VoiceIntentType.createTask);
    expect(action.title, 'study Python');
    expect(action.date, DateTime(2026, 9, 28));
  });

  test('parses dedicated navigation routes', () {
    final action = parser.parse('open calendar', now: now);
    expect(action.route, '/calendar');
  });

  test('parses weekday and clock time in the user local timezone', () {
    final action = parser.parse(
      'Create a task to submit assignment on Monday at 10 AM',
      now: now,
    );
    expect(action.type, VoiceIntentType.createTask);
    expect(action.title, 'submit assignment');
    expect(action.date, DateTime(2026, 9, 28));
    expect(action.time?.hour, 10);
  });

  test('parses notes and habits as typed intents', () {
    expect(parser.parse('Take a note: buy better microphones').type,
        VoiceIntentType.createNote);
    expect(parser.parse('Create a habit of reading every day').type,
        VoiceIntentType.createHabit);
  });
}
