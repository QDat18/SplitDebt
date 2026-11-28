// Trách nhiệm file: Cung cấp widget group card chuẩn Fintech, gọn gàng, không dùng emoji, tương thích Light & Dark mode.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../core/state/app_sync.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/pdf_components.dart';
import '../../../core/widgets/fintech_components.dart';
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
    final scheme = Theme.of(context).colorScheme;
    final balance = group.userBalance;

    String balanceText;
    Color balanceColor;
    IconData? balanceIcon;

    if (balance != null) {
      if (balance > 0) {
        balanceText = '+${money(balance)}';
        balanceColor = AppColors.successFor(context);
        balanceIcon = CupertinoIcons.arrow_down_left;
      } else if (balance < 0) {
        balanceText = '-${money(balance.abs())}';
        balanceColor = AppColors.errorFor(context);
        balanceIcon = CupertinoIcons.arrow_up_right;
      } else {
        balanceText = tr(context, 'Đã cân bằng', 'Settled');
        balanceColor = scheme.onSurfaceVariant;
      }
    } else {
      balanceText = group.formattedBalance ?? tr(context, 'Xem nợ', 'View');
      if (balanceText.startsWith('+')) {
        balanceColor = AppColors.successFor(context);
        balanceIcon = CupertinoIcons.arrow_down_left;
      } else if (balanceText.startsWith('-')) {
        balanceColor = AppColors.errorFor(context);
        balanceIcon = CupertinoIcons.arrow_up_right;
      } else {
        balanceColor = scheme.onSurfaceVariant;
      }
    }

    final timeAgoStr =
        group.timeAgo ??
        (group.createdAt == null
            ? ''
            : '${group.createdAt!.day}/${group.createdAt!.month}/${group.createdAt!.year}');
    final membersLabel = tr(
      context,
      '${group.memberCount} thành viên',
      '${group.memberCount} members',
    );
    final subtitle = timeAgoStr.isNotEmpty
        ? '$membersLabel · $timeAgoStr'
        : membersLabel;

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.s8),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.navy800
            : AppColors.n50,
        borderRadius: AppDimensions.radius16,
        border: Border.all(color: AppColors.hairlineFor(context), width: 0.8),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppDimensions.radius16,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppDimensions.radius16,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.s12,
              vertical: AppDimensions.s12,
            ),
            child: Row(
              children: [
                GroupAvatar(name: group.name, size: 42, radius: 10),
                const SizedBox(width: AppDimensions.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: scheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppDimensions.s8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (balanceIcon != null) ...[
                          Icon(balanceIcon, size: 12, color: balanceColor),
                          const SizedBox(width: 2),
                        ],
                        Text(
                          balanceText,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: balanceColor,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (onActionSelected != null)
                  PopupMenuButton<String>(
                    tooltip: tr(context, 'Tùy chọn nhóm', 'Group options'),
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      Icons.more_vert_rounded,
                      size: 20,
                      color: scheme.onSurfaceVariant,
                    ),
                    onSelected: (val) => onActionSelected!(val),
                    itemBuilder: (ctx) => [
                      if (group.isAdminOrOwner)
                        PopupMenuItem(
                          value: 'settings',
                          child: Row(
                            children: [
                              const Icon(Icons.settings_outlined, size: 18),
                              const SizedBox(width: 8),
                              Text(tr(ctx, 'Cài đặt nhóm', 'Group settings')),
                            ],
                          ),
                        ),
                      PopupMenuItem(
                        value: 'leave',
                        child: Row(
                          children: [
                            Icon(
                              Icons.exit_to_app_rounded,
                              size: 18,
                              color: AppColors.errorFor(ctx),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              tr(ctx, 'Rời nhóm', 'Leave group'),
                              style: TextStyle(color: AppColors.errorFor(ctx)),
                            ),
                          ],
                        ),
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
