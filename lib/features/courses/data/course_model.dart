// lib/features/courses/data/course_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// A YouTube playlist imported as a course
class CourseModel {
  final String id;
  final String playlistId;
  final String title;
  final String description;
  final String thumbnailUrl;
  final String channelName;
  final int videoCount;
  final int completedCount;
  final int totalDurationSeconds;
  final String category;
  final DateTime addedAt;
  final DateTime? lastWatchedAt;
  final double progress; // 0.0 to 1.0
  final List<VideoItemModel> videos;

  const CourseModel({
    required this.id,
    required this.playlistId,
    required this.title,
    this.description = '',
    required this.thumbnailUrl,
    required this.channelName,
    required this.videoCount,
    this.completedCount = 0,
    this.totalDurationSeconds = 0,
    this.category = 'General',
    required this.addedAt,
    this.lastWatchedAt,
    this.progress = 0.0,
    this.videos = const [],
  });

  factory CourseModel.fromMap(Map<String, dynamic> map, String docId) {
    return CourseModel(
      id: docId,
      playlistId: map['playlistId'] as String? ?? '',
      title: map['title'] as String? ?? 'Untitled Course',
      description: map['description'] as String? ?? '',
      thumbnailUrl: map['thumbnailUrl'] as String? ?? '',
      channelName: map['channelName'] as String? ?? '',
      videoCount: (map['videoCount'] as num?)?.toInt() ?? 0,
      completedCount: (map['completedCount'] as num?)?.toInt() ?? 0,
      totalDurationSeconds: (map['totalDurationSeconds'] as num?)?.toInt() ?? 0,
      category: map['category'] as String? ?? 'General',
      addedAt: (map['addedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastWatchedAt: (map['lastWatchedAt'] as Timestamp?)?.toDate(),
      progress: (map['progress'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() => {
        'playlistId': playlistId,
        'title': title,
        'description': description,
        'thumbnailUrl': thumbnailUrl,
        'channelName': channelName,
        'videoCount': videoCount,
        'completedCount': completedCount,
        'totalDurationSeconds': totalDurationSeconds,
        'category': category,
        'addedAt': Timestamp.fromDate(addedAt),
        'lastWatchedAt':
            lastWatchedAt != null ? Timestamp.fromDate(lastWatchedAt!) : null,
        'progress': progress,
      };

  CourseModel copyWith({
    int? completedCount,
    DateTime? lastWatchedAt,
    double? progress,
    List<VideoItemModel>? videos,
  }) {
    return CourseModel(
      id: id,
      playlistId: playlistId,
      title: title,
      description: description,
      thumbnailUrl: thumbnailUrl,
      channelName: channelName,
      videoCount: videoCount,
      completedCount: completedCount ?? this.completedCount,
      totalDurationSeconds: totalDurationSeconds,
      category: category,
      addedAt: addedAt,
      lastWatchedAt: lastWatchedAt ?? this.lastWatchedAt,
      progress: progress ?? this.progress,
      videos: videos ?? this.videos,
    );
  }

  String get formattedDuration {
    final h = totalDurationSeconds ~/ 3600;
    final m = (totalDurationSeconds % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  int get progressPercent => (progress * 100).round();
}

/// A single video inside a playlist/course
class VideoItemModel {
  final String videoId;
  final String title;
  final String thumbnailUrl;
  final int durationSeconds;
  final int position; // index in playlist
  bool isCompleted;
  int lastTimestamp; // seconds watched so far
  int watchedSeconds;
  DateTime? watchedAt;

  VideoItemModel({
    required this.videoId,
    required this.title,
    required this.thumbnailUrl,
    required this.durationSeconds,
    required this.position,
    this.isCompleted = false,
    this.lastTimestamp = 0,
    this.watchedSeconds = 0,
    this.watchedAt,
  });

  factory VideoItemModel.fromMap(Map<String, dynamic> map) {
    return VideoItemModel(
      videoId: map['videoId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      thumbnailUrl: map['thumbnailUrl'] as String? ?? '',
      durationSeconds: (map['durationSeconds'] as num?)?.toInt() ?? 0,
      position: (map['position'] as num?)?.toInt() ?? 0,
      isCompleted: map['isCompleted'] as bool? ?? false,
      lastTimestamp: (map['lastTimestamp'] as num?)?.toInt() ?? 0,
      watchedSeconds: (map['watchedSeconds'] as num?)?.toInt() ?? 0,
      watchedAt: (map['watchedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'videoId': videoId,
        'title': title,
        'thumbnailUrl': thumbnailUrl,
        'durationSeconds': durationSeconds,
        'position': position,
        'isCompleted': isCompleted,
        'lastTimestamp': lastTimestamp,
        'watchedSeconds': watchedSeconds,
        'watchedAt': watchedAt != null ? Timestamp.fromDate(watchedAt!) : null,
      };

  String get formattedDuration {
    final h = durationSeconds ~/ 3600;
    final m = (durationSeconds % 3600) ~/ 60;
    final s = durationSeconds % 60;
    if (h > 0) return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String get youtubeUrl => 'https://www.youtube.com/watch?v=$videoId';
}
