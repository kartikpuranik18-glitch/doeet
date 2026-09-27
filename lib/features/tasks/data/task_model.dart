import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel {
  const TaskModel({
    required this.id,
    required this.title,
    required this.dueAt,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    this.isCompleted = false,
  });

  final String id;
  final String title;
  final DateTime dueAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final bool isCompleted;

  factory TaskModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime dateValue(Object? value, {DateTime? fallback}) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return fallback ?? DateTime.now();
    }

    return TaskModel(
      id: id,
      title: map['title'] as String? ?? 'Untitled task',
      dueAt: dateValue(map['dueAt']),
      createdAt: dateValue(map['createdAt']),
      updatedAt: dateValue(map['updatedAt']),
      completedAt:
          map['completedAt'] == null ? null : dateValue(map['completedAt']),
      isCompleted: map['isCompleted'] as bool? ?? false,
    );
  }

  Map<String, Object?> toMap() => {
        'title': title,
        'dueAt': Timestamp.fromDate(dueAt),
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'completedAt':
            completedAt == null ? null : Timestamp.fromDate(completedAt!),
        'isCompleted': isCompleted,
      };

}
