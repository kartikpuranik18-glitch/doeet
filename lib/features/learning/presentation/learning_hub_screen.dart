import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';

/// A course discovery space. It intentionally has no job or company content.
class LearningHubScreen extends StatelessWidget {
  const LearningHubScreen({super.key});

  static const _courses = <_CoursePick>[
    _CoursePick('CS50: Introduction to Computer Science', 'Harvard University', 'Computer science', Icons.terminal_rounded, Color(0xFFEAF1FF), 'https://www.edx.org/learn/computer-science/harvard-university-cs50-s-introduction-to-computer-science'),
    _CoursePick('Machine Learning Specialization', 'DeepLearning.AI', 'Machine learning', Icons.psychology_outlined, Color(0xFFF0ECFF), 'https://www.coursera.org/specializations/machine-learning-introduction'),
    _CoursePick('Google Data Analytics', 'Google Career Certificates', 'Data analytics', Icons.query_stats_rounded, Color(0xFFE7F8F2), 'https://www.coursera.org/professional-certificates/google-data-analytics'),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(28, 30, 28, 56),
                children: [
                  const _Eyebrow(icon: Icons.school_outlined, text: 'LEARNING HOME'),
                  const SizedBox(height: 12),
                  Text('Build skills that\nmove you forward.', style: Theme.of(context).textTheme.displayMedium),
                  const SizedBox(height: 10),
                  const Text('Discover world-class courses, make a focused study plan, and learn at your own pace.', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                  const SizedBox(height: 28),
                  _HeroPanel(
                    onImport: () => context.go('/import-course'),
                    onCourses: () => context.go('/courses'),
                  ),
                  const SizedBox(height: 42),
                  _SectionTitle(title: 'Keep learning', action: 'View my courses', onAction: () => context.go('/courses')),
                  const SizedBox(height: 14),
                  _ContinueCard(onTap: () => context.go('/courses')),
                  const SizedBox(height: 42),
                  const _SectionTitle(title: 'Top picks from global educators'),
                  const SizedBox(height: 6),
                  const Text('Hand-picked starting points from trusted providers. Explore a course, then add a YouTube playlist to track it in Dooet.', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                  const SizedBox(height: 18),
                  LayoutBuilder(builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 860;
                    final cardWidth = wide ? (constraints.maxWidth - 32) / 3 : constraints.maxWidth;
                    return Wrap(spacing: 16, runSpacing: 16, children: [
                      for (final course in _courses) SizedBox(width: cardWidth, child: _CourseCard(course: course)),
                    ]);
                  }),
                  const SizedBox(height: 44),
                  const _SectionTitle(title: 'Live learning & webinars'),
                  const SizedBox(height: 16),
                  const _EventsPanel(),
                ],
              ),
            ),
          ),
        ),
      );
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 7),
        Text(text, style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
      ]);
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({required this.onImport, required this.onCourses});
  final VoidCallback onImport;
  final VoidCallback onCourses;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(.16), blurRadius: 26, offset: const Offset(0, 12))],
        ),
        child: LayoutBuilder(builder: (context, constraints) {
          final stacked = constraints.maxWidth < 660;
          final copy = Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.play_circle_fill_rounded, color: Color(0xFFFFC0D4), size: 20),
              SizedBox(width: 8),
              Text('YOUR FOCUSED STUDY SPACE', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.1)),
            ]),
            const SizedBox(height: 18),
            const Text('Turn any YouTube playlist\ninto a course.', style: TextStyle(color: Colors.white, fontSize: 26, height: 1.15, fontWeight: FontWeight.w800, letterSpacing: -0.7)),
            const SizedBox(height: 10),
            const Text('No distractions. Just structured lessons, notes and progress that stays with you.', style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5)),
          ]);
          final actions = Wrap(spacing: 10, runSpacing: 10, children: [
            FilledButton.icon(onPressed: onImport, icon: const Icon(Icons.add_rounded, size: 18), label: const Text('Create from playlist'), style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.primaryDark)),
            OutlinedButton(onPressed: onCourses, child: const Text('My library'), style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white54))),
          ]);
          return stacked ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [copy, const SizedBox(height: 24), actions]) : Row(children: [Expanded(child: copy), const SizedBox(width: 26), actions]);
        }),
      );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.action, this.onAction});
  final String title;
  final String? action;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(child: Text(title, style: Theme.of(context).textTheme.headlineSmall)),
        if (action != null) TextButton.icon(onPressed: onAction, icon: const Icon(Icons.arrow_forward_rounded, size: 17), label: Text(action!)),
      ]);
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(16)),
            child: Row(children: [
              Container(width: 48, height: 48, decoration: BoxDecoration(color: const Color(0xFFFFEEF4), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.play_arrow_rounded, color: AppColors.brandPink)),
              const SizedBox(width: 16),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Continue your learning', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                SizedBox(height: 4),
                Text('Your saved courses and lesson progress are waiting.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ])),
              const Icon(Icons.arrow_forward_rounded, color: AppColors.primary),
            ]),
          ),
        ),
      );
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({required this.course});
  final _CoursePick course;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: AppColors.bgCard, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 48, height: 48, decoration: BoxDecoration(color: course.tint, borderRadius: BorderRadius.circular(14)), child: Icon(course.icon, color: AppColors.primaryDark)),
          const SizedBox(height: 18),
          Text(course.topic.toUpperCase(), style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
          const SizedBox(height: 8),
          Text(course.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, height: 1.3)),
          const SizedBox(height: 7),
          Text(course.provider, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 18),
          TextButton.icon(onPressed: () => launchUrl(Uri.parse(course.url), mode: LaunchMode.externalApplication), icon: const Icon(Icons.open_in_new_rounded, size: 15), label: const Text('Explore course')),
        ]),
      );
}

class _EventsPanel extends StatelessWidget {
  const _EventsPanel();
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: AppColors.bgCard, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(16)),
        child: Column(children: const [
          _EventRow(icon: Icons.live_tv_rounded, color: AppColors.accentPurple, title: 'MIT OpenCourseWare events', detail: 'Lectures, talks and recorded sessions', url: 'https://ocw.mit.edu/'),
          Divider(height: 32),
          _EventRow(icon: Icons.groups_rounded, color: AppColors.accentCyan, title: 'Google for Developers events', detail: 'Community sessions and developer webinars', url: 'https://developers.google.com/events'),
        ]),
      );
}

class _EventRow extends StatelessWidget {
  const _EventRow({required this.icon, required this.color, required this.title, required this.detail, required this.url});
  final IconData icon;
  final Color color;
  final String title;
  final String detail;
  final String url;
  @override
  Widget build(BuildContext context) => Row(children: [
        Container(width: 42, height: 42, decoration: BoxDecoration(color: color.withOpacity(.12), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 21)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 3), Text(detail, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))])),
        TextButton(onPressed: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication), child: const Text('View')),
      ]);
}

class _CoursePick {
  const _CoursePick(this.title, this.provider, this.topic, this.icon, this.tint, this.url);
  final String title;
  final String provider;
  final String topic;
  final IconData icon;
  final Color tint;
  final String url;
}
