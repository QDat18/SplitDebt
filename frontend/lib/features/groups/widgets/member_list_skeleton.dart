// Trách nhiệm file: Cung cấp skeleton danh sách thành viên tương thích Light & Dark mode.

import 'package:flutter/material.dart';

import '../../../core/widgets/motion_kit.dart';

class MemberListSkeleton extends StatelessWidget {
  const MemberListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        4,
        (_) => const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              ShimmerBox(width: 40, height: 40, radius: 20),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(width: 120, height: 14, radius: 5),
                    SizedBox(height: 6),
                    ShimmerBox(width: 170, height: 12, radius: 5),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
