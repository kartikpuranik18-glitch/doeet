import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';

/// Learning discovery is intentionally separate from employment. These are
/// curated external learning resources; no progress is claimed until a user
/// imports a YouTube playlist into their own Dooet course library.
class LearningHubScreen extends StatelessWidget {
  const LearningHubScreen({super.key});

  static const _courses = <_Resource>[
    _Resource(
      title: 'CS50: Introduction to Computer Science',
      provider: 'Harvard University',
      topic: 'Computer science',
      url: 'https://www.edx.org/learn/computer-science/harvard-university-cs50-s-introduction-to-computer-science',
    ),
    _Resource(
      title: 'Machine Learning Specialization',
      provider: 'DeepLearning.AI',
      topic: 'Machine learning',
      url: 'https://www.coursera.org/specializations/machine-learning-introduction',
    ),
    _Resource(
      title: 'Google Data Analytics',
      provider: 'Google Career Certificates',
      topic: 'Data analytics',
      url: 'https://www.coursera.org/professional-certificates/google-data-analytics',
    ),
  ];

  static const _events = <_Resource>[
    _Resource(
      title: 'MIT OpenCourseWare live & recorded events',
      provider: 'MIT OpenCourseWare',
      topic: 'Lectures and events',
      url: 'https://ocw.mit.edu/',
    ),
    _Resource(
      title: 'Google Developers events',
      provider: 'Google for Developers',
      topic: 'Developer webinars',
      url: 'https://developers.google.com/events',
    ),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1060),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 48),
                children: [
                  const Text('Learning',
                      style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.8)),
                  const SizedBox(height: 8),
                  const Text('A focused place to learn without the YouTube noise.',
                      style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 28),
                  _ImportCallout(
                    onImport: () => context.go('/import-course'),
                    onCourses: () => context.go('/courses'),
                  ),
                  const SizedBox(height: 40),
                  _SectionHeader(
                    title: 'My learning',
                    action: 'My courses',
                    onAction: () => context.go('/courses'),
                  ),
                  const SizedBox(height: 12),
                  _SimpleActionRow(
                    icon: Icons.playlist_play_outlined,
                    title: 'Continue a course',
                    subtitle: 'Pick up exactly where you stopped.',
                    onTap: () => context.go('/courses'),
                  ),
                  const SizedBox(height: 36),
                  const _SectionHeader(title: 'Global course picks'),
                  const SizedBox(height: 6),
                  const Text(
                    'Independent recommendations. Open a provider to explore, or import a YouTube playlist to track it in Dooet.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  ..._courses.map((item) => _ResourceRow(resource: item)),
                  const SizedBox(height: 36),
                  const _SectionHeader(title: 'Webinars & live learning'),
                  const SizedBox(height: 6),
                  const Text(
                    'Events are hosted by their providers. Check the source for current dates and registration.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  ..._events.map((item) => _ResourceRow(resource: item, event: true)),
                ],
              ),
            ),
          ),
        ),
      );
}

class _ImportCallout extends StatelessWidget {
  const _ImportCallout({required this.onImport, required this.onCourses});
  final VoidCallback onImport;
  final VoidCallback onCourses;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) => Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 16,
            children: [
              const SizedBox(
                width: 520,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Finish what you started.',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                  SizedBox(height: 6),
                  Text('Paste a YouTube playlist and follow it lesson by lesson — without distractions.',
                      style: TextStyle(color: AppColors.textSecondary, height: 1.4)),
                ]),
              ),
              Row(mainAxisSize: MainAxisSize.min, children: [
                OutlinedButton(onPressed: onCourses, child: const Text('My courses')),
                const SizedBox(width: 10),
                FilledButton.icon(
                  onPressed: onImport,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add playlist'),
                ),
              ]),
            ],
          ),
        ),
      );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.action, this.onAction});
  final String title;
  final String? action;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(child: Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700))),
        if (action != null) TextButton(onPressed: onAction, child: Text(action!)),
      ]);
}

class _SimpleActionRow extends StatelessWidget {
  const _SimpleActionRow({required this.icon, required this.title, required this.subtitle, required this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ])),
              const Icon(Icons.arrow_forward_rounded, size: 18),
            ]),
          ),
        ),
      );
}

class _ResourceRow extends StatelessWidget {
  const _ResourceRow({required this.resource, this.event = false});
  final _Resource resource;
  final bool event;
  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          leading: Icon(event ? Icons.videocam_outlined : Icons.menu_book_outlined, color: AppColors.primary),
          title: Text(resource.title, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text('${resource.provider} · ${resource.topic}'),
          trailing: TextButton(
            onPressed: () => launchUrl(Uri.parse(resource.url), mode: LaunchMode.externalApplication),
            child: const Text('Explore'),
          ),
        ),
      );
}

class _Resource {
  const _Resource({required this.title, required this.provider, required this.topic, required this.url});
  final String title;
  final String provider;
  final String topic;
  final String url;
}
