// Trách nhiệm file: Icon thương hiệu Xén Nợ (chủ đề du lịch) dùng chung ở màn khởi động, giới thiệu.

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Biểu tượng chính của thương hiệu: máy bay cất cánh, gợi chuyến đi chung của cả nhóm.
const IconData kAppMarkIcon = Icons.flight_takeoff_rounded;

/// Ô bo góc kiểu app icon, nền tím thương hiệu, biểu tượng máy bay màu trắng.
/// Bo góc và cỡ icon tính theo [size] nên dùng được ở mọi kích thước.
class AppMark extends StatelessWidget {
  final double size;
  final bool elevated;

  const AppMark({super.key, this.size = 96, this.elevated = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.27),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.p400, AppColors.p600],
        ),
        boxShadow: elevated
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 30,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Icon(
        kAppMarkIcon,
        size: size * 0.5,
        color: Colors.white,
        semanticLabel: 'Biểu tượng Xén Nợ',
      ),
    );
  }
}
