import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppColors {
  static const primary = Color(0xFF6C55EA);
  static const primaryAlt = Color(0xFF8168F6);
  static const primaryDark = Color(0xFF2B1E70);
  static const accentBlue = Color(0xFF5A8DEE);
  static const champagne = Color(0xFFD8B46D);
  static const primaryLight = Color(0xFFF0EDFF);
  static const lightBackground = Color(0xFFF7F8FC);
  static const darkBackground = Color(0xFF0E1220);
  static const background = lightBackground;
  static const surface = Colors.white;
  static const textPrimary = Color(0xFF201F36);
  static const textSecondary = Color(0xFF6F6A86);
  static const success = Color(0xFF12C98A);
  static const error = Color(0xFFFF4B55);
  static const warning = Color(0xFFFFA21A);
  static const info = Color(0xFF5A8DEE);
  static const ink = Color(0xFF20202A);
  static const mutedInk = Color(0xFF737787);

  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7B66F4), Color(0xFF6C55EA), Color(0xFF5B43DB)],
  );

  static const softGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF5F2FF), Color(0xFFF0F4FF)],
  );
}

class Appearance {
  static final mode = ValueNotifier<ThemeMode>(ThemeMode.system);

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('appearance');
    mode.value = ThemeMode.values.firstWhere(
      (m) => m.name == stored,
      orElse: () => ThemeMode.system,
    );
  }

  static Future<void> set(ThemeMode value) async {
    mode.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('appearance', value.name);
  }
}

class AppTheme {
  static ThemeData get lightTheme => build(Brightness.light);
  static ThemeData get darkTheme => build(Brightness.dark);

  static ThemeData build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final background = dark ? AppColors.darkBackground : AppColors.lightBackground;
    final surface = dark ? const Color(0xFF171D2D) : Colors.white;
    final elevated = dark ? const Color(0xFF20283C) : const Color(0xFFFCFCFF);
    final ink = dark ? const Color(0xFFF5F3FF) : AppColors.textPrimary;
    final muted = dark ? const Color(0xFFB9B5CC) : AppColors.textSecondary;
    final border = dark ? const Color(0xFF30384E) : const Color(0xFFE7E4F1);
    final primary = dark ? const Color(0xFFB8A7FF) : AppColors.primary;

    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
      surface: surface,
      error: dark ? const Color(0xFFFF9BAD) : AppColors.error,
    ).copyWith(
      primary: primary,
      secondary: dark ? const Color(0xFF86C5FF) : AppColors.accentBlue,
      onSurface: ink,
      onSurfaceVariant: muted,
      surfaceContainerHighest: elevated,
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
    );

    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        displaySmall: TextStyle(
          fontSize: 38,
          fontWeight: FontWeight.w900,
          letterSpacing: -1.6,
          height: 1.03,
          color: ink,
        ),
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w900,
          letterSpacing: -1.25,
          height: 1.08,
          color: ink,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          letterSpacing: -.7,
          height: 1.12,
          color: ink,
        ),
        headlineSmall: TextStyle(
          fontSize: 23,
          fontWeight: FontWeight.w800,
          letterSpacing: -.35,
          color: ink,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -.2,
          color: ink,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: ink,
        ),
        bodyLarge: TextStyle(fontSize: 16, height: 1.5, color: ink),
        bodyMedium: TextStyle(fontSize: 14, height: 1.5, color: muted),
        labelLarge: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background.withOpacity(.94),
        foregroundColor: ink,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: ink,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -.25,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? const Color(0xFF1C2335) : Colors.white.withOpacity(.92),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
        labelStyle: TextStyle(color: muted),
        hintStyle: TextStyle(color: muted.withOpacity(.78)),
        prefixIconColor: muted,
        suffixIconColor: muted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(48, 54),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 52),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          side: BorderSide(color: border),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: dark ? const Color(0xFF151B2B) : Colors.white.withOpacity(.96),
        indicatorColor: dark ? const Color(0xFF393052) : AppColors.primaryLight,
        height: 72,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
          fontSize: 12,
          fontWeight: states.contains(WidgetState.selected) ? FontWeight.w800 : FontWeight.w600,
          color: states.contains(WidgetState.selected) ? primary : muted,
        )),
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
        contentTextStyle: TextStyle(color: ink),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: border),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        side: BorderSide(color: border),
        selectedColor: dark ? const Color(0xFF373050) : AppColors.primaryLight,
        labelStyle: TextStyle(color: ink, fontWeight: FontWeight.w700),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: border,
        circularTrackColor: border,
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
