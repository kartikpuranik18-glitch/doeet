// lib/features/home/presentation/widgets/weekly_chart.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../home_provider.dart';

class WeeklyChart extends ConsumerWidget {
  const WeeklyChart({super.key});

  List<_DayStat> _getLast7Days(List<DailyStats> stats) {
    final today = DateTime.now();
    return List.generate(7, (i) {
      final day = today.subtract(Duration(days: 6 - i));
      final stat = stats.cast<DailyStats?>().firstWhere(
            (item) => item != null &&
                item.date.year == day.year &&
                item.date.month == day.month &&
                item.date.day == day.day,
            orElse: () => null,
          );
      return _DayStat(
        label: DateFormat('E').format(day).substring(0, 1),
        minutes: stat?.minutesWatched ?? 0,
        isToday: i == 6,
      );
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(weeklyStatsProvider).maybeWhen(
          data: (value) => value,
          orElse: () => const <DailyStats>[],
        );
    final days = _getLast7Days(stats);
    final maxY = days.map((d) => d.minutes).reduce((a, b) => a > b ? a : b);

    return Container(
      height: 160,
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: BarChart(
        BarChartData(
          maxY: maxY > 0 ? maxY.toDouble() + 10 : 60,
          minY: 0,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                const FlLine(color: AppColors.border, strokeWidth: 0.5),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= days.length) return const SizedBox();
                  final d = days[idx];
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      d.label,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: d.isToday ? FontWeight.w700 : FontWeight.w400,
                        color: d.isToday ? AppColors.primary : AppColors.textMuted,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: days.asMap().entries.map((e) {
            final i = e.key;
            final d = e.value;
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: d.minutes > 0 ? d.minutes.toDouble() : 2,
                  width: 16,
                  borderRadius: BorderRadius.circular(6),
                  gradient: d.isToday
                      ? AppColors.primaryGradient
                      : LinearGradient(
                          colors: [
                            AppColors.primary.withOpacity(0.4),
                            AppColors.primary.withOpacity(0.2),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                ),
              ],
            );
          }).toList(),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => AppColors.bgElevated,
              getTooltipItem: (group, groupIdx, rod, rodIdx) {
                final d = days[group.x];
                return BarTooltipItem(
                  '${d.minutes}m',
                  const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                );
              },
            ),
          ),
        ),
        swapAnimationDuration: const Duration(milliseconds: 800),
        swapAnimationCurve: Curves.easeInOut,
      ),
    );
  }
}

class _DayStat {
  final String label;
  final int minutes;
  final bool isToday;
  const _DayStat({required this.label, required this.minutes, this.isToday = false});
}
