// lib/features/home/presentation/widgets/streak_card.dart
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class StreakCard extends StatelessWidget {
  const StreakCard({super.key, required this.streak, required this.longestStreak});
  final int streak;
  final int longestStreak;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: streak > 0
            ? AppColors.streakGradient
            : const LinearGradient(colors: [AppColors.bgCard, AppColors.bgCard]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: streak > 0 ? AppColors.streakFire.withOpacity(0.4) : AppColors.border,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(streak > 0 ? '🔥' : '❄️', style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Text(
            '$streak',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: streak > 0 ? Colors.white : AppColors.textPrimary,
            ),
          ),
          Text(
            streak == 1 ? 'day streak' : 'day streak',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              color: streak > 0 ? Colors.white70 : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
