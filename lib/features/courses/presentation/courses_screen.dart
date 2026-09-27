// lib/features/courses/presentation/courses_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'courses_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/shimmer_loader.dart';
import '../../../core/widgets/doeet_error_widget.dart';
import 'widgets/course_card.dart';

class CoursesScreen extends ConsumerWidget {
  const CoursesScreen({super.key});

  static const _categories = [
    'All',
    'Programming',
    'Mathematics',
    'Science',
    'Design',
    'Business',
    'Languages',
    'Music',
    'Health',
    'AI & ML',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coursesAsync = ref.watch(filteredCoursesProvider);
    final selected = ref.watch(selectedCategoryProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: MediaQuery.sizeOf(context).width < 900
          ? AppBar(
              title: const Text('My Courses'),
              actions: [
                IconButton(
                  onPressed: () => context.go('/import-course'),
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.add_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            )
          : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Category filter chips ────────────────────
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.screenPadding),
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final cat = _categories[i];
                final isSelected =
                    (selected == null && cat == 'All') || selected == cat;
                return GestureDetector(
                  onTap: () => ref
                      .read(selectedCategoryProvider.notifier)
                      .state = cat == 'All' ? null : cat,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color:
                          isSelected ? AppColors.primary : AppColors.bgElevated,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color:
                            isSelected ? AppColors.primary : AppColors.border,
                      ),
                    ),
                    child: Text(
                      cat,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color:
                            isSelected ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // ── Course list ──────────────────────────────
          Expanded(
            child: coursesAsync.when(
              data: (courses) {
                if (courses.isEmpty) {
                  return DoeetEmptyWidget(
                    icon: Icons.video_library_outlined,
                    title: 'No courses yet',
                    subtitle: 'Import a YouTube playlist to start learning',
                    actionLabel: '+ Import Course',
                    action: () => context.go('/import-course'),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.screenPadding, vertical: 4),
                  itemCount: courses.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    return CourseCard(course: courses[i])
                        .animate(delay: Duration(milliseconds: i * 60))
                        .fadeIn()
                        .slideY(begin: 0.1, end: 0);
                  },
                );
              },
              loading: () => ListView.separated(
                padding: const EdgeInsets.all(AppSizes.screenPadding),
                itemCount: 4,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, __) => const ShimmerCard(height: 130),
              ),
              error: (e, _) => DoeetErrorWidget(
                message: e.toString(),
                onRetry: () => ref.invalidate(coursesProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
