import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../notes/data/note_model.dart';
import '../../notes/data/notes_repository.dart';
import '../../tasks/data/task_model.dart';
import '../../tasks/data/task_repository.dart';
import '../domain/voice_intent.dart';

class VoiceActionExecutor {
  VoiceActionExecutor(
      {FirebaseFirestore? firestore,
      TaskRepository? tasks,
      NotesRepository? notes})
      : _db = firestore ?? FirebaseFirestore.instance,
        _tasks = tasks ?? TaskRepository(firestore: firestore),
        _notes = notes ?? NotesRepository(db: firestore);

  final FirebaseFirestore _db;
  final TaskRepository _tasks;
  final NotesRepository _notes;

  Future<VoiceExecutionResult> execute(String uid, VoiceIntent action) async {
    if (uid.isEmpty)
      throw const VoiceCommandException('Sign in to use voice commands.');
    if (action.route != null)
      return VoiceExecutionResult(
          message: 'Opening ${action.route!.replaceFirst('/', '')}.',
          route: action.route);
    final user = _db.collection('users').doc(uid);
    switch (action.type) {
      case VoiceIntentType.createTask:
        final title = _required(action.title, 'Tell me what the task is.');
        await _tasks.addTask(uid, title, dueAt: _scheduledAt(action));
        return VoiceExecutionResult(
            message: _dated('Done. I added “$title”', _scheduledAt(action)));
      case VoiceIntentType.createEvent:
      case VoiceIntentType.createReminder:
        final title = _required(action.title, 'Tell me what to schedule.');
        await _tasks.addTask(uid, title, dueAt: _scheduledAt(action));
        return VoiceExecutionResult(
            message:
                _dated('Done. I scheduled “$title”', _scheduledAt(action)));
      case VoiceIntentType.completeTask:
        final task = await _findTask(uid, action.title!);
        await _tasks.setCompleted(uid, task, true);
        return VoiceExecutionResult(
            message: 'Done. I marked “${task.title}” complete.');
      case VoiceIntentType.deleteTask:
        final task = await _findTask(uid, action.title!);
        await _tasks.deleteTask(uid, task.id);
        return VoiceExecutionResult(message: 'Deleted “${task.title}”.');
      case VoiceIntentType.listTasks:
        final snapshot = await user.collection('tasks').orderBy('dueAt').get();
        final tasks = snapshot.docs
            .map((doc) => TaskModel.fromMap(doc.data(), doc.id))
            .where((task) => !task.isCompleted)
            .take(8)
            .toList();
        return VoiceExecutionResult(
            message: tasks.isEmpty
                ? 'You have no open tasks.'
                : 'You have ${tasks.length} open tasks: ${tasks.map((task) => task.title).join(', ')}.');
      case VoiceIntentType.createGoal:
        final title = _required(action.title, 'Tell me the goal name.');
        await user.collection('goals').add({
          'title': title,
          'target': 10,
          'progress': 0,
          'category': 'General',
          'status': 'Active',
          'createdAt': FieldValue.serverTimestamp()
        });
        return VoiceExecutionResult(
            message: 'Done. I created the goal “$title”.');
      case VoiceIntentType.updateGoal:
        final goal =
            await _findByTitle(user.collection('goals'), action.title!);
        final target = action.target!;
        final goalTarget = (goal.data()['target'] as num?)?.toInt() ?? 100;
        await goal.reference
            .update({'progress': (goalTarget * target / 100).round()});
        return VoiceExecutionResult(
            message: 'Updated “${action.title}” to $target percent.');
      case VoiceIntentType.completeGoal:
        final goal =
            await _findByTitle(user.collection('goals'), action.title!);
        final data = goal.data();
        await goal.reference
            .update({'progress': data['target'] ?? 1, 'status': 'Completed'});
        return VoiceExecutionResult(
            message: 'Marked goal “${action.title}” completed.');
      case VoiceIntentType.listGoals:
        final docs = await user
            .collection('goals')
            .where('status', isEqualTo: 'Active')
            .get();
        return VoiceExecutionResult(
            message: docs.docs.isEmpty
                ? 'You have no active goals.'
                : 'Your active goals are: ${docs.docs.map((doc) => doc.data()['title']).join(', ')}.');
      case VoiceIntentType.createHabit:
        final title = _required(action.title, 'Tell me the habit name.');
        await user.collection('habits').add({
          'title': title,
          'frequency': action.recurrence ?? 'daily',
          'completedDates': <String>[],
          'createdAt': FieldValue.serverTimestamp()
        });
        return VoiceExecutionResult(
            message: 'Done. I created the habit “$title”.');
      case VoiceIntentType.completeHabit:
        final habit =
            await _findByTitle(user.collection('habits'), action.title!);
        final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
        await habit.reference.update({
          'completedDates': FieldValue.arrayUnion([today])
        });
        return VoiceExecutionResult(
            message: 'Marked habit “${action.title}” complete for today.');
      case VoiceIntentType.listHabits:
        final docs = await user.collection('habits').get();
        return VoiceExecutionResult(
            message: docs.docs.isEmpty
                ? 'You have no habits.'
                : 'Your habits are: ${docs.docs.map((doc) => doc.data()['title']).join(', ')}.');
      case VoiceIntentType.createNote:
        final content = _required(action.content, 'Tell me what to write.');
        await _notes.saveNote(uid, _note(action.title ?? content, content));
        return VoiceExecutionResult(
            message: 'Saved your note “${action.title ?? content}”.');
      case VoiceIntentType.listNotes:
        final docs = await user
            .collection('notes')
            .orderBy('updatedAt', descending: true)
            .limit(8)
            .get();
        return VoiceExecutionResult(
            message: docs.docs.isEmpty
                ? 'You have no notes.'
                : 'Your latest notes are: ${docs.docs.map((doc) => doc.data()['title']).join(', ')}.');
      case VoiceIntentType.searchNotes:
        final docs = await user.collection('notes').get();
        final query = (action.title ?? '').toLowerCase();
        final matches = docs.docs.where((doc) =>
            '${doc.data()['title']} ${doc.data()['content']}'
                .toLowerCase()
                .contains(query));
        return VoiceExecutionResult(
            message: matches.isEmpty
                ? 'I found no notes matching $query.'
                : 'I found: ${matches.map((doc) => doc.data()['title']).join(', ')}.');
      case VoiceIntentType.listEvents:
        final tasks = await user.collection('tasks').orderBy('dueAt').get();
        final date = action.date;
        final matching = tasks.docs.where((doc) {
          if (date == null) return true;
          final due = (doc.data()['dueAt'] as Timestamp?)?.toDate();
          return due != null &&
              due.year == date.year &&
              due.month == date.month &&
              due.day == date.day;
        });
        return VoiceExecutionResult(
            message: matching.isEmpty
                ? 'Nothing is scheduled for that day.'
                : 'Scheduled items: ${matching.map((doc) => doc.data()['title']).join(', ')}.');
      default:
        throw const VoiceCommandException(
            'That voice action is not available yet.');
    }
  }

  Future<TaskModel> _findTask(String uid, String title) async {
    final docs =
        await _db.collection('users').doc(uid).collection('tasks').get();
    final matches = docs.docs
        .map((doc) => TaskModel.fromMap(doc.data(), doc.id))
        .where((task) => task.title.toLowerCase().contains(title.toLowerCase()))
        .toList();
    if (matches.length != 1)
      throw const VoiceCommandException(
          'I could not find exactly one matching task. Try its full name.');
    return matches.single;
  }

  Future<QueryDocumentSnapshot<Map<String, dynamic>>> _findByTitle(
      CollectionReference<Map<String, dynamic>> collection,
      String title) async {
    final docs = await collection.get();
    final matches = docs.docs
        .where((doc) => (doc.data()['title'] as String? ?? '')
            .toLowerCase()
            .contains(title.toLowerCase()))
        .toList();
    if (matches.length != 1)
      throw const VoiceCommandException(
          'I could not find exactly one matching item. Try its full name.');
    return matches.single;
  }

  String _required(String? value, String message) {
    if (value == null || value.trim().isEmpty)
      throw VoiceCommandException(message);
    return value.trim();
  }

  String _dated(String message, DateTime? date) => date == null
      ? '$message for today.'
      : '$message for ${DateFormat('EEEE, MMMM d').format(date)}.';

  DateTime? _scheduledAt(VoiceIntent action) {
    final date = action.date ?? action.time;
    final time = action.time;
    if (date == null || time == null) return date;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  NoteModel _note(String title, String content) => NoteModel(
        id: '',
        courseId: 'general',
        title: title,
        content: content,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
}
