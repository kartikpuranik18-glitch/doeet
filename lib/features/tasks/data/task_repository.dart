import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import 'task_model.dart';

class TaskRepository {
  TaskRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> _tasks(String uid) =>
      _firestore.collection('users').doc(uid).collection('tasks');

  Stream<List<TaskModel>> watchTasks(String uid) {
    return _tasks(uid).orderBy('dueAt').snapshots().map((snapshot) {
      final tasks = snapshot.docs
          .map((doc) => TaskModel.fromMap(doc.data(), doc.id))
          .toList();
      tasks.sort((a, b) {
        if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
        final dueOrder = a.dueAt.compareTo(b.dueAt);
        return dueOrder != 0 ? dueOrder : b.createdAt.compareTo(a.createdAt);
      });
      return tasks;
    });
  }

  Future<void> addTask(String uid, String title, {DateTime? dueAt}) async {
    final now = DateTime.now();
    final date = dueAt ?? now;
    final dueDate = DateTime(date.year, date.month, date.day);
    await _tasks(uid).doc(_uuid.v4()).set({
      'title': title.trim(),
      'dueAt': Timestamp.fromDate(dueDate),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'completedAt': null,
      'isCompleted': false,
    });
  }

  Future<void> setCompleted(
    String uid,
    TaskModel task,
    bool isCompleted,
  ) async {
    await _tasks(uid).doc(task.id).update({
      'isCompleted': isCompleted,
      'completedAt': isCompleted ? FieldValue.serverTimestamp() : null,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> reschedule(String uid, TaskModel task, DateTime dueAt) async {
    final date = DateTime(dueAt.year, dueAt.month, dueAt.day);
    await _tasks(uid).doc(task.id).update({
      'dueAt': Timestamp.fromDate(date),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> rename(String uid, TaskModel task, String title) async {
    await _tasks(uid).doc(task.id).update({
      'title': title.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteTask(String uid, String taskId) async {
    await _tasks(uid).doc(taskId).delete();
  }
}
