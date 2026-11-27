// Trách nhiệm file: Định nghĩa thành phần thiết kế app dimensions dùng thống nhất trong toàn ứng dụng.

import 'package:flutter/material.dart';

/// QUY CHUẨN KHOẢNG CÁCH, BO GÓC & BÓNG ĐỔ DESIGN SYSTEM v1.0.0
class AppDimensions {
  static const double compactBreakpoint = 600;
  static const double navigationRailBreakpoint = 840;
  static const double extendedNavigationBreakpoint = 1200;
  static const double maxAppWidth = 1440;
  static const double maxContentWidth = 1040;
  static const double minTouchTarget = 48;

  static double horizontalPadding(double width) =>
      width < compactBreakpoint ? 16 : 32;

  // --- SPACING SCALE ---
  static const double s4 = 4.0;
  static const double s8 = 8.0;
  static const double s12 = 12.0;
  static const double s14 = 14.0;
  static const double s16 = 16.0;
  static const double s20 = 20.0;
  static const double s24 = 24.0;
  static const double s28 = 28.0;
  static const double s32 = 32.0;
  static const double s40 = 40.0;
  static const double s48 = 48.0;
  static const double s64 = 64.0;

  // --- BORDER RADIUS ---
  static const double r8 = 8.0;
  static const double r12 = 12.0;
  static const double r16 = 16.0;
  static const double r20 = 20.0;
  static const double r24 = 24.0;
  static const double r32 = 32.0;

  static BorderRadius get radius8 => BorderRadius.circular(r8);
  static BorderRadius get radius12 => BorderRadius.circular(r12);
  static BorderRadius get radius16 => BorderRadius.circular(r16);
  static BorderRadius get radius20 => BorderRadius.circular(r20);
  static BorderRadius get radius24 => BorderRadius.circular(r24);
  static BorderRadius get radius32 => BorderRadius.circular(r32);

  // --- SHADOWS ---
  static List<BoxShadow> get shadowSm => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get shadowMd => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get shadowLg => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.12),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];
}
