import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// kiểu chữ cho app
class AppTypography {
  static TextStyle get display => GoogleFonts.inter(
        fontSize: 32,
        height: 40 / 32,
        fontWeight: FontWeight.w800, // Bold (800)
        color: AppColors.n800,
      );

  static TextStyle get h1 => GoogleFonts.inter(
        fontSize: 28,
        height: 36 / 28,
        fontWeight: FontWeight.w800, // Bold (800)
        color: AppColors.n800,
      );

  static TextStyle get h2 => GoogleFonts.inter(
        fontSize: 24,
        height: 32 / 24,
        fontWeight: FontWeight.w700, // Bold (700)
        color: AppColors.n800,
      );

  static TextStyle get h3 => GoogleFonts.inter(
        fontSize: 20,
        height: 28 / 20,
        fontWeight: FontWeight.w700, // Bold (700)
        color: AppColors.n800,
      );

  static TextStyle get title => GoogleFonts.inter(
        fontSize: 18,
        height: 24 / 18,
        fontWeight: FontWeight.w600, // SemiBold (600)
        color: AppColors.n800,
      );

  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 16,
        height: 24 / 16,
        fontWeight: FontWeight.w400, // Regular (400)
        color: AppColors.n800,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w400, // Regular (400)
        color: AppColors.n700,
      );

  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 13,
        height: 18 / 13,
        fontWeight: FontWeight.w400, // Regular (400)
        color: AppColors.n600,
      );

  static TextStyle get label => GoogleFonts.inter(
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w600, // SemiBold (600)
        color: AppColors.n800,
      );

  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w400, // Regular (400)
        color: AppColors.n500,
      );
}
