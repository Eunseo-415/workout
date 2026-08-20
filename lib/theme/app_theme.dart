import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Broadsheet 디자인 시스템 토큰 (`styles.css`의 `:root`를 그대로 옮김).
abstract final class AppColors {
  static const bg = Color(0xFFF3F2F2);
  static const surface = Color(0xFFEAE9E9);
  static const text = Color(0xFF201E1D);

  static const accent = Color(0xFF0088B0);
  static const accent100 = Color(0xFFE9F8FF);
  static const accent600 = Color(0xFF1186AC);
  static const accent700 = Color(0xFF006786);
  static const accent800 = Color(0xFF004961);

  static final divider = text.withValues(alpha: 0.16);
  static final textMuted65 = text.withValues(alpha: 0.65);
  static final textMuted60 = text.withValues(alpha: 0.60);
  static final textMuted55 = text.withValues(alpha: 0.55);
  static final textMuted50 = text.withValues(alpha: 0.50);
}

abstract final class AppSpacing {
  static const s1 = 5.0;
  static const s2 = 10.0;
  static const s3 = 15.0;
  static const s4 = 20.0;
  static const s6 = 30.0;
  static const s8 = 40.0;
}

abstract final class AppRadius {
  static const sm = 1.0;
  static const md = 2.0;
  static const lg = 4.0;
}

ThemeData buildAppTheme() {
  final base = ThemeData(useMaterial3: true);
  final serifTextTheme = GoogleFonts.sourceSerif4TextTheme(base.textTheme)
      .apply(bodyColor: AppColors.text, displayColor: AppColors.text);

  return base.copyWith(
    scaffoldBackgroundColor: AppColors.bg,
    textTheme: serifTextTheme,
    colorScheme: base.colorScheme.copyWith(
      primary: AppColors.accent,
      surface: AppColors.bg,
      onSurface: AppColors.text,
    ),
    dividerColor: AppColors.divider,
    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      filled: true,
      fillColor: AppColors.surface,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      hintStyle: GoogleFonts.sourceSerif4(color: AppColors.textMuted65),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: AppColors.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: AppColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.accent),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.bg,
        disabledBackgroundColor: AppColors.accent.withValues(alpha: 0.45),
        textStyle: GoogleFonts.sourceSerif4(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        padding: const EdgeInsets.symmetric(vertical: 14),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.text,
        textStyle: GoogleFonts.sourceSerif4(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
    ),
    iconTheme: const IconThemeData(color: AppColors.text),
  );
}
