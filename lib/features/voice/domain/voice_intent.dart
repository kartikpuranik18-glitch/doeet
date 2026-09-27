enum VoiceIntentType {
  createTask,
  completeTask,
  deleteTask,
  listTasks,
  createGoal,
  updateGoal,
  completeGoal,
  listGoals,
  createHabit,
  completeHabit,
  listHabits,
  createNote,
  updateNote,
  searchNotes,
  listNotes,
  createEvent,
  listEvents,
  createReminder,
  unknown,
}

class VoiceIntent {
  const VoiceIntent({
    required this.type,
    this.title,
    this.content,
    this.date,
    this.time,
    this.target,
    this.route,
    this.recurrence,
  });

  final VoiceIntentType type;
  final String? title;
  final String? content;
  final DateTime? date;
  final DateTime? time;
  final int? target;
  final String? route;
  final String? recurrence;

  bool get needsConfirmation =>
      type == VoiceIntentType.deleteTask || type == VoiceIntentType.updateNote;
}

class VoiceExecutionResult {
  const VoiceExecutionResult({required this.message, this.route});
  final String message;
  final String? route;
}

class VoiceCommandException implements Exception {
  const VoiceCommandException(this.message);
  final String message;
}
