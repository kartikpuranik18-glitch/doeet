// lib/features/courses/data/course_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'course_model.dart';

/// Firestore CRUD for user courses and their videos
class CourseRepository {
  final FirebaseFirestore _db;

  CourseRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  // ── Collection refs ───────────────────────────────
  CollectionReference<Map<String, dynamic>> _coursesCol(String uid) =>
      _db.collection('users').doc(uid).collection('courses');

  CollectionReference<Map<String, dynamic>> _videosCol(
          String uid, String courseId) =>
      _coursesCol(uid).doc(courseId).collection('videos');

  // ── Stream all courses ────────────────────────────
  Stream<List<CourseModel>> watchCourses(String uid) {
    return _coursesCol(uid)
        .orderBy('lastWatchedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => CourseModel.fromMap(d.data(), d.id))
            .toList());
  }

  // ── Fetch one course ──────────────────────────────
  Future<CourseModel?> fetchCourse(String uid, String courseId) async {
    final doc = await _coursesCol(uid).doc(courseId).get();
    if (!doc.exists) return null;
    final course = CourseModel.fromMap(doc.data()!, doc.id);
    final videos = await fetchVideos(uid, courseId);
    return course.copyWith(videos: videos);
  }

  // ── Save a new course (import) ────────────────────
  Future<String> saveCourse(String uid, CourseModel course) async {
    final docRef = _coursesCol(uid).doc(course.playlistId);
    await docRef.set(course.toMap());

    // Save each video as a subcollection doc
    final batch = _db.batch();
    for (final video in course.videos) {
      final vRef = _videosCol(uid, course.playlistId).doc(video.videoId);
      batch.set(vRef, video.toMap());
    }
    await batch.commit();
    return course.playlistId;
  }

  // ── Delete course ─────────────────────────────────
  Future<void> deleteCourse(String uid, String courseId) async {
    // Delete all videos first
    final vDocs = await _videosCol(uid, courseId).get();
    final batch = _db.batch();
    for (final doc in vDocs.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_coursesCol(uid).doc(courseId));
    await batch.commit();
  }

  // ── Fetch videos ──────────────────────────────────
  Future<List<VideoItemModel>> fetchVideos(
      String uid, String courseId) async {
    final snap = await _videosCol(uid, courseId)
        .orderBy('position')
        .get();
    return snap.docs.map((d) => VideoItemModel.fromMap(d.data())).toList();
  }

  // ── Update video progress ─────────────────────────
  Future<void> updateVideoProgress(
    String uid,
    String courseId,
    String videoId, {
    required int lastTimestamp,
    required int watchedSeconds,
    bool? isCompleted,
  }) async {
    final updates = <String, dynamic>{
      'lastTimestamp': lastTimestamp,
      'watchedSeconds': watchedSeconds,
      'watchedAt': FieldValue.serverTimestamp(),
    };
    if (isCompleted != null) updates['isCompleted'] = isCompleted;

    await _videosCol(uid, courseId).doc(videoId).update(updates);

    // Recalculate course progress
    if (isCompleted == true) {
      await _recalculateCourseProgress(uid, courseId);
    }

    // Update last watched on course
    await _coursesCol(uid).doc(courseId).update({
      'lastWatchedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _recalculateCourseProgress(
      String uid, String courseId) async {
    final videos = await fetchVideos(uid, courseId);
    final completed = videos.where((v) => v.isCompleted).length;
    final total = videos.length;
    final progress = total > 0 ? completed / total : 0.0;

    await _coursesCol(uid).doc(courseId).update({
      'completedCount': completed,
      'progress': progress,
    });
  }

  // ── Update daily stats ────────────────────────────
  Future<void> addDailyStats(
    String uid, {
    required int minutesWatched,
    required int videosCompleted,
    required int xpEarned,
  }) async {
    final today = DateTime.now();
    final dateKey =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final ref = _db
        .collection('users')
        .doc(uid)
        .collection('dailyStats')
        .doc(dateKey);

    await ref.set({
      'minutesWatched': FieldValue.increment(minutesWatched),
      'videosCompleted': FieldValue.increment(videosCompleted),
      'xpEarned': FieldValue.increment(xpEarned),
      'date': dateKey,
    }, SetOptions(merge: true));

    // Update total on user doc
    await _db.collection('users').doc(uid).update({
      'totalMinutesWatched': FieldValue.increment(minutesWatched),
    });
  }

  // ── Fetch daily stats (last N days) ───────────────
  Future<List<Map<String, dynamic>>> fetchDailyStats(
      String uid, int days) async {
    final snap = await _db
        .collection('users')
        .doc(uid)
        .collection('dailyStats')
        .orderBy('date', descending: true)
        .limit(days)
        .get();
    return snap.docs.map((d) => d.data()).toList();
  }
}
