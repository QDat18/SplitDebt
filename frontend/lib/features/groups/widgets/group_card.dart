// Trách nhiệm file: Cung cấp widget thẻ nhóm (GroupCard) theo chuẩn Apple HIG / iOS Inset Grouped style.

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/pdf_components.dart';
import '../models/group_model.dart';

class GroupCard extends StatelessWidget {
  final GroupModel group;
  final VoidCallback onTap;
  final Function(String action)? onActionSelected;

  const GroupCard({
    super.key,
    required this.group,
    required this.onTap,
    this.onActionSelected,
  });

  @override
  Widget build(BuildContext context) {
    final balance = group.userBalance;

    String balanceText = 'Đã cân bằng';
    Color balanceColor = AppColors.n500;

    if (balance != null) {
      if (balance > 0.01) {
        balanceText = '+${money(balance)}';
        balanceColor = AppColors.success;
      } else if (balance < -0.01) {
        balanceText = money(balance);
        balanceColor = AppColors.error;
      } else {
        balanceText = 'Đã cân bằng';
        balanceColor = AppColors.n500;
      }
    } else if (group.formattedBalance != null && group.formattedBalance!.isNotEmpty) {
      balanceText = group.formattedBalance!;
      if (balanceText.startsWith('+')) {
        balanceColor = AppColors.success;
      } else if (balanceText.startsWith('-')) {
        balanceColor = AppColors.error;
      } else {
        balanceColor = AppColors.n500;
      }
    }

    final String timeAgoStr = group.timeAgo ??
        (group.createdAt == null
            ? ''
            : '${group.createdAt!.day}/${group.createdAt!.month}/${group.createdAt!.year}');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.n0,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppDimensions.shadowSm,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 14.0,
            ),
            child: Row(
              children: [
                // Left Icon Box theo phong cách iOS Squircle
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.p50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.groups_rounded,
                      color: AppColors.p500,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Group Title & Subtitle (Tên nhóm, số thành viên, thời gian)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.n800,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        timeAgoStr.isNotEmpty
                            ? '${group.memberCount} thành viên • $timeAgoStr'
                            : '${group.memberCount} thành viên',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.n500,
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Right Balance Indicator & Chevron
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          balanceText,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: balanceColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: AppColors.n400,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
