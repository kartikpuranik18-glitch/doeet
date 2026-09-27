// lib/features/notes/data/note_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class NoteModel {
  final String id;
  final String courseId;
  final String? videoId;
  final String title;
  final String content;
  final int? timestamp; // video timestamp in seconds
  final DateTime createdAt;
  final DateTime updatedAt;

  const NoteModel({
    required this.id,
    required this.courseId,
    this.videoId,
    required this.title,
    required this.content,
    this.timestamp,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NoteModel.fromMap(Map<String, dynamic> map, String docId) {
    return NoteModel(
      id: docId,
      courseId: map['courseId'] as String? ?? '',
      videoId: map['videoId'] as String?,
      title: map['title'] as String? ?? 'Untitled Note',
      content: map['content'] as String? ?? '',
      timestamp: (map['timestamp'] as num?)?.toInt(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'courseId': courseId,
        'videoId': videoId,
        'title': title,
        'content': content,
        'timestamp': timestamp,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  NoteModel copyWith({String? title, String? content}) => NoteModel(
        id: id,
        courseId: courseId,
        videoId: videoId,
        title: title ?? this.title,
        content: content ?? this.content,
        timestamp: timestamp,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );

  String get formattedTimestamp {
    if (timestamp == null) return '';
    final m = timestamp! ~/ 60;
    final s = timestamp! % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
