// lib/features/courses/presentation/course_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'courses_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/shimmer_loader.dart';
import '../../../core/widgets/doeet_error_widget.dart';
import '../data/course_model.dart';

class CourseDetailScreen extends ConsumerWidget {
  const CourseDetailScreen({super.key, required this.courseId});
  final String courseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courseAsync = ref.watch(courseDetailProvider(courseId));

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: courseAsync.when(
        data: (course) {
          if (course == null) {
            return const DoeetErrorWidget(message: 'Course not found');
          }
          return _CourseDetailBody(course: course);
        },
        loading: () => const Scaffold(
          backgroundColor: AppColors.bg,
          body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
        ),
        error: (e, _) => Scaffold(
          backgroundColor: AppColors.bg,
          body: DoeetErrorWidget(message: e.toString()),
        ),
      ),
    );
  }
}

class _CourseDetailBody extends StatelessWidget {
  const _CourseDetailBody({required this.course});
  final CourseModel course;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // ── Hero App Bar ──────────────────────────────
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          backgroundColor: AppColors.bg,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => context.go('/courses'),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.note_add_outlined, color: Colors.white),
              onPressed: () => context.push('/notes/editor', extra: <String, dynamic>{'courseId': course.id}),
            ),
            IconButton(
              icon: const Icon(Icons.auto_awesome_rounded, color: Colors.white),
              onPressed: () => context.push('/flashcards', extra: <String, dynamic>{'topic': course.title, 'content': course.description}),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                course.thumbnailUrl.isNotEmpty
                    ? Image.network(course.thumbnailUrl, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(color: AppColors.bgElevated))
                    : Container(color: AppColors.bgElevated),
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, AppColors.bg],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        SliverPadding(
          padding: const EdgeInsets.all(AppSizes.screenPadding),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // ── Title & Channel ───────────────────────
              Text(course.title,
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 22,
                      fontWeight: FontWeight.w800, color: AppColors.textPrimary,
                      letterSpacing: -0.5)),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.verified_rounded, size: 14, color: AppColors.secondary),
                  const SizedBox(width: 4),
                  Text(course.channelName,
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 13,
                          color: AppColors.secondary, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 16),

              // ── Stats row ─────────────────────────────
              Row(
                children: [
                  _StatPill(Icons.play_circle_outline_rounded, '${course.videoCount} videos'),
                  const SizedBox(width: 8),
                  _StatPill(Icons.timer_outlined, course.formattedDuration),
                  const SizedBox(width: 8),
                  _StatPill(Icons.trending_up_rounded,
                      '${course.progressPercent}% done', color: AppColors.primary),
                ],
              ),
              const SizedBox(height: 16),

              // ── Progress bar ──────────────────────────
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: course.progress,
                  backgroundColor: AppColors.bgElevated,
                  valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${course.completedCount} of ${course.videoCount} videos completed',
                style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.textMuted),
              ),
              const SizedBox(height: 20),

              // ── Action Buttons ────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _ActionBtn(
                      icon: Icons.auto_awesome_rounded,
                      label: 'AI Flashcards',
                      color: AppColors.secondary,
                      onTap: () => context.push('/flashcards', extra: <String, dynamic>{'topic': course.title, 'content': course.description}),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ActionBtn(
                      icon: Icons.quiz_rounded,
                      label: 'AI Quiz',
                      color: AppColors.accent,
                      onTap: () => context.push('/quiz', extra: <String, dynamic>{'topic': course.title, 'content': course.description}),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ActionBtn(
                      icon: Icons.sticky_note_2_outlined,
                      label: 'Notes',
                      color: AppColors.xpGold,
                      onTap: () => context.go('/notes'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Video List ────────────────────────────
              const Text('Videos',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 18,
                      fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 12),

              ...course.videos.asMap().entries.map((e) {
                final i = e.key;
                final video = e.value;
                return _VideoTile(
                  video: video,
                  index: i + 1,
                  courseId: course.id,
                ).animate(delay: Duration(milliseconds: i * 40)).fadeIn();
              }),

              const SizedBox(height: 32),
            ]),
          ),
        ),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill(this.icon, this.label, {this.color = AppColors.textSecondary});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.bgElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: color)),
          ],
        ),
      );
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({required this.icon, required this.label,
      required this.color, required this.onTap});
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 5),
              Text(label,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'Inter', fontSize: 11,
                      fontWeight: FontWeight.w600, color: color)),
            ],
          ),
        ),
      );
}

class _VideoTile extends StatelessWidget {
  const _VideoTile({required this.video, required this.index, required this.courseId});
  final VideoItemModel video;
  final int index;
  final String courseId;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/player/$courseId/${video.videoId}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: video.isCompleted
              ? AppColors.bgCard.withOpacity(0.5)
              : AppColors.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: video.isCompleted ? AppColors.success.withOpacity(0.3) : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            // Index / Check
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: video.isCompleted
                    ? AppColors.success.withOpacity(0.15)
                    : AppColors.bgElevated,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: video.isCompleted
                    ? const Icon(Icons.check_rounded, color: AppColors.success, size: 16)
                    : Text('$index',
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 12,
                            fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
              ),
            ),
            const SizedBox(width: 10),
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: video.thumbnailUrl.isNotEmpty
                  ? Image.network(video.thumbnailUrl, width: 72, height: 48, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _thumbPlaceholder())
                  : _thumbPlaceholder(),
            ),
            const SizedBox(width: 10),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(video.title,
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontFamily: 'Inter', fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: video.isCompleted
                              ? AppColors.textMuted
                              : AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text(video.formattedDuration,
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 11,
                          color: AppColors.textMuted)),
                  if (video.lastTimestamp > 0 && !video.isCompleted) ...[
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: video.durationSeconds > 0
                            ? video.lastTimestamp / video.durationSeconds
                            : 0,
                        backgroundColor: AppColors.bgElevated,
                        valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                        minHeight: 2,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.play_arrow_rounded, color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _thumbPlaceholder() => Container(
        width: 72, height: 48,
        color: AppColors.bgElevated,
        child: const Icon(Icons.play_arrow_rounded, color: AppColors.primary, size: 20),
      );
}
