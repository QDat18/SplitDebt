import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_dimensions.dart';

export 'app_colors.dart';
export 'app_typography.dart';
export 'app_dimensions.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.n50,
      colorScheme: const ColorScheme.light(
        primary: AppColors.p500,
        primaryContainer: AppColors.p100,
        secondary: AppColors.p700,
        surface: AppColors.n0,
        error: AppColors.error,
        onPrimary: AppColors.n0,
        onSurface: AppColors.n800,
      ),
      textTheme: TextTheme(
        displayLarge: AppTypography.display,
        headlineLarge: AppTypography.h1,
        headlineMedium: AppTypography.h2,
        headlineSmall: AppTypography.h3,
        titleLarge: AppTypography.title,
        bodyLarge: AppTypography.bodyLarge,
        bodyMedium: AppTypography.bodyMedium,
        bodySmall: AppTypography.bodySmall,
        labelLarge: AppTypography.label,
        labelSmall: AppTypography.caption,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.n0,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.s16,
          vertical: AppDimensions.s16,
        ),
        border: OutlineInputBorder(
          borderRadius: AppDimensions.radius12,
          borderSide: const BorderSide(color: AppColors.n300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppDimensions.radius12,
          borderSide: const BorderSide(color: AppColors.n200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppDimensions.radius12,
          borderSide: const BorderSide(color: AppColors.p500, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppDimensions.radius12,
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.p500,
          foregroundColor: AppColors.n0,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: AppDimensions.radius16),
          elevation: 0,
          textStyle: AppTypography.title.copyWith(color: AppColors.n0),
        ),
      ),
      cardTheme: CardTheme(
        color: AppColors.n0,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppDimensions.radius16),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.n900,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.p400,
        primaryContainer: AppColors.p800,
        secondary: AppColors.p300,
        surface: AppColors.n800,
        error: AppColors.error,
        onPrimary: AppColors.n0,
        onSurface: AppColors.n0,
      ),
      textTheme: TextTheme(
        displayLarge: AppTypography.display.copyWith(color: AppColors.n0),
        headlineLarge: AppTypography.h1.copyWith(color: AppColors.n0),
        headlineMedium: AppTypography.h2.copyWith(color: AppColors.n0),
        headlineSmall: AppTypography.h3.copyWith(color: AppColors.n0),
        titleLarge: AppTypography.title.copyWith(color: AppColors.n0),
        bodyLarge: AppTypography.bodyLarge.copyWith(color: AppColors.n100),
        bodyMedium: AppTypography.bodyMedium.copyWith(color: AppColors.n300),
        bodySmall: AppTypography.bodySmall.copyWith(color: AppColors.n400),
        labelLarge: AppTypography.label.copyWith(color: AppColors.n0),
        labelSmall: AppTypography.caption.copyWith(color: AppColors.n400),
      ),
    );
  }
}