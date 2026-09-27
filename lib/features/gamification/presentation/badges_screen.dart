// lib/features/gamification/presentation/badges_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../auth/presentation/auth_provider.dart';

// Badge definition model
class BadgeDefinition {
  final String id;
  final String emoji;
  final String title;
  final String description;
  final int xpRequired;
  final Color color;

  const BadgeDefinition({
    required this.id,
    required this.emoji,
    required this.title,
    required this.description,
    required this.xpRequired,
    required this.color,
  });
}

const _allBadges = [
  BadgeDefinition(
      id: 'first_video',
      emoji: '🎬',
      title: 'First Watch',
      description: 'Watch your first video',
      xpRequired: 10,
      color: AppColors.accentCyan),
  BadgeDefinition(
      id: 'streak_3',
      emoji: '🔥',
      title: 'On Fire',
      description: 'Maintain a 3-day streak',
      xpRequired: 50,
      color: Color(0xFFFF6B2B)),
  BadgeDefinition(
      id: 'streak_7',
      emoji: '🌟',
      title: 'Week Warrior',
      description: 'Maintain a 7-day streak',
      xpRequired: 200,
      color: AppColors.accentGold),
  BadgeDefinition(
      id: 'first_course',
      emoji: '📚',
      title: 'Course Starter',
      description: 'Import your first course',
      xpRequired: 20,
      color: AppColors.accentGreen),
  BadgeDefinition(
      id: 'xp_100',
      emoji: '⚡',
      title: 'Power Learner',
      description: 'Earn 100 XP',
      xpRequired: 100,
      color: AppColors.accentPurple),
  BadgeDefinition(
      id: 'xp_500',
      emoji: '💎',
      title: 'XP Master',
      description: 'Earn 500 XP',
      xpRequired: 500,
      color: Color(0xFF00D4FF)),
  BadgeDefinition(
      id: 'ai_user',
      emoji: '🤖',
      title: 'AI Explorer',
      description: 'Use the AI doubt assistant',
      xpRequired: 30,
      color: Color(0xFFBB6BD9)),
  BadgeDefinition(
      id: 'notes_maker',
      emoji: '📝',
      title: 'Note Taker',
      description: 'Create your first note',
      xpRequired: 15,
      color: Color(0xFFFFB020)),
  BadgeDefinition(
      id: 'quiz_ace',
      emoji: '🏅',
      title: 'Quiz Ace',
      description: 'Score 100% on a quiz',
      xpRequired: 80,
      color: AppColors.accentGold),
  BadgeDefinition(
      id: 'course_complete',
      emoji: '🎓',
      title: 'Graduate',
      description: 'Complete an entire course',
      xpRequired: 300,
      color: AppColors.accentGreen),
  BadgeDefinition(
      id: 'flashcard_pro',
      emoji: '🃏',
      title: 'Flashcard Pro',
      description: 'Review 50 flashcards',
      xpRequired: 150,
      color: Color(0xFFFF6B2B)),
  BadgeDefinition(
      id: 'level_5',
      emoji: '🚀',
      title: 'Rising Star',
      description: 'Reach Level 5',
      xpRequired: 2500,
      color: AppColors.accentCyan),
];

class BadgesScreen extends ConsumerWidget {
  const BadgesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: MediaQuery.sizeOf(context).width < 900
          ? AppBar(
              backgroundColor: AppColors.bgPrimary,
              title: const Text('Badges & Achievements'),
            )
          : null,
      body: userAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.accentPurple)),
        error: (_, __) => const SizedBox.shrink(),
        data: (user) {
          final userXp = user?.xp ?? 0;
          final earned =
              _allBadges.where((b) => userXp >= b.xpRequired).toList();
          final locked =
              _allBadges.where((b) => userXp < b.xpRequired).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary card
                GlassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        const Text('🏆', style: TextStyle(fontSize: 40)),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${earned.length} / ${_allBadges.length} earned',
                              style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${locked.length} badges remaining',
                              style: const TextStyle(
                                  color: AppColors.textSecondary, fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(),

                const SizedBox(height: 20),

                if (earned.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 12),
                    child: Text('Earned',
                        style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1)),
                  ),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.85,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: earned.length,
                    itemBuilder: (_, i) =>
                        _BadgeCard(badge: earned[i], isEarned: true, index: i),
                  ),
                  const SizedBox(height: 20),
                ],

                if (locked.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 12),
                    child: Text('Locked',
                        style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1)),
                  ),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.85,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: locked.length,
                    itemBuilder: (_, i) => _BadgeCard(
                        badge: locked[i],
                        isEarned: false,
                        index: i + earned.length),
                  ),
                ],

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  const _BadgeCard(
      {required this.badge, required this.isEarned, required this.index});
  final BadgeDefinition badge;
  final bool isEarned;
  final int index;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
        decoration: BoxDecoration(
          color: isEarned ? badge.color.withOpacity(0.1) : AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isEarned ? badge.color.withOpacity(0.3) : AppColors.border,
            width: isEarned ? 1.5 : 0.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ColorFiltered(
              colorFilter: isEarned
                  ? const ColorFilter.mode(
                      Colors.transparent, BlendMode.multiply)
                  : const ColorFilter.matrix([
                      0.2126,
                      0.7152,
                      0.0722,
                      0,
                      0,
                      0.2126,
                      0.7152,
                      0.0722,
                      0,
                      0,
                      0.2126,
                      0.7152,
                      0.0722,
                      0,
                      0,
                      0,
                      0,
                      0,
                      0.4,
                      0,
                    ]),
              child: Text(badge.emoji, style: const TextStyle(fontSize: 36)),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                badge.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isEarned ? AppColors.textPrimary : AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
              ),
            ),
            if (!isEarned) ...[
              const SizedBox(height: 2),
              Text(
                '${badge.xpRequired} XP',
                style:
                    const TextStyle(color: AppColors.textMuted, fontSize: 10),
              ),
            ],
          ],
        ),
      )
          .animate(delay: Duration(milliseconds: index * 40))
          .fadeIn()
          .scale(begin: const Offset(0.8, 0.8)),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(badge.emoji, style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 12),
            Text(badge.title,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(badge.description,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 14),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: badge.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isEarned ? '✅ Earned!' : '🔒 Requires ${badge.xpRequired} XP',
                style: TextStyle(
                    color: isEarned ? AppColors.accentGreen : badge.color,
                    fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
