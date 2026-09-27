// lib/features/courses/presentation/courses_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/course_model.dart';
import '../data/course_repository.dart';
import '../data/youtube_service.dart';
import '../../auth/presentation/auth_provider.dart';

// ── Repository Providers ──────────────────────────────
final courseRepositoryProvider = Provider<CourseRepository>((ref) {
  return CourseRepository();
});

final youTubeServiceProvider = Provider<YouTubeService>((ref) {
  return YouTubeService();
});

// ── Courses Stream ────────────────────────────────────
final coursesProvider = StreamProvider<List<CourseModel>>((ref) {
  final authState = ref.watch(firebaseAuthStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value([]);
      return ref.watch(courseRepositoryProvider).watchCourses(user.uid);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

/// Alias for coursesProvider — used by home_provider and other screens
final coursesStreamProvider = coursesProvider;

// ── Single Course ─────────────────────────────────────
final courseDetailProvider =
    FutureProvider.family<CourseModel?, String>((ref, courseId) async {
  final user = ref.watch(firebaseAuthStateProvider).value;
  if (user == null) return null;
  return ref.watch(courseRepositoryProvider).fetchCourse(user.uid, courseId);
});

// ── Import State ──────────────────────────────────────
class ImportNotifier extends StateNotifier<AsyncValue<CourseModel?>> {
  ImportNotifier(this._ytService, this._repo, this._uid)
      : super(const AsyncValue.data(null));

  final YouTubeService _ytService;
  final CourseRepository _repo;
  final String _uid;

  CourseModel? _previewCourse;
  CourseModel? get previewCourse => _previewCourse;

  /// Step 1: Fetch preview from YouTube
  Future<void> fetchPreview(String url) async {
    if (_uid.isEmpty) {
      state = AsyncValue.error(
        StateError('Sign in before importing a course.'),
        StackTrace.current,
      );
      return;
    }
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final course = await _ytService.fetchPlaylist(url);
      _previewCourse = course;
      return course;
    });
  }

  /// Step 2: Save to Firestore
  Future<String?> saveCourse({String? category}) async {
    if (_uid.isEmpty || _previewCourse == null) return null;
    final course = CourseModel(
      id: _previewCourse!.playlistId,
      playlistId: _previewCourse!.playlistId,
      title: _previewCourse!.title,
      description: _previewCourse!.description,
      thumbnailUrl: _previewCourse!.thumbnailUrl,
      channelName: _previewCourse!.channelName,
      videoCount: _previewCourse!.videoCount,
      totalDurationSeconds: _previewCourse!.totalDurationSeconds,
      category: category ?? 'General',
      addedAt: DateTime.now(),
      videos: _previewCourse!.videos,
    );
    await _repo.saveCourse(_uid, course);
    _previewCourse = null;
    state = const AsyncValue.data(null);
    return course.id;
  }

  void reset() {
    _previewCourse = null;
    state = const AsyncValue.data(null);
  }
}

final importNotifierProvider =
    StateNotifierProvider<ImportNotifier, AsyncValue<CourseModel?>>((ref) {
  final user = ref.watch(firebaseAuthStateProvider).value;
  return ImportNotifier(
    ref.watch(youTubeServiceProvider),
    ref.watch(courseRepositoryProvider),
    user?.uid ?? '',
  );
});

// ── Category filter ───────────────────────────────────
final selectedCategoryProvider = StateProvider<String?>((ref) => null);

final filteredCoursesProvider = Provider<AsyncValue<List<CourseModel>>>((ref) {
  final courses = ref.watch(coursesProvider);
  final category = ref.watch(selectedCategoryProvider);
  return courses.whenData((list) {
    if (category == null || category == 'All') return list;
    return list.where((c) => c.category == category).toList();
  });
});
