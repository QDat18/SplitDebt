import 'package:flutter/material.dart';
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
    final theme = Theme.of(context);

    final String roleText;
    final Color roleColor;
    switch (member.role) {
      case 'OWNER':
        roleText = 'Trưởng nhóm';
        roleColor = theme.colorScheme.primary;
        break;
      case 'ADMIN':
        roleText = 'Quản trị';
        roleColor = Colors.blue.shade700;
        break;
      default:
        roleText = 'Thành viên';
        roleColor = Colors.grey.shade600;
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: theme.colorScheme.primaryContainer,
        child: Text(
          member.fullName.isNotEmpty ? member.fullName[0].toUpperCase() : 'U',
          style: TextStyle(
            color: theme.colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        member.fullName,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
      subtitle: Text(
        member.email,
        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: roleColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              roleText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: roleColor,
              ),
            ),
          ),
          if (canManage && !member.isOwner && onRemove != null) ...[
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(
                Icons.remove_circle_outline_rounded,
                color: Colors.red,
                size: 20,
              ),
              onPressed: onRemove,
              tooltip: 'Xóa thành viên',
            ),
          ],
        ],
      ),
    );
  }
}
