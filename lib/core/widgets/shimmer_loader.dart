// lib/core/widgets/shimmer_loader.dart
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../constants/app_colors.dart';

/// Shimmer loading skeleton for cards and list tiles
class ShimmerLoader extends StatelessWidget {
  const ShimmerLoader({
    super.key,
    required this.child,
  });

  final Widget child;

  /// Static factory: shimmer card of a given height
  static Widget card({double height = 120, double? width}) {
    return ShimmerLoader(
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: AppColors.bgElevated,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.bgElevated,
      highlightColor: AppColors.bgCard,
      child: child,
    );
  }
}

/// Pre-built shimmer skeletons
class ShimmerCard extends StatelessWidget {
  const ShimmerCard({super.key, this.height = 120});
  final double height;

  @override
  Widget build(BuildContext context) {
    return ShimmerLoader(
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: AppColors.bgElevated,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

class ShimmerListTile extends StatelessWidget {
  const ShimmerListTile({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoader(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.bgElevated,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppColors.bgElevated,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 12,
                    width: 100,
                    decoration: BoxDecoration(
                      color: AppColors.bgElevated,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
