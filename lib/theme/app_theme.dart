import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const background = Color(0xFF130E1B);
  static const surface = Color(0xFF1E1728);
  static const surfaceRaised = Color(0xFF2A2038);
  static const primary = Color(0xFFC5A3F1);
  static const primaryDeep = Color(0xFFA47BCD);
  static const accent = Color(0xFFB79ADD);
  static const textPrimary = Color(0xFFFAF6FF);
  static const textSecondary = Color(0xFFD1C6DE);
  static const outline = Color(0xFF4A3D5A);
}

abstract final class AppCardDecorations {
  static BoxDecoration get surface => BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: AppColors.outline.withValues(alpha: 0.8)),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF000000).withValues(alpha: 0.16),
        blurRadius: 16,
        offset: const Offset(0, 6),
      ),
    ],
  );

  static BoxDecoration get featured => BoxDecoration(
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [AppColors.surfaceRaised, AppColors.surface],
    ),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: AppColors.primary.withValues(alpha: 0.22)),
    boxShadow: [
      BoxShadow(
        color: AppColors.primaryDeep.withValues(alpha: 0.08),
        blurRadius: 20,
        offset: const Offset(0, 7),
      ),
    ],
  );
}

class AppTheme {
  const AppTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: Color(0xFF281637),
        secondary: AppColors.accent,
        onSecondary: Color(0xFF281C35),
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        outline: AppColors.outline,
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 34,
          fontWeight: FontWeight.w700,
          height: 1.12,
        ),
        titleLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 16,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
          height: 1.45,
        ),
        labelSmall: TextStyle(
          color: AppColors.accent,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: Color(0xFF49375E),
        elevation: 0,
        height: 76,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFF191322),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: Color(0xFF39284B),
        contentTextStyle: TextStyle(color: Color(0xFFFFFFFF)),
        behavior: SnackBarBehavior.floating,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shadowColor: const Color(0xFF000000).withValues(alpha: 0.16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: AppColors.outline.withValues(alpha: 0.8)),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.surfaceRaised,
      ),
    );
  }
}
