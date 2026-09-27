// lib/features/home/presentation/widgets/daily_goal_ring.dart
import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../../../../core/constants/app_colors.dart';

class DailyGoalRing extends StatelessWidget {
  const DailyGoalRing({
    super.key,
    required this.minutesWatched,
    required this.goalMinutes,
  });
  final int minutesWatched;
  final int goalMinutes;

  @override
  Widget build(BuildContext context) {
    final pct = goalMinutes > 0
        ? (minutesWatched / goalMinutes).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularPercentIndicator(
            radius: 28,
            lineWidth: 5,
            percent: pct,
            animation: true,
            animationDuration: 1000,
            progressColor: AppColors.secondary,
            backgroundColor: AppColors.bgElevated,
            circularStrokeCap: CircularStrokeCap.round,
            center: Text(
              '${(pct * 100).round()}%',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.secondary,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${minutesWatched}m',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            'of ${goalMinutes}m',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
