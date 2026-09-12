import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Luminous Depth design tokens supplied with the Stitch reference.
///
/// The reference is intentionally dark-only. Both Material theme slots return
/// the same palette so switching the OS/theme preference never changes the
/// visual language away from the supplied design.
class AppColors {
  static const background = Color(0xFF0B1326);
  static const darkBackground = background;
  static const lightBackground = background;

  static const surfaceLowest = Color(0xFF060E20);
  static const surfaceLow = Color(0xFF131B2E);
  static const surface = Color(0xFF171F33);
  static const surfaceHigh = Color(0xFF222A3D);
  static const surfaceHighest = Color(0xFF2D3449);
  static const surfaceBright = Color(0xFF31394D);

  static const primary = Color(0xFF4EDEA3);
  static const primaryAlt = Color(0xFF10B981);
  static const primaryDark = Color(0xFF006C49);
  static const primaryLight = Color(0xFF173B32);

  static const secondary = Color(0xFFFFB690);
  static const tertiary = Color(0xFFFFB95F);
  static const accentBlue = secondary;
  static const champagne = tertiary;

  static const textPrimary = Color(0xFFDAE2FD);
  static const textSecondary = Color(0xFFBBCABF);
  static const ink = textPrimary;
  static const mutedInk = textSecondary;

  static const outline = Color(0xFF86948A);
  static const outlineVariant = Color(0xFF3C4A42);

  static const success = primary;
  static const error = Color(0xFFFFB4AB);
  static const warning = tertiary;
  static const info = Color(0xFF9CC8FF);

  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6FFBBE), Color(0xFF4EDEA3), Color(0xFF006C49)],
  );

  static const fabGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4EDEA3), Color(0xFFFFB95F)],
  );

  static const softGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x332D5A4D), Color(0x26171F33)],
  );

  static const glassFill = Color(0x99171F33); // rgba(23,31,51,.60)
  static const glassBorder = Color(0x1AFFFFFF); // white 10%
  static const glassHighlight = Color(0x2AFFFFFF);
}

class Appearance {
  static final mode = ValueNotifier<ThemeMode>(ThemeMode.dark);

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('appearance');
    mode.value = ThemeMode.values.firstWhere(
      (m) => m.name == stored,
      orElse: () => ThemeMode.dark,
    );
  }

  static Future<void> set(ThemeMode value) async {
    mode.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('appearance', value.name);
  }
}

class AppTheme {
  static ThemeData get lightTheme => build(Brightness.dark);
  static ThemeData get darkTheme => build(Brightness.dark);

  static ThemeData build(Brightness _) {
    const brightness = Brightness.dark;
    const background = AppColors.background;
    const surface = AppColors.surface;
    const ink = AppColors.textPrimary;
    const muted = AppColors.textSecondary;
    const border = AppColors.outlineVariant;

    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
      surface: surface,
      error: AppColors.error,
    ).copyWith(
      primary: AppColors.primary,
      onPrimary: const Color(0xFF003824),
      primaryContainer: AppColors.primaryAlt,
      onPrimaryContainer: const Color(0xFF00422B),
      secondary: AppColors.secondary,
      onSecondary: const Color(0xFF552100),
      tertiary: AppColors.tertiary,
      onTertiary: const Color(0xFF472A00),
      onSurface: ink,
      onSurfaceVariant: muted,
      surfaceContainerLowest: AppColors.surfaceLowest,
      surfaceContainerLow: AppColors.surfaceLow,
      surfaceContainer: AppColors.surface,
      surfaceContainerHigh: AppColors.surfaceHigh,
      surfaceContainerHighest: AppColors.surfaceHighest,
      outline: AppColors.outline,
      outlineVariant: border,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      fontFamily: 'Inter',
    );

    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        displaySmall: const TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.w700,
          letterSpacing: -1.6,
          height: 1.0,
          color: ink,
        ),
        headlineLarge: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          letterSpacing: -.32,
          height: 1.25,
          color: ink,
        ),
        headlineMedium: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: -.2,
          height: 1.25,
          color: ink,
        ),
        headlineSmall: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -.1,
          color: ink,
        ),
        titleLarge: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: ink,
        ),
        titleMedium: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: ink,
        ),
        bodyLarge: const TextStyle(fontSize: 16, height: 1.5, color: ink),
        bodyMedium: const TextStyle(fontSize: 14, height: 1.45, color: muted),
        bodySmall: const TextStyle(fontSize: 12, height: 1.4, color: muted),
        labelLarge: const TextStyle(
          fontFamily: 'Geist',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: .25,
          color: ink,
        ),
        labelMedium: const TextStyle(
          fontFamily: 'Geist',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: .6,
          color: muted,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background.withValues(alpha: .42),
        foregroundColor: ink,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: const TextStyle(
          color: ink,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(color: muted),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceLow.withValues(alpha: .94),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: const TextStyle(color: muted),
        floatingLabelStyle: const TextStyle(color: AppColors.primary, fontSize: 12),
        hintStyle: TextStyle(color: muted.withValues(alpha: .68)),
        prefixIconColor: muted,
        suffixIconColor: muted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: const Color(0xFF003824),
          minimumSize: const Size(48, 50),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          minimumSize: const Size(48, 50),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          side: const BorderSide(color: AppColors.glassBorder),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: muted,
          backgroundColor: AppColors.surfaceHigh.withValues(alpha: .45),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface.withValues(alpha: .72),
        indicatorColor: Colors.transparent,
        height: 68,
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontFamily: 'Geist',
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: states.contains(WidgetState.selected) ? AppColors.primary : muted,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 21,
            color: states.contains(WidgetState.selected) ? AppColors.primary : muted,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(color: border.withValues(alpha: .62), thickness: 1),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: EdgeInsets.fromLTRB(16, 0, 16, 18),
        contentTextStyle: TextStyle(color: ink),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceLow,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: AppColors.surfaceLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface.withValues(alpha: .68),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.glassBorder),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.surfaceLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        side: const BorderSide(color: AppColors.glassBorder),
        selectedColor: AppColors.primary.withValues(alpha: .16),
        labelStyle: const TextStyle(color: ink, fontWeight: FontWeight.w600),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.surfaceHighest,
        circularTrackColor: AppColors.surfaceHighest,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.fuchsia: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}
