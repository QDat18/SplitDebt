import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/pdf_components.dart';
import '../providers/group_provider.dart';
import '../models/group_model.dart';

class GroupCard extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final balance =
        ref.watch(groupNetBalanceProvider(group.id)).asData?.value ??
            group.userBalance;
    // Determine category icon emoji
    String emoji = group.categoryIcon ?? '👥';
    if (emoji == '👥') {
      final nameLower = group.name.toLowerCase();
      if (nameLower.contains('trip') ||
          nameLower.contains('du lịch') ||
          nameLower.contains('hải phòng') ||
          nameLower.contains('đà lạt')) {
        emoji = '🌴';
      } else if (nameLower.contains('project') ||
          nameLower.contains('team') ||
          nameLower.contains('lập trình')) {
        emoji = '💻';
      } else if (nameLower.contains('trọ') ||
          nameLower.contains('phòng') ||
          nameLower.contains('nhà')) {
        emoji = '🏠';
      } else if (nameLower.contains('ăn') ||
          nameLower.contains('uống') ||
          nameLower.contains('cơm')) {
        emoji = '🍜';
      }
    }

    // Determine balance text & color matching Figma design
    String balanceText = group.formattedBalance ?? 'Xem nợ';
    Color balanceColor = const Color(0xFF6B7280);

    if (balance != null) {
      if (balance > 0) {
        balanceText = '+${money(balance)}';
        balanceColor = const Color(0xFF10B981);
      } else if (balance < 0) {
        balanceText = money(balance);
        balanceColor = const Color(0xFFEF4444);
      } else {
        balanceText = 'Đã cân bằng';
        balanceColor = const Color(0xFF6B7280);
      }
    } else {
      if (balanceText.startsWith('+')) {
        balanceColor = const Color(0xFF10B981);
      } else if (balanceText.startsWith('-')) {
        balanceColor = const Color(0xFFEF4444);
      } else {
        balanceColor = const Color(0xFF6B7280);
      }
    }

    final String timeAgoStr = group.timeAgo ??
        (group.createdAt == null
            ? ''
            : '${group.createdAt!.day}/${group.createdAt!.month}/${group.createdAt!.year}');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEEF2F6), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 14.0,
            ),
            child: Row(
              children: [
                // Left Emoji / Icon Box
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0EDFF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(emoji, style: const TextStyle(fontSize: 24)),
                  ),
                ),
                const SizedBox(width: 14),

                // Group Title & Subtitle (Member count • Time ago)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${group.memberCount} thành viên • $timeAgoStr',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Right Balance Indicator
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      balanceText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: balanceColor,
                      ),
                    ),
                    if (onActionSelected != null) ...[
                      const SizedBox(height: 2),
                      GestureDetector(
                        onTapDown: (details) {
                          final position = details.globalPosition;
                          showMenu<String>(
                            context: context,
                            position: RelativeRect.fromLTRB(
                              position.dx,
                              position.dy,
                              position.dx,
                              position.dy,
                            ),
                            items: [
                              if (group.isAdminOrOwner)
                                const PopupMenuItem(
                                  value: 'settings',
                                  child: Row(
                                    children: [
                                      Icon(Icons.settings_outlined, size: 18),
                                      SizedBox(width: 8),
                                      Text('Cài đặt nhóm'),
                                    ],
                                  ),
                                ),
                              const PopupMenuItem(
                                value: 'leave',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.exit_to_app_rounded,
                                      size: 18,
                                      color: Colors.red,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Rời nhóm',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ).then((val) {
                            if (val != null) onActionSelected!(val);
                          });
                        },
                        child: const Icon(
                          Icons.more_horiz_rounded,
                          size: 18,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
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
