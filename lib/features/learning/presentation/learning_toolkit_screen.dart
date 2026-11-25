import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// Deliberately realistic product prototypes for learning features that are
/// ready to be connected to personalised backend data later.
class LearningToolkitScreen extends StatelessWidget {
  const LearningToolkitScreen({super.key, required this.section});
  final String section;

  @override
  Widget build(BuildContext context) {
    final page = switch (section) {
      'paths' => _ToolkitPage.paths,
      'practice' => _ToolkitPage.practice,
      'projects' => _ToolkitPage.projects,
      'webinars' => _ToolkitPage.webinars,
      'certificates' => _ToolkitPage.certificates,
      _ => _ToolkitPage.paths,
    };
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(28, 30, 28, 56),
              children: [
                _PageHeading(page: page),
                const SizedBox(height: 28),
                switch (page) {
                  _ToolkitPage.paths => const _PathsView(),
                  _ToolkitPage.practice => const _PracticeView(),
                  _ToolkitPage.projects => const _ProjectsView(),
                  _ToolkitPage.webinars => const _WebinarsView(),
                  _ToolkitPage.certificates => const _CertificatesView(),
                },
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _ToolkitPage { paths, practice, projects, webinars, certificates }

class _PageHeading extends StatelessWidget {
  const _PageHeading({required this.page});
  final _ToolkitPage page;
  @override
  Widget build(BuildContext context) {
    final data = switch (page) {
      _ToolkitPage.paths => (Icons.route_outlined, 'LEARNING PATHS', 'Choose a clear route. Build a job-ready skill stack.'),
      _ToolkitPage.practice => (Icons.bolt_outlined, 'PRACTICE LAB', 'Sharpen the skills that matter with short, focused practice.'),
      _ToolkitPage.projects => (Icons.folder_copy_outlined, 'PROJECT STUDIO', 'Turn lessons into portfolio-ready proof of work.'),
      _ToolkitPage.webinars => (Icons.live_tv_outlined, 'LIVE LEARNING', 'Talks, workshops and recordings from global educators.'),
      _ToolkitPage.certificates => (Icons.verified_outlined, 'CREDENTIALS', 'Your verified learning record, ready to share.'),
    };
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(data.$1, color: AppColors.primary, size: 17), const SizedBox(width: 7), Text(data.$2, style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.15))]),
      const SizedBox(height: 12),
      Text(data.$3, style: Theme.of(context).textTheme.headlineLarge),
    ]);
  }
}

class _PathsView extends StatelessWidget {
  const _PathsView();
  @override
  Widget build(BuildContext context) => Wrap(spacing: 16, runSpacing: 16, children: const [
        _PathCard(icon: Icons.code_rounded, color: Color(0xFF2866E1), title: 'Frontend Developer', detail: 'HTML · CSS · JavaScript · React', lessons: '42 lessons', progress: .38),
        _PathCard(icon: Icons.query_stats_rounded, color: Color(0xFF16885E), title: 'Data Analyst', detail: 'Excel · SQL · Power BI · Python', lessons: '36 lessons', progress: .12),
        _PathCard(icon: Icons.design_services_outlined, color: Color(0xFF7259CC), title: 'UI/UX Designer', detail: 'Research · Figma · Design systems', lessons: '31 lessons', progress: 0),
        _PathCard(icon: Icons.memory_rounded, color: Color(0xFFE07A31), title: 'Java Developer', detail: 'Core Java · Spring Boot · APIs', lessons: '46 lessons', progress: 0),
      ]);
}

class _PathCard extends StatelessWidget {
  const _PathCard({required this.icon, required this.color, required this.title, required this.detail, required this.lessons, required this.progress});
  final IconData icon; final Color color; final String title; final String detail; final String lessons; final double progress;
  @override
  Widget build(BuildContext context) => SizedBox(width: 270, child: Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Container(width: 46, height: 46, decoration: BoxDecoration(color: color.withOpacity(.12), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: color)),
    const SizedBox(height: 18), Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)), const SizedBox(height: 6), Text(detail, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
    const SizedBox(height: 18), Row(children: [Text(lessons, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)), const Spacer(), Text(progress == 0 ? 'Start path' : '${(progress * 100).round()}%', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w800))]),
    const SizedBox(height: 8), ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: progress, minHeight: 6, backgroundColor: AppColors.bgElevated, valueColor: AlwaysStoppedAnimation(color))), const SizedBox(height: 16),
    SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () {}, child: Text(progress == 0 ? 'View roadmap' : 'Continue path'))),
  ])));
}

class _PracticeView extends StatelessWidget {
  const _PracticeView();
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(color: AppColors.primaryDark, borderRadius: BorderRadius.circular(18)), child: const Row(children: [Icon(Icons.timer_outlined, color: Color(0xFFFFC4D5), size: 28), SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Today’s 15-minute challenge', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)), SizedBox(height: 4), Text('Solve two SQL filtering questions and reinforce your fundamentals.', style: TextStyle(color: Colors.white70, fontSize: 13))])), Icon(Icons.arrow_forward_rounded, color: Colors.white)])),
    const SizedBox(height: 24), const Text('Practice by skill', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)), const SizedBox(height: 14),
    const _FeatureTile(icon: Icons.code_rounded, title: 'Coding challenges', detail: '128 beginner-to-advanced programming questions', tag: '12 new'),
    const _FeatureTile(icon: Icons.calculate_outlined, title: 'Aptitude practice', detail: 'Quantitative, logical and verbal reasoning sets', tag: '8 min'),
    const _FeatureTile(icon: Icons.quiz_outlined, title: 'Course quizzes', detail: 'Quick checks that help you retain what you learn', tag: '24 questions'),
    const _FeatureTile(icon: Icons.style_outlined, title: 'Flashcards', detail: 'Build and revise the concepts you need to remember', tag: 'Review'),
  ]);
}

class _ProjectsView extends StatelessWidget {
  const _ProjectsView();
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(color: const Color(0xFFFFF2F6), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFF8D6E2))), child: Row(children: [const Icon(Icons.lightbulb_outline_rounded, color: AppColors.brandPink, size: 28), const SizedBox(width: 14), const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Portfolio projects make learning visible.', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)), SizedBox(height: 4), Text('Complete a brief, attach a live link, and share it in your career profile.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13))])), OutlinedButton(onPressed: () {}, child: const Text('Create project'))])),
    const SizedBox(height: 24),
    const _FeatureTile(icon: Icons.dashboard_customize_outlined, title: 'Sales dashboard', detail: 'Build an interactive dashboard with Excel or Power BI.', tag: 'Data analytics · 6 hrs'),
    const _FeatureTile(icon: Icons.web_outlined, title: 'Personal portfolio website', detail: 'Design and ship a responsive portfolio using HTML, CSS and JavaScript.', tag: 'Frontend · 8 hrs'),
    const _FeatureTile(icon: Icons.smart_toy_outlined, title: 'Customer support classifier', detail: 'Create a simple machine learning project using Python.', tag: 'Machine learning · 10 hrs'),
  ]);
}

class _WebinarsView extends StatelessWidget {
  const _WebinarsView();
  @override
  Widget build(BuildContext context) => Column(children: const [
    _FeatureTile(icon: Icons.calendar_today_outlined, title: 'Designing systems that scale', detail: 'Live workshop · Thu, 6:30 PM IST · with Google Developer Expert', tag: 'Register'),
    _FeatureTile(icon: Icons.calendar_today_outlined, title: 'How to build a recruiter-ready portfolio', detail: 'Live career session · Sat, 11:00 AM IST', tag: 'Register'),
    _FeatureTile(icon: Icons.play_circle_outline_rounded, title: 'From learner to frontend developer', detail: 'Recording · 48 minutes · Career stories and roadmap', tag: 'Watch'),
    _FeatureTile(icon: Icons.play_circle_outline_rounded, title: 'SQL patterns for data interviews', detail: 'Recording · 62 minutes · Practice walk-through', tag: 'Watch'),
  ]);
}

class _CertificatesView extends StatelessWidget {
  const _CertificatesView();
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)), child: const Row(children: [Icon(Icons.verified_rounded, color: AppColors.success, size: 30), SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Your learning record', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)), SizedBox(height: 4), Text('Verified certificates will appear here when you complete eligible courses.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13))]))])),
    const SizedBox(height: 24), const _FeatureTile(icon: Icons.workspace_premium_outlined, title: 'Frontend Foundations', detail: 'In progress · Complete 7 more lessons to become eligible', tag: '72% complete'),
    const _FeatureTile(icon: Icons.workspace_premium_outlined, title: 'Data Analytics Essentials', detail: 'Locked · Start this learning path to earn a credential', tag: 'Explore path'),
  ]);
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({required this.icon, required this.title, required this.detail, required this.tag});
  final IconData icon; final String title; final String detail; final String tag;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(15), border: Border.all(color: AppColors.border)), child: Row(children: [Container(width: 43, height: 43, decoration: BoxDecoration(color: AppColors.bgElevated, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: AppColors.primary)), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 4), Text(detail, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))])), const SizedBox(width: 12), Text(tag, style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w800))]))));
}
