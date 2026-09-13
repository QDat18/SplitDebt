import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/group_model.dart';
import '../models/group_member_model.dart';
import '../providers/group_provider.dart';
import '../widgets/member_tile.dart';
import '../widgets/member_list_skeleton.dart';
import 'add_member_dialog.dart';
import 'group_settings_screen.dart';
import '../../settlements/group_settlement_screen.dart';
import '../../expenses/create_expense_screen.dart';

class GroupDetailScreen extends ConsumerStatefulWidget {
  final GroupModel group;

  const GroupDetailScreen({super.key, required this.group});

  @override
  ConsumerState<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends ConsumerState<GroupDetailScreen> {
  Future<void> _leaveGroup() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rời khỏi nhóm'),
        content: const Text('Bạn có chắc chắn muốn rời nhóm này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Rời nhóm'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(userGroupsProvider.notifier).leaveGroup(widget.group.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã rời khỏi nhóm'),
              backgroundColor: Colors.orange,
            ),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Lỗi: ${e.toString().replaceAll('Exception: ', '')}',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _removeMember(GroupMemberModel member) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa thành viên'),
        content: Text(
          'Bạn có chắc muốn xóa "${member.fullName}" khỏi nhóm?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref
            .read(userGroupsProvider.notifier)
            .removeMember(widget.group.id, member.userId);
        ref.invalidate(groupMembersProvider(widget.group.id));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã xóa thành viên khỏi nhóm'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Lỗi: ${e.toString().replaceAll('Exception: ', '')}',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final membersAsync = ref.watch(groupMembersProvider(widget.group.id));

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200.0,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.group.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withOpacity(0.8),
                      theme.colorScheme.primaryContainer,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Hero(
                    tag: 'group_icon_${widget.group.id}',
                    child: Icon(
                      Icons.groups_rounded,
                      size: 80,
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              if (widget.group.isAdminOrOwner)
                IconButton(
                  icon: const Icon(
                    Icons.settings_outlined,
                    color: Colors.white,
                  ),
                  tooltip: 'Cài đặt nhóm',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            GroupSettingsScreen(group: widget.group),
                      ),
                    );
                  },
                ),
              IconButton(
                tooltip: 'Thêm khoản chi',
                icon: const Icon(Icons.add, color: Colors.white),
                onPressed: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => CreateExpenseScreen(groupId: int.parse(widget.group.id)))),
              ),
              IconButton(
                tooltip: 'Quyết toán nhóm',
                icon: const Icon(Icons.payments_outlined, color: Colors.white),
                onPressed: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => GroupSettlementScreen(groupId: int.parse(widget.group.id)))),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
                onSelected: (val) {
                  if (val == 'leave') _leaveGroup();
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'leave',
                    child: Row(
                      children: [
                        Icon(Icons.exit_to_app_rounded, color: Colors.red),
                        SizedBox(width: 8),
                        Text(
                          'Rời nhóm',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Group Summary Card
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Mô tả nhóm',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  widget.group.currentUserRole == 'OWNER'
                                      ? 'Trưởng nhóm'
                                      : widget.group.currentUserRole == 'ADMIN'
                                          ? 'Quản trị'
                                          : 'Thành viên',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            (widget.group.description != null &&
                                    widget.group.description!.isNotEmpty)
                                ? widget.group.description!
                                : 'Chưa có mô tả cho nhóm này.',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 14,
                            ),
                          ),
                          const Divider(height: 24),
                          Row(
                            children: [
                              Icon(
                                Icons.person_pin_rounded,
                                size: 18,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Tạo bởi: ${widget.group.createdByName ?? 'Admin'}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Members Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Danh sách thành viên',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (widget.group.isAdminOrOwner)
                        TextButton.icon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) =>
                                  AddMemberDialog(groupId: widget.group.id),
                            );
                          },
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Thêm'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Members List
                  membersAsync.when(
                    data: (members) {
                      if (members.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: Text('Chưa có thành viên nào.')),
                        );
                      }
                      return Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: members.length,
                          separatorBuilder: (ctx, idx) =>
                              const Divider(height: 1),
                          itemBuilder: (ctx, idx) {
                            final m = members[idx];
                            return MemberTile(
                              member: m,
                              canManage: widget.group.isAdminOrOwner,
                              onRemove: () => _removeMember(m),
                            );
                          },
                        ),
                      );
                    },
                    loading: () => const MemberListSkeleton(),
                    error: (err, st) => Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Lỗi tải danh sách thành viên: $err',
                        style: TextStyle(color: Colors.red.shade800),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
