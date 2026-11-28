// Trách nhiệm file: Định nghĩa Theme Light & Dark theo phong cách Midnight Navy + Electric Royal Blue + Ice Surface.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';

class AppTheme {
  static const Color primaryColor = AppColors.p500;
  static const Color backgroundColor = AppColors.n0;
  static const Color surfaceColor = AppColors.n0;
  static const Color textPrimaryColor = AppColors.navy900;
  static const Color textSecondaryColor = AppColors.n600;
  static const Color errorColor = AppColors.error;
  static const Color successColor = AppColors.success;

  static final ThemeData lightTheme = _buildTheme(Brightness.light);
  static final ThemeData darkTheme = _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final bg = isDark ? AppColors.navy950 : AppColors.n0;
    final cardBg = isDark ? AppColors.navy800 : AppColors.n0;
    final subtleCard = isDark ? AppColors.navy700 : AppColors.n50;
    final textPrimary = isDark ? Colors.white : AppColors.navy900;
    final textSecondary = isDark ? const Color(0xFFB8BCD6) : AppColors.n600;
    final hairline = isDark ? AppColors.navy600 : AppColors.n100;
    final inputFill = isDark ? AppColors.navy700 : Colors.white;
    final primary = isDark ? AppColors.p300 : primaryColor;
    final onPrimary = isDark ? const Color(0xFF061840) : Colors.white;
    final error = isDark ? AppColors.errorOnDark : errorColor;
    final inputOutline = isDark ? const Color(0xFF7E83A8) : AppColors.n400;

    final scheme =
        ColorScheme.fromSeed(
          seedColor: primaryColor,
          brightness: brightness,
        ).copyWith(
          primary: primary,
          onPrimary: onPrimary,
          primaryContainer: isDark ? const Color(0xFF1F2B6B) : AppColors.p50,
          onPrimaryContainer: isDark ? Colors.white : AppColors.navy900,
          secondary: isDark ? const Color(0xFF3B4380) : AppColors.navy900,
          onSecondary: Colors.white,
          surface: cardBg,
          surfaceContainerLow: subtleCard,
          surfaceContainerHighest: isDark
              ? AppColors.navy700
              : const Color(0xFFEBEFF9),
          onSurface: textPrimary,
          onSurfaceVariant: textSecondary,
          error: error,
          onError: isDark ? const Color(0xFF560013) : Colors.white,
          outline: inputOutline,
          outlineVariant: hairline,
        );

    final baseText = isDark
        ? ThemeData.dark().textTheme
        : ThemeData.light().textTheme;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      focusColor: primary.withValues(alpha: 0.16),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
      checkboxTheme: CheckboxThemeData(
        materialTapTargetSize: MaterialTapTargetSize.padded,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        side: BorderSide(color: inputOutline, width: 1.8),
      ),
      scaffoldBackgroundColor: bg,
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          fontSize: 17.5,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          color: textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: isDark ? AppColors.navy800 : AppColors.n50,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: hairline, width: 0.8),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardBg,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cardBg,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.navy900,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 50),
          backgroundColor: primary,
          foregroundColor: onPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            letterSpacing: -0.1,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(0, 50),
          backgroundColor: primary,
          foregroundColor: onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          foregroundColor: primary,
          side: BorderSide(color: inputOutline, width: 1),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: primary,
          textStyle: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(color: hairline, thickness: 0.8),
      textTheme: baseText.copyWith(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.8,
          color: textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.6,
          color: textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          color: textPrimary,
        ),
        bodyLarge: TextStyle(fontSize: 15.5, height: 1.45, color: textPrimary),
        bodyMedium: TextStyle(fontSize: 14, height: 1.45, color: textPrimary),
        bodySmall: TextStyle(fontSize: 13, height: 1.4, color: textSecondary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: inputOutline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: inputOutline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: error, width: 2),
        ),
        errorMaxLines: 3,
        helperMaxLines: 3,
        errorStyle: TextStyle(color: error, fontSize: 13),
        hintStyle: TextStyle(color: textSecondary, fontSize: 14),
        floatingLabelStyle: TextStyle(
          color: primary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        labelStyle: TextStyle(
          color: textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      tooltipTheme: TooltipThemeData(
        waitDuration: const Duration(milliseconds: 400),
        textStyle: TextStyle(color: isDark ? AppColors.navy950 : Colors.white),
        decoration: BoxDecoration(
          color: isDark ? AppColors.p50 : AppColors.navy900,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: primary),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: cardBg,
        selectedIconTheme: IconThemeData(color: primary),
        unselectedIconTheme: IconThemeData(color: textSecondary),
        selectedLabelTextStyle: TextStyle(
          color: primary,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelTextStyle: TextStyle(color: textSecondary, fontSize: 14),
      ),
    );
  }
}
