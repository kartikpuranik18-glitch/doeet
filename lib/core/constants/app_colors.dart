import 'package:flutter/material.dart';

/// Dooet visual system. Pink is reserved for the wordmark and small moments;
/// learning actions use an accessible academy blue.
class AppColors {
  AppColors._();

  static const Color brandPink = Color(0xFFE95D8A);
  static const Color primary = Color(0xFF1956D1);
  static const Color primaryLight = Color(0xFF3474EF);
  static const Color primaryDark = Color(0xFF102A63);
  static const Color secondary = Color(0xFF53637D);
  static const Color accent = brandPink;

  static const Color accentPurple = Color(0xFF6D4CDB);
  static const Color accentCyan = Color(0xFF11A9B8);
  static const Color accentGreen = Color(0xFF16885E);
  static const Color accentGold = xpGold;

  static const Color bg = Color(0xFFF7F9FC);
  static const Color bgPrimary = bg;
  static const Color bgCard = Color(0xFFFFFFFF);
  static const Color bgSurface = bgCard;
  static const Color bgElevated = Color(0xFFF0F5FF);
  static const Color bgGlass = Color(0xEDFFFFFF);

  static const Color textPrimary = Color(0xFF162033);
  static const Color textSecondary = Color(0xFF526178);
  static const Color textMuted = Color(0xFF8591A5);

  static const Color border = Color(0xFFE3E8F0);
  static const Color borderGlass = Color(0x334479E8);

  static const Color success = Color(0xFF1E9B69);
  static const Color warning = Color(0xFFE49A21);
  static const Color error = Color(0xFFD6455D);
  static const Color info = Color(0xFF3474EF);

  static const Color xpGold = Color(0xFFF2B84B);
  static const Color streakFire = Color(0xFFFF7A45);
  static const Color levelBadge = Color(0xFF7259CC);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF2866E1), Color(0xFF1745AD)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient brandGradient = primaryGradient;
  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFFF1F5FF), Color(0xFFFDF8FA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient cardGradient = LinearGradient(colors: [bgCard, bgCard]);
  static const LinearGradient streakGradient = LinearGradient(colors: [Color(0xFFFF9157), Color(0xFFFF684D)]);
  static const LinearGradient successGradient = LinearGradient(colors: [Color(0xFF2DB982), Color(0xFF14875D)]);
}
