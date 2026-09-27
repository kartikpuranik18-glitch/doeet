// lib/features/courses/presentation/widgets/course_card.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/course_model.dart';

class CourseCard extends StatelessWidget {
  const CourseCard({super.key, required this.course});
  final CourseModel course;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/course/${course.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Thumbnail ──────────────────────────────
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: course.thumbnailUrl.isNotEmpty
                      ? Image.network(
                          course.thumbnailUrl,
                          height: 140,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _thumbPlaceholder(),
                        )
                      : _thumbPlaceholder(),
                ),
                // Progress overlay pill
                if (course.progress > 0)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.75),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${course.progressPercent}%',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                // Category chip
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.65),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      course.category,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // ── Progress bar ───────────────────────────
            ClipRRect(
              child: LinearProgressIndicator(
                value: course.progress,
                backgroundColor: AppColors.bgElevated,
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                minHeight: 3,
              ),
            ),
            // ── Info ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.play_circle_outline_rounded,
                          size: 13, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        '${course.videoCount} videos',
                        style: const TextStyle(
                          fontFamily: 'Inter', fontSize: 12, color: AppColors.textMuted),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.timer_outlined, size: 13, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        course.formattedDuration,
                        style: const TextStyle(
                          fontFamily: 'Inter', fontSize: 12, color: AppColors.textMuted),
                      ),
                      const Spacer(),
                      Text(
                        course.channelName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter', fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _thumbPlaceholder() => Container(
        height: 140,
        width: double.infinity,
        color: AppColors.bgElevated,
        child: const Icon(Icons.video_library_outlined, color: AppColors.primary, size: 40),
      );
}
