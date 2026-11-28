// Trách nhiệm file: Cung cấp widget member tile chuẩn hóa, tương thích Light & Dark mode.

import 'package:flutter/material.dart';

import '../../../core/state/app_sync.dart';
import '../../../core/theme/app_colors.dart';
import '../models/group_member_model.dart';

class MemberTile extends StatelessWidget {
  final GroupMemberModel member;
  final bool canManage;
  final VoidCallback? onRemove;

  const MemberTile({
    super.key,
    required this.member,
    this.canManage = false,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final String roleText;
    final Color roleColor;
    switch (member.role) {
      case 'OWNER':
        roleText = tr(context, 'Trưởng nhóm', 'Owner');
        roleColor = scheme.primary;
        break;
      case 'ADMIN':
        roleText = tr(context, 'Quản trị', 'Admin');
        roleColor = AppColors.warningFor(context);
        break;
      default:
        roleText = tr(context, 'Thành viên', 'Member');
        roleColor = scheme.onSurfaceVariant;
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: scheme.primary.withValues(alpha: 0.12),
        child: Text(
          member.fullName.isNotEmpty ? member.fullName[0].toUpperCase() : 'U',
          style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w700),
        ),
      ),
      title: Text(
        member.fullName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          color: scheme.onSurface,
        ),
      ),
      subtitle: Text(
        member.email,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: roleColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              roleText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: roleColor,
              ),
            ),
          ),
          if (canManage && !member.isOwner && onRemove != null) ...[
            const SizedBox(width: 4),
            IconButton(
              icon: Icon(
                Icons.person_remove_outlined,
                color: AppColors.errorFor(context),
                size: 20,
              ),
              onPressed: onRemove,
              tooltip: tr(context, 'Xóa thành viên', 'Remove member'),
            ),
          ],
        ],
      ),
    );
  }
}
