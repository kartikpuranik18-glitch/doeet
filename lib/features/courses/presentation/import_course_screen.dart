// lib/features/courses/presentation/import_course_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'courses_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/gradient_button.dart';

class ImportCourseScreen extends ConsumerStatefulWidget {
  const ImportCourseScreen({super.key});

  @override
  ConsumerState<ImportCourseScreen> createState() => _ImportCourseScreenState();
}

class _ImportCourseScreenState extends ConsumerState<ImportCourseScreen> {
  final _urlCtrl = TextEditingController();
  String _selectedCategory = 'General';
  bool _showPreview = false;

  static const _categories = [
    'General', 'Programming', 'Mathematics', 'Science',
    'Design', 'Business', 'Languages', 'Music', 'Health', 'AI & ML',
  ];

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchPreview() async {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty) return;
    FocusScope.of(context).unfocus();
    await ref.read(importNotifierProvider.notifier).fetchPreview(url);
    final state = ref.read(importNotifierProvider);
    state.whenOrNull(
      data: (course) { if (course != null) setState(() => _showPreview = true); },
      error: (e, _) => _showError(e.toString()),
    );
  }

  Future<void> _saveCourse() async {
    final id = await ref
        .read(importNotifierProvider.notifier)
        .saveCourse(category: _selectedCategory);
    if (!mounted) return;
    if (id != null) {
      context.go('/course/$id');
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final importState = ref.watch(importNotifierProvider);
    final isLoading = importState.isLoading;
    final previewCourse = ref.read(importNotifierProvider.notifier).previewCourse;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Import Course'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            ref.read(importNotifierProvider.notifier).reset();
            context.go('/courses');
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary.withOpacity(0.1), Colors.transparent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: const Row(
                children: [
                  Text('📺', style: TextStyle(fontSize: 36)),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('YouTube Playlist Import',
                            style: TextStyle(fontFamily: 'Inter', fontSize: 16,
                                fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                        SizedBox(height: 4),
                        Text('Paste any YouTube playlist URL to import all videos as a structured course.',
                            style: TextStyle(fontFamily: 'Inter', fontSize: 13,
                                color: AppColors.textSecondary, height: 1.4)),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: 0.2, end: 0),

            const SizedBox(height: 28),

            // ── URL Input ────────────────────────────────
            const Text('Playlist URL',
                style: TextStyle(fontFamily: 'Inter', fontSize: 15,
                    fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _urlCtrl,
                    style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'Inter', fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'https://youtube.com/playlist?list=...',
                      hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                      prefixIcon: const Icon(Icons.link_rounded, color: AppColors.textMuted),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.content_paste_rounded, color: AppColors.textMuted),
                        onPressed: () async {
                          final data = await Clipboard.getData('text/plain');
                          if (data?.text != null) _urlCtrl.text = data!.text!;
                        },
                      ),
                    ),
                    onSubmitted: (_) => _fetchPreview(),
                  ),
                ),
              ],
            ).animate(delay: 100.ms).fadeIn(),

            const SizedBox(height: 12),

            // ── Example hints ────────────────────────────
            const Text('Supported formats:',
                style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.textMuted)),
            const SizedBox(height: 6),
            ...[
              'youtube.com/playlist?list=PLxxxxxx',
              'youtube.com/watch?v=xxx&list=PLxxxxxx',
            ].map((hint) => Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text('• $hint',
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 11,
                          color: AppColors.textMuted, fontStyle: FontStyle.italic)),
                )),

            const SizedBox(height: 24),

            GradientButton(
              label: 'Fetch Playlist',
              onPressed: isLoading ? null : _fetchPreview,
              isLoading: isLoading,
              icon: const Icon(Icons.search_rounded, color: Colors.white, size: 18),
            ).animate(delay: 200.ms).fadeIn(),

            // ── Preview ──────────────────────────────────
            if (_showPreview && previewCourse != null) ...[
              const SizedBox(height: 28),
              const Divider(color: AppColors.border),
              const SizedBox(height: 20),
              const Text('Preview 👀',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 18,
                      fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 14),

              // Thumbnail + info
              Container(
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: previewCourse.thumbnailUrl.isNotEmpty
                          ? Image.network(previewCourse.thumbnailUrl,
                              height: 160, width: double.infinity, fit: BoxFit.cover)
                          : Container(height: 160, color: AppColors.bgElevated,
                              child: const Icon(Icons.video_library_outlined,
                                  color: AppColors.primary, size: 40)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(previewCourse.title,
                              style: const TextStyle(fontFamily: 'Inter', fontSize: 16,
                                  fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                          const SizedBox(height: 6),
                          Text(previewCourse.channelName,
                              style: const TextStyle(fontFamily: 'Inter', fontSize: 13,
                                  color: AppColors.secondary)),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              _InfoChip(icon: Icons.video_library_outlined,
                                  label: '${previewCourse.videoCount} videos'),
                              const SizedBox(width: 8),
                              _InfoChip(icon: Icons.timer_outlined,
                                  label: previewCourse.formattedDuration),
                            ],
                          ),
                          if (previewCourse.description.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(previewCourse.description,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontFamily: 'Inter', fontSize: 12,
                                    color: AppColors.textSecondary, height: 1.5)),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn().scale(begin: const Offset(0.97, 0.97)),

              const SizedBox(height: 20),

              // Category selector
              const Text('Category',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 15,
                      fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: _categories.map((cat) {
                  final isSel = _selectedCategory == cat;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSel ? AppColors.primary.withOpacity(0.15) : AppColors.bgElevated,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isSel ? AppColors.primary : AppColors.border,
                            width: isSel ? 1.5 : 1),
                      ),
                      child: Text(cat,
                          style: TextStyle(fontFamily: 'Inter', fontSize: 12,
                              fontWeight: isSel ? FontWeight.w700 : FontWeight.w400,
                              color: isSel ? AppColors.primary : AppColors.textSecondary)),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              GradientButton(
                label: 'Add to Library',
                onPressed: isLoading ? null : _saveCourse,
                isLoading: isLoading,
                gradient: AppColors.successGradient,
                icon: const Icon(Icons.library_add_rounded, color: Colors.white, size: 18),
              ).animate().fadeIn(),

              const SizedBox(height: 40),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

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
            Icon(icon, size: 13, color: AppColors.textMuted),
            const SizedBox(width: 5),
            Text(label,
                style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      );
}
