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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: course.thumbnailUrl.isNotEmpty
                  ? Image.network(course.thumbnailUrl,
                      width: 86, height: 58, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _thumbPlaceholder())
                  : _thumbPlaceholder(),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(course.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(course.channelName.isEmpty ? 'YouTube playlist' : course.channelName,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(value: course.progress, minHeight: 5,
                      backgroundColor: AppColors.bgElevated,
                      valueColor: const AlwaysStoppedAnimation(AppColors.primary)),
                  )),
                  const SizedBox(width: 10),
                  Text('${course.completedCount}/${course.videoCount}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ]),
              ]),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.arrow_forward_rounded, size: 19, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _thumbPlaceholder() => Container(
        height: 58,
        width: 86,
        color: AppColors.bgElevated,
        child: const Icon(Icons.video_library_outlined, color: AppColors.primary, size: 40),
      );
}
