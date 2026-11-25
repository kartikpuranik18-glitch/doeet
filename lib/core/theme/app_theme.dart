import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';

class AppTheme {
  AppTheme._();

  static TextTheme get _textTheme => GoogleFonts.interTextTheme(const TextTheme(
        displayLarge: TextStyle(fontSize: 46, fontWeight: FontWeight.w800, letterSpacing: -1.8, color: AppColors.textPrimary),
        displayMedium: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: -1.2, color: AppColors.textPrimary),
        headlineLarge: TextStyle(fontSize: 29, fontWeight: FontWeight.w700, letterSpacing: -0.8, color: AppColors.textPrimary),
        headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.5, color: AppColors.textPrimary),
        headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        bodyLarge: TextStyle(fontSize: 16, height: 1.55, color: AppColors.textPrimary),
        bodyMedium: TextStyle(fontSize: 14, height: 1.5, color: AppColors.textSecondary),
        bodySmall: TextStyle(fontSize: 12, height: 1.45, color: AppColors.textMuted),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
      ));

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.bg,
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.accentPurple,
          error: AppColors.error,
          surface: AppColors.bgCard,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: AppColors.textPrimary,
          onError: Colors.white,
        ),
        textTheme: _textTheme,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.bgCard,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: GoogleFonts.inter(fontSize: 19, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          iconTheme: const IconThemeData(color: AppColors.textPrimary),
          systemOverlayStyle: const SystemUiOverlayStyle(statusBarColor: Colors.transparent, statusBarIconBrightness: Brightness.dark),
        ),
        cardTheme: CardTheme(
          color: AppColors.bgCard,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.border)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.bgCard,
          isDense: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.7)),
          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.error)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          hintStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14),
          labelStyle: GoogleFonts.inter(color: AppColors.textSecondary),
        ),
        filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 46),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
        )),
        elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 46),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        )),
        outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(0, 46),
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
        )),
        textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
        )),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.bgElevated,
          labelStyle: GoogleFonts.inter(color: AppColors.primaryDark, fontSize: 12, fontWeight: FontWeight.w600),
          side: BorderSide.none,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1, space: 1),
      );
}
