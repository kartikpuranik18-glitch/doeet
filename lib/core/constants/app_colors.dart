// lib/core/constants/app_colors.dart
import 'package:flutter/material.dart';

/// Doeet Design System — light pink palette
class AppColors {
  AppColors._();

  // ── Brand ──────────────────────────────────────────
  static const Color primary = Color(0xFFD94F87);
  static const Color primaryLight = Color(0xFFE978A0);
  static const Color primaryDark = Color(0xFFB83268);
  static const Color secondary = Color(0xFFB84F87);
  static const Color accent = Color(0xFFEA6A91);

  // ── Alias for new screens ────────────────────────────
  static const Color accentPurple = primary;             // Electric violet alias
  static const Color accentCyan = Color(0xFFD889A8);
  static const Color accentGreen = secondary;            // Mint green alias
  static const Color accentGold = xpGold;                // Gold alias

  // ── Backgrounds ────────────────────────────────────
  static const Color bg = Color(0xFFFFF4F7);
  static const Color bgPrimary = bg;
  static const Color bgCard = Color(0xFFFFFFFF);
  static const Color bgSurface = bgCard;
  static const Color bgElevated = Color(0xFFFFE7EF);
  static const Color bgGlass = Color(0xCCFFFFFF);

  // ── Text ───────────────────────────────────────────
  static const Color textPrimary = Color(0xFF382632);
  static const Color textSecondary = Color(0xFF765D6B);
  static const Color textMuted = Color(0xFFA48C99);

  // ── Borders ────────────────────────────────────────
  static const Color border = Color(0xFFF0D0DC);
  static const Color borderGlass = Color(0x55D94F87);

  // ── Semantic ───────────────────────────────────────
  static const Color success = Color(0xFF32D583);
  static const Color warning = Color(0xFFFFB74D);
  static const Color error = Color(0xFFFF5252);
  static const Color info = Color(0xFF64B5F6);

  // ── Gamification ───────────────────────────────────
  static const Color xpGold = Color(0xFFFFD700);
  static const Color streakFire = Color(0xFFFF6B35);
  static const Color levelBadge = Color(0xFF9C27B0);

  // ── Gradients ──────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Alias used across new screens
  static const LinearGradient brandGradient = primaryGradient;

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFFFFE5EF), Color(0xFFFFF4F7), Color(0xFFFAD8E5)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFFFEDF3)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient streakGradient = LinearGradient(
    colors: [Color(0xFFFF6B35), Color(0xFFFF4500)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF00D4AA), Color(0xFF00B890)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
