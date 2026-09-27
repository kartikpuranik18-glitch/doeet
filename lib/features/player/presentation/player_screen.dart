// lib/features/player/presentation/player_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart'
    hide PlayerState;
import 'player_provider.dart';
import '../../courses/presentation/courses_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/glass_card.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({super.key, required this.courseId, required this.videoId});
  final String courseId;
  final String videoId;

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  late YoutubePlayerController _yt;
  bool _showControls = true;
  DateTime _watchStart = DateTime.now();

  @override
  void initState() {
    super.initState();
    _yt = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: true,
        loop: false,
      ),
    )..addListener(_onPlayerStateChange);

    // Lock to landscape when playing
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
    ]);
  }

  void _onPlayerStateChange() {
    if (!mounted) return;
    final notifier = ref.read(playerNotifierProvider.notifier);
    notifier.setPlaying(_yt.value.isPlaying);
    notifier.updateTimestamp(_yt.value.position.inSeconds);

    // Auto-mark complete when >90% watched
    final dur = _yt.value.metaData.duration.inSeconds;
    final pos = _yt.value.position.inSeconds;
    if (dur > 0 && pos > 0 && pos / dur > 0.9) {
      final playerState = ref.read(playerNotifierProvider);
      if (!playerState.isCompleted) {
        _saveProgress(completed: true);
      }
    }
  }

  Future<void> _saveProgress({bool completed = false}) async {
    final watchedSecs = DateTime.now().difference(_watchStart).inSeconds;
    await ref.read(playerNotifierProvider.notifier).saveProgress(
          courseId: widget.courseId,
          videoId: widget.videoId,
          timestamp: _yt.value.position.inSeconds,
          watchedSeconds: watchedSecs,
          completed: completed,
        );
  }

  @override
  void dispose() {
    _saveProgress();
    _yt.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerNotifierProvider);
    final courseAsync = ref.watch(courseDetailProvider(widget.courseId));

    return YoutubePlayerBuilder(
      onExitFullScreen: () {
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      },
      player: YoutubePlayer(
        controller: _yt,
        showVideoProgressIndicator: true,
        progressIndicatorColor: AppColors.primary,
        progressColors: const ProgressBarColors(
          playedColor: AppColors.primary,
          handleColor: AppColors.primaryLight,
          bufferedColor: Color(0x44FFFFFF),
          backgroundColor: Color(0x22FFFFFF),
        ),
        onReady: () {
          _yt.setPlaybackRate(playerState.playbackSpeed);
          _watchStart = DateTime.now();
        },
      ),
      builder: (context, player) {
        return Scaffold(
          backgroundColor: AppColors.bg,
          body: GestureDetector(
            onTap: () =>
                setState(() => _showControls = !_showControls),
            child: Column(
              children: [
                // ── Video Player ────────────────────────
                player,

                // ── Focus mode overlay toggle ───────────
                if (!playerState.focusMode)
                  Expanded(
                    child: _VideoInfo(
                      videoId: widget.videoId,
                      courseId: widget.courseId,
                      courseAsync: courseAsync,
                      playerState: playerState,
                      controller: _yt,
                      onSpeedChange: (s) {
                        ref
                            .read(playerNotifierProvider.notifier)
                            .setSpeed(s);
                        _yt.setPlaybackRate(s);
                      },
                      onFocusToggle: () => ref
                          .read(playerNotifierProvider.notifier)
                          .toggleFocusMode(),
                      onNotes: () => context.push(
                          '/notes/editor',
                          extra: <String, dynamic>{
                            'courseId': widget.courseId,
                            'videoId': widget.videoId,
                            'timestamp': _yt.value.position.inSeconds,
                          }),
                    ),
                  )
                else
                  // Focus mode — minimal UI
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🎯 Focus Mode',
                              style: TextStyle(fontFamily: 'Inter', fontSize: 18,
                                  fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                          const SizedBox(height: 8),
                          const Text('Distractions are hidden',
                              style: TextStyle(color: AppColors.textSecondary,
                                  fontFamily: 'Inter', fontSize: 13)),
                          const SizedBox(height: 24),
                          OutlinedButton.icon(
                            onPressed: () => ref
                                .read(playerNotifierProvider.notifier)
                                .toggleFocusMode(),
                            icon: const Icon(Icons.visibility_rounded),
                            label: const Text('Exit Focus Mode'),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _VideoInfo extends StatelessWidget {
  const _VideoInfo({
    required this.videoId,
    required this.courseId,
    required this.courseAsync,
    required this.playerState,
    required this.controller,
    required this.onSpeedChange,
    required this.onFocusToggle,
    required this.onNotes,
  });

  final String videoId;
  final String courseId;
  final AsyncValue courseAsync;
  final PlayerState playerState;
  final YoutubePlayerController controller;
  final ValueChanged<double> onSpeedChange;
  final VoidCallback onFocusToggle;
  final VoidCallback onNotes;

  @override
  Widget build(BuildContext context) {
    final video = courseAsync.whenData((c) =>
        c?.videos.firstWhere((v) => v.videoId == videoId,
            orElse: () => c!.videos.first)).value;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            video?.title ?? 'Loading...',
            style: const TextStyle(fontFamily: 'Inter', fontSize: 18,
                fontWeight: FontWeight.w700, color: AppColors.textPrimary,
                letterSpacing: -0.3),
          ),
          const SizedBox(height: 16),

          // Controls row
          Row(
            children: [
              // Speed
              GestureDetector(
                onTap: () => _showSpeedSheet(context),
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.speed_rounded, color: AppColors.primary, size: 16),
                      const SizedBox(width: 6),
                      Text('${playerState.playbackSpeed}x',
                          style: const TextStyle(fontFamily: 'Inter', fontSize: 13,
                              fontWeight: FontWeight.w700, color: AppColors.primary)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Focus mode
              GestureDetector(
                onTap: onFocusToggle,
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(playerState.focusMode
                          ? Icons.visibility_off_rounded
                          : Icons.center_focus_strong_rounded,
                          color: AppColors.secondary, size: 16),
                      const SizedBox(width: 6),
                      const Text('Focus',
                          style: TextStyle(fontFamily: 'Inter', fontSize: 13,
                              fontWeight: FontWeight.w600, color: AppColors.secondary)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Note
              GestureDetector(
                onTap: onNotes,
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.sticky_note_2_outlined, color: AppColors.xpGold, size: 16),
                      const SizedBox(width: 6),
                      const Text('Note',
                          style: TextStyle(fontFamily: 'Inter', fontSize: 13,
                              fontWeight: FontWeight.w600, color: AppColors.xpGold)),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              // Completion badge
              if (playerState.isCompleted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: AppColors.successGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_rounded, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text('Completed!',
                          style: TextStyle(fontFamily: 'Inter', fontSize: 12,
                              fontWeight: FontWeight.w700, color: Colors.white)),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 20),

          // Up next
          if (courseAsync.value != null) ...[
            const Text('Up Next',
                style: TextStyle(fontFamily: 'Inter', fontSize: 16,
                    fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 10),
            ...courseAsync.value!.videos
                .where((v) => !v.isCompleted && v.videoId != videoId)
                .take(3)
                .map((v) => GestureDetector(
                      onTap: () => context.go('/player/$courseId/${v.videoId}'),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.bgCard,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: v.thumbnailUrl.isNotEmpty
                                  ? Image.network(v.thumbnailUrl, width: 60, height: 40, fit: BoxFit.cover)
                                  : Container(width: 60, height: 40, color: AppColors.bgElevated,
                                      child: const Icon(Icons.play_arrow_rounded,
                                          color: AppColors.primary)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(v.title,
                                  maxLines: 2, overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontFamily: 'Inter', fontSize: 12,
                                      fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                            ),
                            const Icon(Icons.play_arrow_rounded, color: AppColors.primary, size: 18),
                          ],
                        ),
                      ),
                    )),
          ],
        ],
      ),
    );
  }

  void _showSpeedSheet(BuildContext context) {
    const speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 40, height: 4,
                decoration: BoxDecoration(color: AppColors.border,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            const Text('Playback Speed',
                style: TextStyle(fontFamily: 'Inter', fontSize: 18,
                    fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10, runSpacing: 10,
              children: speeds.map((s) {
                final isCurrent = playerState.playbackSpeed == s;
                return GestureDetector(
                  onTap: () { onSpeedChange(s); Navigator.pop(ctx); },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: isCurrent ? AppColors.primary : AppColors.bgElevated,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: isCurrent ? AppColors.primary : AppColors.border),
                    ),
                    child: Text('${s}x',
                        style: TextStyle(fontFamily: 'Inter', fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isCurrent ? Colors.white : AppColors.textSecondary)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
