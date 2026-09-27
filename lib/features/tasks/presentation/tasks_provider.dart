import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_provider.dart';
import '../data/task_model.dart';
import '../data/task_repository.dart';

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository();
});

final tasksProvider = StreamProvider<List<TaskModel>>((ref) {
  final uid = ref.watch(firebaseAuthStateProvider).value?.uid;
  if (uid == null) return Stream.value(const []);
  return ref.watch(taskRepositoryProvider).watchTasks(uid);
});

class TaskActionsNotifier extends StateNotifier<AsyncValue<void>> {
  TaskActionsNotifier(this._repository, this._uid)
      : super(const AsyncValue.data(null));

  final TaskRepository _repository;
  final String _uid;

  Future<void> add(String title, {DateTime? dueAt}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repository.addTask(_uid, title, dueAt: dueAt),
    );
  }

  Future<void> setCompleted(TaskModel task, bool completed) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repository.setCompleted(_uid, task, completed),
    );
  }

  Future<void> reschedule(TaskModel task, DateTime dueAt) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repository.reschedule(_uid, task, dueAt),
    );
  }

  Future<void> rename(TaskModel task, String title) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repository.rename(_uid, task, title),
    );
  }

  Future<void> delete(String taskId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.deleteTask(_uid, taskId));
  }
}

final taskActionsProvider =
    StateNotifierProvider<TaskActionsNotifier, AsyncValue<void>>((ref) {
  final uid = ref.watch(firebaseAuthStateProvider).value?.uid ?? '';
  return TaskActionsNotifier(ref.watch(taskRepositoryProvider), uid);
});
