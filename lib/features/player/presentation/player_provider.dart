// lib/features/player/presentation/player_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../courses/data/course_repository.dart';
import '../../courses/presentation/courses_provider.dart';

class PlayerState {
  final bool isPlaying;
  final double playbackSpeed;
  final bool focusMode;
  final int currentTimestamp; // seconds
  final bool isCompleted;

  const PlayerState({
    this.isPlaying = false,
    this.playbackSpeed = 1.0,
    this.focusMode = false,
    this.currentTimestamp = 0,
    this.isCompleted = false,
  });

  PlayerState copyWith({
    bool? isPlaying,
    double? playbackSpeed,
    bool? focusMode,
    int? currentTimestamp,
    bool? isCompleted,
  }) =>
      PlayerState(
        isPlaying: isPlaying ?? this.isPlaying,
        playbackSpeed: playbackSpeed ?? this.playbackSpeed,
        focusMode: focusMode ?? this.focusMode,
        currentTimestamp: currentTimestamp ?? this.currentTimestamp,
        isCompleted: isCompleted ?? this.isCompleted,
      );
}

class PlayerNotifier extends StateNotifier<PlayerState> {
  PlayerNotifier(this._repo, this._uid) : super(const PlayerState());

  final CourseRepository _repo;
  final String _uid;

  void setPlaying(bool v) => state = state.copyWith(isPlaying: v);
  void setSpeed(double s) => state = state.copyWith(playbackSpeed: s);
  void toggleFocusMode() =>
      state = state.copyWith(focusMode: !state.focusMode);
  void updateTimestamp(int seconds) =>
      state = state.copyWith(currentTimestamp: seconds);

  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    state = state.copyWith(
      playbackSpeed: prefs.getDouble('defaultPlaybackSpeed') ?? 1.0,
    );
  }

  Future<void> saveProgress({
    required String courseId,
    required String videoId,
    required int timestamp,
    required int watchedSeconds,
    bool completed = false,
  }) async {
    if (_uid.isEmpty) return;
    await _repo.updateVideoProgress(
      _uid,
      courseId,
      videoId,
      lastTimestamp: timestamp,
      watchedSeconds: watchedSeconds,
      isCompleted: completed ? true : null,
    );
    if (completed) {
      state = state.copyWith(isCompleted: true);
      // Award XP for completion
      await _repo.addDailyStats(
        _uid,
        minutesWatched: (watchedSeconds / 60).ceil(),
        videosCompleted: 1,
        xpEarned: 50,
      );
    }
  }
}

final playerNotifierProvider =
    StateNotifierProvider.autoDispose<PlayerNotifier, PlayerState>((ref) {
  final uid = ref.watch(firebaseAuthStateProvider).value?.uid ?? '';
  final notifier = PlayerNotifier(ref.watch(courseRepositoryProvider), uid);
  notifier.loadPreferences();
  return notifier;
});
