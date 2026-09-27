// lib/core/widgets/glass_card.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Glassmorphism card widget — blurred frosted-glass effect
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.border,
    this.gradient,
    this.blur = 10.0,
    this.opacity = 0.1,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final Border? border;
  final Gradient? gradient;
  final double blur;
  final double opacity;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(16);

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding ?? const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: radius,
              gradient: gradient ??
                  LinearGradient(
                    colors: [
                      Colors.white.withOpacity(opacity),
                      Colors.white.withOpacity(opacity * 0.5),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
              border: border ??
                  Border.all(
                    color: AppColors.borderGlass,
                    width: 1,
                  ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
