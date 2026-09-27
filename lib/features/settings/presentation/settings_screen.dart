// lib/features/settings/presentation/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../auth/presentation/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final authAction = ref.watch(authNotifierProvider);
    final isSigningOut = authAction.isLoading;

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: MediaQuery.sizeOf(context).width < 900
          ? AppBar(
              backgroundColor: AppColors.bgPrimary,
              title: const Text('Settings'))
          : null,
      body: userAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.accentPurple)),
        error: (_, __) => const Center(child: Text('Error loading settings')),
        data: (user) => SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // ── Profile card ────────────────────────────────────────────────
              GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor:
                            AppColors.accentPurple.withOpacity(0.2),
                        backgroundImage: user?.photoUrl != null
                            ? NetworkImage(user!.photoUrl!)
                            : null,
                        child: user?.photoUrl == null
                            ? Text(
                                user?.displayName.isNotEmpty == true
                                    ? user!.displayName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                    color: AppColors.accentPurple,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700),
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.displayName ?? 'Guest User',
                              style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user?.email ?? '',
                              style: const TextStyle(
                                  color: AppColors.textSecondary, fontSize: 13),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _MiniChip(
                                    label: '⚡ ${user?.xp ?? 0} XP',
                                    color: AppColors.accentPurple),
                                const SizedBox(width: 8),
                                _MiniChip(
                                    label: '🔥 ${user?.streakDays ?? 0} streak',
                                    color: const Color(0xFFFF6B2B)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 100.ms),

              const SizedBox(height: 20),

              // ── Learning settings ───────────────────────────────────────────
              _SectionLabel(label: 'Learning'),
              GlassCard(
                child: Column(
                  children: [
                    _SettingsTile(
                      icon: Icons.timer_rounded,
                      title: 'Daily Goal',
                      subtitle:
                          '${user?.dailyGoalMinutes ?? 30} minutes per day',
                        onTap: user == null
                          ? null
                          : () => _showGoalPicker(
                            context, ref, user.uid, user.dailyGoalMinutes),
                    ),
                    _Divider(),
                    _SettingsTile(
                      icon: Icons.notifications_rounded,
                      title: 'Study Reminders',
                      subtitle: 'Choose a daily reminder time',
                      onTap: () => _showReminderPicker(context),
                    ),
                    _Divider(),
                    _SettingsTile(
                      icon: Icons.speed_rounded,
                      title: 'Default Playback Speed',
                      subtitle: '1.0x',
                      onTap: () => _showSpeedPicker(context),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 150.ms),

              const SizedBox(height: 16),

              // ── AI settings ─────────────────────────────────────────────────
              _SectionLabel(label: 'AI Features'),
              GlassCard(
                child: Column(
                  children: [
                    _SettingsTile(
                      icon: Icons.key_rounded,
                      title: 'OpenAI API Key',
                      subtitle: 'Configured at build time',
                      onTap: () => _showApiConfigDialog(context),
                    ),
                    _Divider(),
                    _SettingsTile(
                      icon: Icons.translate_rounded,
                      title: 'AI Language',
                      subtitle: 'English',
                      onTap: () => _showLanguagePicker(context),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 16),

              // ── About ───────────────────────────────────────────────────────
              _SectionLabel(label: 'About'),
              GlassCard(
                child: Column(
                  children: [
                    _SettingsTile(
                      icon: Icons.info_outline_rounded,
                      title: 'App Version',
                      subtitle: '1.0.0 (Build 1)',
                      onTap: null,
                    ),
                    _Divider(),
                    _SettingsTile(
                      icon: Icons.privacy_tip_outlined,
                      title: 'Privacy Policy',
                      onTap: () => _showPolicyDialog(
                          context, 'Privacy Policy', _privacyPolicy),
                    ),
                    _Divider(),
                    _SettingsTile(
                      icon: Icons.description_outlined,
                      title: 'Terms of Service',
                      onTap: () => _showPolicyDialog(
                          context, 'Terms of Service', _termsOfService),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 250.ms),

              const SizedBox(height: 24),

              // ── Sign out ────────────────────────────────────────────────────
              GradientButton(
                label: isSigningOut ? 'Signing Out…' : 'Sign Out',
                isLoading: isSigningOut,
                onPressed: isSigningOut
                    ? null
                    : () async {
                        await ref.read(authNotifierProvider.notifier).signOut();
                        if (!context.mounted) return;
                        final result = ref.read(authNotifierProvider);
                        final error = result.whenOrNull(
                          error: (e, _) => authErrorMessage(e),
                        );
                        if (error != null) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(error),
                            backgroundColor: AppColors.error,
                          ));
                        } else {
                          context.go('/login');
                        }
                      },
                gradient: const LinearGradient(
                    colors: [Color(0xFF3A1A1A), Color(0xFF5A2020)]),
              ).animate().fadeIn(delay: 300.ms),

              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  void _showGoalPicker(
      BuildContext context, WidgetRef ref, String uid, int current) {
    final options = [15, 30, 45, 60, 90, 120];
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Daily Study Goal',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: options
                  .map((m) => GestureDetector(
                        onTap: () async {
                          await ref
                              .read(authRepositoryProvider)
                              .updateUser(uid, {'dailyGoalMinutes': m});
                          if (context.mounted) Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: m == current
                                ? AppColors.accentPurple
                                : AppColors.bgSurface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$m min',
                            style: TextStyle(
                              color: m == current
                                  ? Colors.white
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showApiConfigDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: const Text('AI configuration',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'Configure the AI service through a trusted backend or with the '
          'OPENAI_API_KEY build variable. Secrets are never stored in '
          'Firestore or on this device.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close')),
        ],
      ),
    );
  }

  Future<void> _showReminderPicker(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 19, minute: 0),
    );
    if (picked == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('reminderHour', picked.hour);
    await prefs.setInt('reminderMinute', picked.minute);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Reminder preference saved for ${picked.format(context)}.')),
    );
  }

  Future<void> _showSpeedPicker(BuildContext context) async {
    const speeds = [0.75, 1.0, 1.25, 1.5, 2.0];
    final selected = await showModalBottomSheet<double>(
      context: context,
      backgroundColor: AppColors.bgCard,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: speeds
              .map((speed) => ListTile(
                    title: Text('${speed}x'),
                    onTap: () => Navigator.pop(context, speed),
                  ))
              .toList(),
        ),
      ),
    );
    if (selected == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('defaultPlaybackSpeed', selected);
  }

  Future<void> _showLanguagePicker(BuildContext context) async {
    const languages = ['English', 'Spanish', 'French', 'Hindi'];
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.bgCard,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: languages
              .map((language) => ListTile(
                    title: Text(language),
                    onTap: () => Navigator.pop(context, language),
                  ))
              .toList(),
        ),
      ),
    );
    if (selected == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('aiLanguage', selected);
  }

  void _showPolicyDialog(BuildContext context, String title, String body) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: Text(title),
        content: SingleChildScrollView(child: Text(body)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  static const _privacyPolicy =
      'Doeet stores your account, tasks, notes, courses, and progress in your '
      'Firebase project. Data is scoped to your authenticated account. '
      'External AI and video services receive only the content required for '
      'the feature you use.';

  static const _termsOfService =
      'Use Doeet for lawful personal learning and productivity. You are '
      'responsible for content you submit and for any external service keys '
      'configured for development or production.';
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(label,
            style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1)),
      );
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      const Divider(color: AppColors.border, height: 0.5, indent: 52);
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20)),
        child: Text(label,
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.w600)),
      );
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.accentPurple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.accentPurple, size: 20),
        ),
        title: Text(title,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500)),
        subtitle: subtitle != null
            ? Text(subtitle!,
                style:
                    const TextStyle(color: AppColors.textMuted, fontSize: 12))
            : null,
        trailing: onTap != null
            ? const Icon(Icons.chevron_right_rounded,
                color: AppColors.textMuted, size: 20)
            : null,
        onTap: onTap,
      );
}
