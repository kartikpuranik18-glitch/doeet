// lib/features/learning_paths/presentation/learning_paths_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/shimmer_loader.dart';
import '../../../core/widgets/doeet_error_widget.dart';
import '../../auth/presentation/auth_provider.dart';

// ── Models ───────────────────────────────────────────────────────────────────

class LearningPath {
  final String id;
  final String title;
  final String description;
  final String targetRole;
  final List<String> skills;
  final int estimatedWeeks;
  final String difficulty;
  final List<String> courseTopics;
  final String icon;
  final DateTime createdAt;

  const LearningPath({
    required this.id,
    required this.title,
    required this.description,
    required this.targetRole,
    required this.skills,
    required this.estimatedWeeks,
    required this.difficulty,
    required this.courseTopics,
    required this.icon,
    required this.createdAt,
  });

  factory LearningPath.fromMap(Map<String, dynamic> data, String docId) =>
      LearningPath(
        id: docId,
        title: data['title'] as String? ?? '',
        description: data['description'] as String? ?? '',
        targetRole: data['targetRole'] as String? ?? '',
        skills: List<String>.from(data['skills'] as List? ?? []),
        estimatedWeeks: (data['estimatedWeeks'] as num?)?.toInt() ?? 0,
        difficulty: data['difficulty'] as String? ?? 'Intermediate',
        courseTopics: List<String>.from(data['courseTopics'] as List? ?? []),
        icon: data['icon'] as String? ?? '📚',
        createdAt:
            (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
}

class EnrolledPath {
  final String pathId;
  final DateTime enrolledAt;
  final int progressPercent;
  final DateTime? targetCompletionDate;

  const EnrolledPath({
    required this.pathId,
    required this.enrolledAt,
    required this.progressPercent,
    this.targetCompletionDate,
  });

  factory EnrolledPath.fromMap(Map<String, dynamic> data) => EnrolledPath(
        pathId: data['pathId'] as String? ?? '',
        enrolledAt:
            (data['enrolledAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        progressPercent: (data['progressPercent'] as num?)?.toInt() ?? 0,
        targetCompletionDate:
            (data['targetCompletionDate'] as Timestamp?)?.toDate(),
      );
}

// ── Seed Data ─────────────────────────────────────────────────────────────────

const _seedPaths = [
  {
    'title': 'Embedded Systems Engineer',
    'description':
        'Master the foundations and advanced concepts of embedded systems programming. '
            'This path takes you from low-level C programming through real-time operating systems, '
            'Linux device drivers, and professional microcontroller development.',
    'targetRole': 'Embedded Systems Engineer',
    'skills': ['C', 'Embedded C', 'RTOS', 'Linux', 'Microcontrollers', 'Git'],
    'estimatedWeeks': 24,
    'difficulty': 'Advanced',
    'courseTopics': [
      'C Programming Fundamentals',
      'Embedded C for Microcontrollers',
      'FreeRTOS and Real-Time Systems',
      'Linux for Embedded',
      'ARM Cortex Programming',
      'Version Control with Git',
    ],
    'icon': '🔧',
  },
  {
    'title': 'Web Developer',
    'description':
        'Go from zero to a full-stack web developer. Build real-world projects using '
            'modern frontend and backend technologies, learning both the client and server sides '
            'of web development.',
    'targetRole': 'Full-Stack Web Developer',
    'skills': [
      'HTML/CSS',
      'JavaScript',
      'React',
      'Node.js',
      'Databases',
      'Git'
    ],
    'estimatedWeeks': 20,
    'difficulty': 'Beginner',
    'courseTopics': [
      'HTML & CSS Fundamentals',
      'JavaScript Essentials',
      'React for Frontend Development',
      'Node.js and Express',
      'SQL & NoSQL Databases',
      'Git and GitHub',
    ],
    'icon': '🌐',
  },
  {
    'title': 'AI/ML Engineer',
    'description':
        'Build expertise in artificial intelligence and machine learning. '
            'Start with Python and mathematics, then advance through machine learning algorithms, '
            'deep learning architectures, and production-grade model deployment.',
    'targetRole': 'AI/ML Engineer',
    'skills': [
      'Python',
      'Mathematics',
      'Machine Learning',
      'Deep Learning',
      'TensorFlow',
      'Data Analysis',
    ],
    'estimatedWeeks': 28,
    'difficulty': 'Intermediate',
    'courseTopics': [
      'Python for Data Science',
      'Linear Algebra & Calculus',
      'Machine Learning with Scikit-Learn',
      'Deep Learning with TensorFlow',
      'Data Analysis with Pandas',
      'Model Deployment & MLOps',
    ],
    'icon': '🤖',
  },
];

// ── Providers ─────────────────────────────────────────────────────────────────

final learningPathsProvider =
    StreamProvider<List<LearningPath>>((ref) {
  return FirebaseFirestore.instance
      .collection('learningPaths')
      .orderBy('createdAt')
      .snapshots()
      .map((snap) => snap.docs
          .map((d) => LearningPath.fromMap(d.data(), d.id))
          .toList());
});

final enrolledPathsProvider = StreamProvider<List<EnrolledPath>>((ref) {
  final uid = ref.watch(firebaseAuthStateProvider).value?.uid ?? '';
  if (uid.isEmpty) return Stream.value([]);
  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('enrolledPaths')
      .snapshots()
      .map((snap) =>
          snap.docs.map((d) => EnrolledPath.fromMap(d.data())).toList());
});

// ── Main Screen ───────────────────────────────────────────────────────────────

class LearningPathsScreen extends ConsumerStatefulWidget {
  const LearningPathsScreen({super.key});

  @override
  ConsumerState<LearningPathsScreen> createState() =>
      _LearningPathsScreenState();
}

class _LearningPathsScreenState extends ConsumerState<LearningPathsScreen> {
  bool _seeded = false;

  @override
  void initState() {
    super.initState();
    _seedIfEmpty();
  }

  Future<void> _seedIfEmpty() async {
    if (_seeded) return;
    _seeded = true;
    final col = FirebaseFirestore.instance.collection('learningPaths');
    final snap = await col.limit(1).get();
    if (snap.docs.isNotEmpty) return;
    final batch = FirebaseFirestore.instance.batch();
    for (final p in _seedPaths) {
      final ref = col.doc();
      batch.set(ref, {
        ...p,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    final pathsAsync = ref.watch(learningPathsProvider);
    final enrolledAsync = ref.watch(enrolledPathsProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: MediaQuery.sizeOf(context).width < 900
          ? AppBar(
              backgroundColor: AppColors.bg,
              title: const Text('Learning Paths'),
            )
          : null,
      body: pathsAsync.when(
        loading: () => ListView.separated(
          padding: const EdgeInsets.all(AppSizes.screenPadding),
          itemCount: 4,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, __) => const ShimmerCard(height: 160),
        ),
        error: (e, _) => DoeetErrorWidget(
          message: e.toString(),
          onRetry: () => ref.invalidate(learningPathsProvider),
        ),
        data: (paths) {
          final enrolled = enrolledAsync.value ?? [];
          final enrolledIds = {for (final e in enrolled) e.pathId};

          return CustomScrollView(
            slivers: [
              // ── My Paths section ─────────────────────────────────────────
              if (enrolled.isNotEmpty) ...[
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                        AppSizes.screenPadding, 20, AppSizes.screenPadding, 12),
                    child: Text(
                      'My Paths',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.screenPadding),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) {
                        final ep = enrolled[i];
                        final path = paths.firstWhere(
                          (p) => p.id == ep.pathId,
                          orElse: () => LearningPath(
                            id: ep.pathId,
                            title: 'Path',
                            description: '',
                            targetRole: '',
                            skills: [],
                            estimatedWeeks: 0,
                            difficulty: '',
                            courseTopics: [],
                            icon: '📚',
                            createdAt: DateTime.now(),
                          ),
                        );
                        return _EnrolledPathCard(
                          path: path,
                          enrolled: ep,
                          onTap: () =>
                              context.push('/learning-path/${ep.pathId}'),
                        )
                            .animate(
                                delay: Duration(milliseconds: i * 60))
                            .fadeIn()
                            .slideY(begin: 0.1, end: 0);
                      },
                      childCount: enrolled.length,
                    ),
                  ),
                ),
              ],

              // ── All paths section ─────────────────────────────────────────
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                      AppSizes.screenPadding, 20, AppSizes.screenPadding, 12),
                  child: Text(
                    'Explore Paths',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),

              if (paths.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('🗺️', style: TextStyle(fontSize: 56)),
                        SizedBox(height: 16),
                        Text(
                          'No learning paths yet',
                          style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Check back soon for curated paths',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(AppSizes.screenPadding, 0,
                      AppSizes.screenPadding, 32),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) {
                        final path = paths[i];
                        return _PathCard(
                          path: path,
                          isEnrolled: enrolledIds.contains(path.id),
                          onTap: () =>
                              context.push('/learning-path/${path.id}'),
                        )
                            .animate(
                                delay: Duration(milliseconds: i * 60))
                            .fadeIn()
                            .slideY(begin: 0.1, end: 0);
                      },
                      childCount: paths.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ── Path Card ─────────────────────────────────────────────────────────────────

class _PathCard extends StatelessWidget {
  const _PathCard({
    required this.path,
    required this.isEnrolled,
    required this.onTap,
  });

  final LearningPath path;
  final bool isEnrolled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final diffColor = _difficultyColor(path.difficulty);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Text(path.icon, style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        path.title,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        path.targetRole,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isEnrolled)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Enrolled',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // Description
            Text(
              path.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),

            // Stats row
            Row(
              children: [
                _Pill(Icons.schedule_outlined,
                    '${path.estimatedWeeks}w', AppColors.textSecondary),
                const SizedBox(width: 8),
                _DiffBadge(path.difficulty, diffColor),
              ],
            ),
            const SizedBox(height: 10),

            // Skill chips
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: path.skills
                  .take(5)
                  .map((s) => _SkillChip(label: s))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Color _difficultyColor(String d) {
    return switch (d.toLowerCase()) {
      'beginner' => AppColors.success,
      'advanced' => AppColors.error,
      _ => AppColors.xpGold,
    };
  }
}

// ── Enrolled Path Card ────────────────────────────────────────────────────────

class _EnrolledPathCard extends StatelessWidget {
  const _EnrolledPathCard({
    required this.path,
    required this.enrolled,
    required this.onTap,
  });

  final LearningPath path;
  final EnrolledPath enrolled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withOpacity(0.12),
              AppColors.bgCard,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Text(path.icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    path.title,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: enrolled.progressPercent / 100,
                      backgroundColor: AppColors.bgElevated,
                      valueColor:
                          const AlwaysStoppedAnimation(AppColors.primary),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${enrolled.progressPercent}% complete',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

// ── Detail Screen ─────────────────────────────────────────────────────────────

class LearningPathDetailScreen extends ConsumerWidget {
  const LearningPathDetailScreen({super.key, required this.pathId});
  final String pathId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pathsAsync = ref.watch(learningPathsProvider);
    final enrolledAsync = ref.watch(enrolledPathsProvider);
    final uid = ref.watch(firebaseAuthStateProvider).value?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: pathsAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => DoeetErrorWidget(message: e.toString()),
        data: (paths) {
          final path = paths.cast<LearningPath?>().firstWhere(
                (p) => p?.id == pathId,
                orElse: () => null,
              );
          if (path == null) {
            return const DoeetErrorWidget(message: 'Path not found');
          }

          final enrolled = enrolledAsync.value ?? [];
          final isEnrolled = enrolled.any((e) => e.pathId == pathId);
          final ep = isEnrolled
              ? enrolled.firstWhere((e) => e.pathId == pathId)
              : null;

          return CustomScrollView(
            slivers: [
              // AppBar
              SliverAppBar(
                pinned: true,
                backgroundColor: AppColors.bg,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded,
                      color: AppColors.textPrimary),
                  onPressed: () => context.go('/learning-paths'),
                ),
                title: Text(
                  path.title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.all(AppSizes.screenPadding),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Hero
                    Center(
                      child: Text(path.icon,
                          style: const TextStyle(fontSize: 72)),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      path.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Center(
                      child: Text(
                        path.targetRole,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Stats row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _Pill(Icons.schedule_outlined,
                            '${path.estimatedWeeks} weeks',
                            AppColors.textSecondary),
                        const SizedBox(width: 8),
                        _DiffBadge(
                          path.difficulty,
                          _diffColor(path.difficulty),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Description
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        path.description,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Skills
                    const Text(
                      'Skills You\'ll Learn',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          path.skills.map((s) => _SkillChip(label: s)).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Course Topics
                    const Text(
                      'Suggested Course Topics',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...path.courseTopics.asMap().entries.map((e) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.bgCard,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Center(
                                child: Text(
                                  '${e.key + 1}',
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                e.value,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 24),

                    // Progress if enrolled
                    if (isEnrolled && ep != null) ...[
                      const Text(
                        'Your Progress',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.bgCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: ep.progressPercent / 100,
                                backgroundColor: AppColors.bgElevated,
                                valueColor: const AlwaysStoppedAnimation(
                                    AppColors.primary),
                                minHeight: 10,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${ep.progressPercent}% complete',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Enroll / Continue button
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: uid.isEmpty
                            ? null
                            : () => _handleEnroll(context, uid, path),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          isEnrolled ? 'Continue Learning' : 'Enroll Now',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Color _diffColor(String d) {
    return switch (d.toLowerCase()) {
      'beginner' => AppColors.success,
      'advanced' => AppColors.error,
      _ => AppColors.xpGold,
    };
  }

  Future<void> _handleEnroll(
      BuildContext context, String uid, LearningPath path) async {
    final col = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('enrolledPaths');
    final existing = await col.doc(path.id).get();
    if (existing.exists) {
      // Already enrolled — just navigate to courses
      if (context.mounted) context.go('/courses');
      return;
    }
    await col.doc(path.id).set({
      'pathId': path.id,
      'enrolledAt': FieldValue.serverTimestamp(),
      'progressPercent': 0,
      'targetCompletionDate': null,
    });
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Enrolled in ${path.title}!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

// ── Shared small widgets ──────────────────────────────────────────────────────

class _Pill extends StatelessWidget {
  const _Pill(this.icon, this.label, this.color);
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
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    fontFamily: 'Inter', fontSize: 12, color: color)),
          ],
        ),
      );
}

class _DiffBadge extends StatelessWidget {
  const _DiffBadge(this.label, this.color);
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      );
}

class _SkillChip extends StatelessWidget {
  const _SkillChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.bgElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      );
}
