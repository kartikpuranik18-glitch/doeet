// lib/core/constants/app_colors.dart
import 'package:flutter/material.dart';

/// Dooet Design System — warm white with a restrained pink brand mark.
class AppColors {
  AppColors._();

  // ── Brand ──────────────────────────────────────────
  static const Color brandPink = Color(0xFFE56F96);
  static const Color primary = Color(0xFF262124);
  static const Color primaryLight = Color(0xFF51494D);
  static const Color primaryDark = Color(0xFF171315);
  static const Color secondary = Color(0xFF6A6065);
  static const Color accent = brandPink;

  // ── Alias for new screens ────────────────────────────
  static const Color accentPurple = primary;
  static const Color accentCyan = Color(0xFF8C8186);
  static const Color accentGreen = Color(0xFF2F8B68);
  static const Color accentGold = xpGold;                // Gold alias

  // ── Backgrounds ────────────────────────────────────
  static const Color bg = Color(0xFFFFFCFD);
  static const Color bgPrimary = bg;
  static const Color bgCard = Color(0xFFFFFFFF);
  static const Color bgSurface = bgCard;
  static const Color bgElevated = Color(0xFFFFF7F9);
  static const Color bgGlass = Color(0xCCFFFFFF);

  // ── Text ───────────────────────────────────────────
  static const Color textPrimary = Color(0xFF262124);
  static const Color textSecondary = Color(0xFF665D62);
  static const Color textMuted = Color(0xFF968B91);

  // ── Borders ────────────────────────────────────────
  static const Color border = Color(0xFFEEE7EA);
  static const Color borderGlass = Color(0x22E56F96);

  // ── Semantic ───────────────────────────────────────
  static const Color success = Color(0xFF32D583);
  static const Color warning = Color(0xFFFFB74D);
  static const Color error = Color(0xFFFF5252);
  static const Color info = Color(0xFF64B5F6);

  // ── Gamification ───────────────────────────────────
  static const Color xpGold = Color(0xFFFFD700);
  static const Color streakFire = Color(0xFFFF6B35);
  static const Color levelBadge = Color(0xFF9C27B0);

  // Legacy names retained so established UI widgets keep compiling. They are
  // deliberately flat to avoid a gradient-heavy visual system.
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Alias used across new screens
  static const LinearGradient brandGradient = primaryGradient;

  static const LinearGradient heroGradient = LinearGradient(
    colors: [bg, bg, bg],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [bgCard, bgCard],
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
