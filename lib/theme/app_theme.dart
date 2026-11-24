import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static Brightness _brightness = Brightness.light;

  static void setBrightness(Brightness brightness) {
    _brightness = brightness;
  }

  static _AppPalette get _current =>
      _brightness == Brightness.dark ? _darkPalette : _lightPalette;

  static bool get isDark => _brightness == Brightness.dark;

  static Color get background => _current.background;
  static Color get surface => _current.surface;
  static Color get surfaceRaised => _current.surfaceRaised;
  static Color get brand => _current.brand;
  static Color get primary => _current.primary;
  static Color get primaryAction => _current.primaryAction;
  static Color get actionForeground => _current.actionForeground;
  static Color get primaryDeep => _current.primaryDeep;
  static Color get accent => _current.accent;
  static Color get textPrimary => _current.textPrimary;
  static Color get textSecondary => _current.textSecondary;
  static Color get outline => _current.outline;
  static Color get positive => _current.positive;
  static Color get negative => _current.negative;
  static Color get warning => _current.warning;
  static List<Color> get chartPalette => _current.chartPalette;
}

class _AppPalette {
  const _AppPalette({
    required this.background,
    required this.surface,
    required this.surfaceRaised,
    required this.brand,
    required this.primary,
    required this.primaryAction,
    required this.actionForeground,
    required this.primaryDeep,
    required this.accent,
    required this.textPrimary,
    required this.textSecondary,
    required this.outline,
    required this.positive,
    required this.negative,
    required this.warning,
    required this.chartPalette,
  });

  final Color background;
  final Color surface;
  final Color surfaceRaised;
  final Color brand;
  final Color primary;
  final Color primaryAction;
  final Color actionForeground;
  final Color primaryDeep;
  final Color accent;
  final Color textPrimary;
  final Color textSecondary;
  final Color outline;
  final Color positive;
  final Color negative;
  final Color warning;
  final List<Color> chartPalette;
}

const _lightPalette = _AppPalette(
  background: Color(0xFFFFF8EF),
  surface: Color(0xFFFFFFFF),
  surfaceRaised: Color(0xFFF8EEE2),
  brand: Color(0xFF5B2A86),
  primary: Color(0xFF5B2A86),
  primaryAction: Color(0xFF5B2A86),
  actionForeground: Color(0xFFFFFFFF),
  primaryDeep: Color(0xFF5B2A86),
  accent: Color(0xFFF2994A),
  textPrimary: Color(0xFF2B1E36),
  textSecondary: Color(0xFF6E6077),
  outline: Color(0xFF9C8F80),
  positive: Color(0xFF237A50),
  negative: Color(0xFFC03636),
  warning: Color(0xFF8A5300),
  chartPalette: [
    Color(0xFF5B2A86),
    Color(0xFFF2994A),
    Color(0xFFE0B12E),
    Color(0xFFB48AD8),
    Color(0xFF8C5A3C),
    Color(0xFFE8A598),
    Color(0xFF7A6E86),
  ],
);

const _darkPalette = _AppPalette(
  background: Color(0xFF1C1625),
  surface: Color(0xFF271F33),
  surfaceRaised: Color(0xFF211A2C),
  brand: Color(0xFF3A2B52),
  primary: Color(0xFFC9A7F0),
  primaryAction: Color(0xFFC9A7F0),
  actionForeground: Color(0xFF1C1625),
  primaryDeep: Color(0xFF3A2B52),
  accent: Color(0xFFF2A766),
  textPrimary: Color(0xFFFFF4E6),
  textSecondary: Color(0xFFC4B6CF),
  outline: Color(0xFF7E6F8C),
  positive: Color(0xFF6FD3A0),
  negative: Color(0xFFFF8C82),
  warning: Color(0xFFF6C744),
  chartPalette: [
    Color(0xFFC9A7F0),
    Color(0xFFF2A766),
    Color(0xFF6FD3A0),
    Color(0xFFF6C744),
    Color(0xFFFF8C82),
    Color(0xFF87C8F8),
    Color(0xFFF0A6E5),
    Color(0xFFB5E4A5),
  ],
);

abstract final class AppSpacing {
  static const pageHorizontal = 16.0;
  static const pageHorizontalWide = 32.0;
  static const pageTop = 4.0;
  static const section = 22.0;
  static const card = 16.0;
  static const compact = 12.0;
}

abstract final class AppRadii {
  static const small = 14.0;
  static const medium = 20.0;
  static const large = 24.0;
  static const pill = 999.0;
}

abstract final class AppCardDecorations {
  static BoxDecoration get surface => surfaceWithBorder();

  static BoxDecoration surfaceWithBorder({Color? borderColor}) => BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(AppRadii.medium),
    border: Border.all(
      color:
          borderColor ??
          (AppColors.isDark ? AppColors.outline : Colors.transparent),
    ),
    boxShadow: AppColors.isDark
        ? const []
        : [
            BoxShadow(
              color: AppColors.brand.withValues(alpha: 0.06),
              blurRadius: 2,
            ),
            BoxShadow(
              color: AppColors.brand.withValues(alpha: 0.07),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
  );

  static BoxDecoration get featured => surfaceWithBorder();
}

class AppTheme {
  const AppTheme._();

  static ThemeData get darkTheme {
    AppColors.setBrightness(Brightness.dark);
    final scheme = ColorScheme.dark(
      primary: AppColors.primaryAction,
      onPrimary: AppColors.actionForeground,
      secondary: AppColors.accent,
      onSecondary: AppColors.background,
      error: AppColors.negative,
      onError: AppColors.background,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      outline: AppColors.outline,
    );
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.small),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'Inter',
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.surface,
      dividerColor: AppColors.outline.withValues(alpha: 0.55),
      iconTheme: IconThemeData(color: AppColors.primary),
      textTheme: TextTheme(
        displaySmall: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 30,
          fontWeight: FontWeight.w700,
          height: 1.15,
          fontFamily: 'Nunito',
        ),
        headlineMedium: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 32,
          fontWeight: FontWeight.w700,
          height: 1.15,
          fontFamily: 'Nunito',
        ),
        headlineSmall: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 26,
          fontWeight: FontWeight.w700,
          height: 1.2,
          fontFamily: 'Nunito',
        ),
        titleLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          height: 1.25,
          fontFamily: 'Nunito',
        ),
        titleMedium: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          height: 1.3,
          fontFamily: 'Nunito',
        ),
        titleSmall: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          height: 1.35,
          fontFamily: 'Nunito',
        ),
        bodyLarge: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 16,
          height: 1.5,
          fontFamily: 'Inter',
        ),
        bodyMedium: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
          height: 1.45,
          fontFamily: 'Inter',
        ),
        bodySmall: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          height: 1.4,
          fontFamily: 'Inter',
        ),
        labelLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          fontFamily: 'Inter',
        ),
        labelSmall: TextStyle(
          color: AppColors.accent,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
          fontFamily: 'Inter',
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primaryAction.withValues(alpha: 0.28),
        elevation: 0,
        height: 84,
        labelTextStyle: const WidgetStatePropertyAll(
          TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: AppColors.primary,
        textColor: AppColors.textPrimary,
        minVerticalPadding: 8,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceRaised,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        hintStyle: TextStyle(color: AppColors.textSecondary),
        labelStyle: TextStyle(color: AppColors.textSecondary),
        floatingLabelStyle: TextStyle(color: AppColors.accent),
        prefixIconColor: AppColors.primary,
        suffixIconColor: AppColors.textSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.small),
          borderSide: BorderSide(color: AppColors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.small),
          borderSide: BorderSide(
            color: AppColors.outline.withValues(alpha: 0.8),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.small),
          borderSide: BorderSide(color: AppColors.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.small),
          borderSide: BorderSide(color: AppColors.negative),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.small),
          borderSide: BorderSide(color: AppColors.negative, width: 1.6),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primaryAction,
          foregroundColor: AppColors.actionForeground,
          minimumSize: const Size(48, 52),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(48, 52),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          side: BorderSide(color: AppColors.outline),
          shape: buttonShape,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          minimumSize: const Size(48, 44),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: buttonShape,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(48, 48),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryAction,
        foregroundColor: AppColors.actionForeground,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadii.medium)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.large),
          side: BorderSide(color: AppColors.outline.withValues(alpha: 0.55)),
        ),
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 19,
          fontWeight: FontWeight.w800,
          fontFamily: 'Nunito',
        ),
        contentTextStyle: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
          height: 1.45,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: AppColors.surface,
        showDragHandle: true,
        dragHandleColor: AppColors.outline,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadii.large),
          ),
        ),
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(AppColors.surfaceRaised),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.small),
              side: BorderSide(color: AppColors.outline),
            ),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceRaised,
        contentTextStyle: TextStyle(color: AppColors.textPrimary, fontSize: 14),
        behavior: SnackBarBehavior.floating,
        showCloseIcon: true,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.medium),
          side: BorderSide(
            color: AppColors.isDark ? AppColors.outline : Colors.transparent,
          ),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.surfaceRaised,
        circularTrackColor: AppColors.surfaceRaised,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          foregroundColor: AppColors.textSecondary,
          selectedForegroundColor: AppColors.textPrimary,
          selectedBackgroundColor: AppColors.primaryAction.withValues(
            alpha: 0.32,
          ),
          side: BorderSide(color: AppColors.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.small),
          ),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          borderRadius: BorderRadius.all(Radius.circular(AppRadii.small)),
        ),
        textStyle: TextStyle(color: AppColors.textPrimary, fontSize: 12),
      ),
    );
  }

  static ThemeData get lightTheme {
    final dark = darkTheme;
    AppColors.setBrightness(Brightness.light);
    final scheme = ColorScheme.light(
      primary: AppColors.primaryAction,
      onPrimary: Colors.white,
      secondary: AppColors.accent,
      onSecondary: AppColors.textPrimary,
      error: AppColors.negative,
      onError: Colors.white,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      outline: AppColors.outline,
    );
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.small),
    );
    final outlineBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.small),
      borderSide: BorderSide(color: AppColors.outline),
    );
    final textTheme = TextTheme(
      displaySmall: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 30,
        fontWeight: FontWeight.w800,
        height: 1.15,
        fontFamily: 'Nunito',
      ),
      headlineMedium: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 32,
        fontWeight: FontWeight.w800,
        height: 1.15,
        fontFamily: 'Nunito',
      ),
      headlineSmall: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 26,
        fontWeight: FontWeight.w800,
        height: 1.2,
        fontFamily: 'Nunito',
      ),
      titleLarge: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w800,
        height: 1.25,
        fontFamily: 'Nunito',
      ),
      titleMedium: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w700,
        height: 1.3,
        fontFamily: 'Nunito',
      ),
      titleSmall: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w700,
        height: 1.35,
        fontFamily: 'Nunito',
      ),
      bodyLarge: TextStyle(
        color: AppColors.textSecondary,
        fontSize: 16,
        height: 1.5,
        fontFamily: 'Inter',
      ),
      bodyMedium: TextStyle(
        color: AppColors.textSecondary,
        fontSize: 14,
        height: 1.45,
        fontFamily: 'Inter',
      ),
      bodySmall: TextStyle(
        color: AppColors.textSecondary,
        fontSize: 12,
        height: 1.4,
        fontFamily: 'Inter',
      ),
      labelLarge: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        fontFamily: 'Inter',
      ),
      labelSmall: TextStyle(
        color: AppColors.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
        fontFamily: 'Inter',
      ),
    );

    return dark.copyWith(
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.surface,
      dividerColor: const Color(0xFFEFE3D3),
      iconTheme: const IconThemeData(color: Color(0xFF5B2A86)),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: const Color(0xFFEFE4F7),
        elevation: 0,
        height: 84,
        labelTextStyle: const WidgetStatePropertyAll(
          TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: AppColors.primary,
        textColor: AppColors.textPrimary,
        minVerticalPadding: 8,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        hintStyle: TextStyle(color: AppColors.textSecondary),
        labelStyle: TextStyle(color: AppColors.textSecondary),
        floatingLabelStyle: TextStyle(color: AppColors.primary),
        prefixIconColor: AppColors.primary,
        suffixIconColor: AppColors.textSecondary,
        border: outlineBorder,
        enabledBorder: outlineBorder,
        focusedBorder: outlineBorder.copyWith(
          borderSide: BorderSide(color: AppColors.primary, width: 1.6),
        ),
        errorBorder: outlineBorder.copyWith(
          borderSide: BorderSide(color: AppColors.negative),
        ),
        focusedErrorBorder: outlineBorder.copyWith(
          borderSide: BorderSide(color: AppColors.negative, width: 1.6),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primaryAction,
          foregroundColor: Colors.white,
          minimumSize: const Size(48, 52),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(48, 52),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          side: BorderSide(color: AppColors.outline),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(48, 48),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryAction,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.medium),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.large),
          side: BorderSide(color: AppColors.outline.withValues(alpha: 0.55)),
        ),
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
          height: 1.45,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: AppColors.surface,
        showDragHandle: true,
        dragHandleColor: AppColors.outline,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadii.large),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceRaised,
        contentTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
        ),
        behavior: SnackBarBehavior.floating,
        showCloseIcon: true,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.medium),
          side: BorderSide(
            color: AppColors.isDark ? AppColors.outline : Colors.transparent,
          ),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.surfaceRaised,
        circularTrackColor: AppColors.surfaceRaised,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          foregroundColor: AppColors.textSecondary,
          selectedForegroundColor: AppColors.textPrimary,
          selectedBackgroundColor: const Color(0xFFEFE4F7),
          side: BorderSide(color: AppColors.outline),
          shape: buttonShape,
        ),
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(AppColors.surfaceRaised),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.small),
              side: BorderSide(color: AppColors.outline),
            ),
          ),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          borderRadius: const BorderRadius.all(
            Radius.circular(AppRadii.small),
          ),
        ),
        textStyle: TextStyle(color: AppColors.textPrimary, fontSize: 12),
      ),
    );
  }
}
