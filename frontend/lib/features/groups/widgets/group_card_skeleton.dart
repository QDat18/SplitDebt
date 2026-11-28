// Trách nhiệm file: Cung cấp skeleton tải danh sách nhóm tương thích Light & Dark mode.

import 'package:flutter/material.dart';

import '../../../core/theme/app_dimensions.dart';
import '../../../core/widgets/motion_kit.dart';
import '../../../core/widgets/premium_shell.dart';

class GroupCardSkeleton extends StatelessWidget {
  const GroupCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: AppDimensions.s8),
      child: PremiumSurface(
        padding: EdgeInsets.all(AppDimensions.s12),
        radius: AppDimensions.r12,
        child: Row(
          children: [
            ShimmerBox(width: 42, height: 42, radius: 10),
            SizedBox(width: AppDimensions.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(width: 140, height: 15, radius: 6),
                  SizedBox(height: 6),
                  ShimmerBox(width: 96, height: 12, radius: 5),
                ],
              ),
            ),
            ShimmerBox(width: 68, height: 15, radius: 6),
          ],
        ),
      ),
    );
  }
}
