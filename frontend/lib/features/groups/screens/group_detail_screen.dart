// Trách nhiệm file: Xây dựng màn hình chi tiết nhóm (GroupDetailScreen) theo chuẩn Apple HIG / iOS Design.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/pdf_components.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../expenses/create_expense_screen.dart';
import '../../expenses/expense_read_screen.dart';
import '../../settlements/group_settlement_screen.dart';
import '../models/group_member_model.dart';
import '../models/group_model.dart';
import '../providers/group_provider.dart';
import 'add_member_dialog.dart';
import 'group_settings_screen.dart';

class GroupDetailScreen extends ConsumerStatefulWidget {
  final GroupModel group;

  const GroupDetailScreen({super.key, required this.group});

  @override
  ConsumerState<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends ConsumerState<GroupDetailScreen> {
  int _tab = 0;
  int? _user;
  List<Map<String, dynamic>> _expenses = [];
  Map<String, dynamic> _debt = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      _user = await AuthRepository().getCurrentUserId();
      final result = await Future.wait([
        dioClient.get('/v1/expenses/group/${widget.group.id}'),
        dioClient.get(
          '/groups/${widget.group.id}/debts',
          queryParameters: {'userId': _user},
        ),
      ]);
      if (!mounted) return;
      setState(() {
        _expenses = (result[0].data['data'] as List)
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        _debt = Map<String, dynamic>.from(result[1].data['data']);
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Không tải được thông tin nhóm. Hãy thử lại.';
          _loading = false;
        });
      }
    }
  }

  Future<void> _open(Widget screen) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    if (mounted) _load();
  }

  Future<void> _leaveGroup() async {
    final confirm = await showAdaptiveDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog.adaptive(
        title: const Text('Rời khỏi nhóm?'),
        content: const Text('Bạn có chắc chắn muốn rời nhóm này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Huỷ'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Rời nhóm',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
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
              content: Text('Đã rời khỏi nhóm thành công'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi: ${e.toString().replaceAll('Exception: ', '')}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _removeMember(GroupMemberModel member) async {
    final confirm = await showAdaptiveDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog.adaptive(
        title: const Text('Xoá thành viên?'),
        content: Text('Bạn có chắc muốn xoá "${member.fullName}" khỏi nhóm?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Huỷ'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Xoá',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
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
              content: Text('Đã xoá thành viên khỏi nhóm'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi: ${e.toString().replaceAll('Exception: ', '')}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  void _showMoreActions() {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(widget.group.name),
        actions: [
          if (widget.group.isAdminOrOwner)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(ctx);
                _open(GroupSettingsScreen(group: widget.group));
              },
              child: const Text('Cài đặt nhóm'),
            ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(ctx);
              _leaveGroup();
            },
            child: const Text('Rời khỏi nhóm'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Huỷ'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final members = ref.watch(groupMembersProvider(widget.group.id));
    final total = _expenses.fold<num>(0, (sum, e) => sum + (e['totalAmount'] as num));

    return Scaffold(
      backgroundColor: AppColors.n100,
      appBar: AppBar(
        title: Text(
          widget.group.name,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.n100,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          if (widget.group.isAdminOrOwner)
            IconButton(
              icon: const Icon(Icons.settings_outlined, color: AppColors.n800),
              tooltip: 'Cài đặt nhóm',
              onPressed: () => _open(GroupSettingsScreen(group: widget.group)),
            ),
          IconButton(
            icon: const Icon(Icons.more_horiz_rounded, color: AppColors.n800),
            tooltip: 'Tuỳ chọn',
            onPressed: _showMoreActions,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // Hero Financial Summary Card theo phong cách Apple HIG
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.n0,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppDimensions.shadowSm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tổng chi tiêu nhóm',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.n600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _loading ? '...' : money(total),
                    style: const TextStyle(
                      color: AppColors.n800,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: AppColors.n200),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Bạn đang nợ',
                              style: TextStyle(
                                color: AppColors.n500,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              money(_debt['totalToPay'] ?? 0),
                              style: const TextStyle(
                                color: AppColors.error,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 36,
                        color: AppColors.n200,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Bạn được nhận',
                              style: TextStyle(
                                color: AppColors.n500,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              money(_debt['totalToReceive'] ?? 0),
                              style: const TextStyle(
                                color: AppColors.success,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _open(
                            CreateExpenseScreen(
                              groupId: int.parse(widget.group.id),
                            ),
                          ),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Thêm chi tiêu'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.p500,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _open(
                            GroupSettlementScreen(
                              groupId: int.parse(widget.group.id),
                            ),
                          ),
                          icon: const Icon(Icons.payments_outlined, size: 18),
                          label: const Text('Thanh toán'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.p50,
                            foregroundColor: AppColors.p500,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Cupertino Segmented Control chuẩn Apple HIG
            SizedBox(
              width: double.infinity,
              child: CupertinoSlidingSegmentedControl<int>(
                groupValue: _tab,
                thumbColor: AppColors.n0,
                backgroundColor: AppColors.n200,
                padding: const EdgeInsets.all(3),
                children: const {
                  0: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Text(
                      'Chi tiêu',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.n800,
                      ),
                    ),
                  ),
                  1: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Text(
                      'Thành viên',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.n800,
                      ),
                    ),
                  ),
                  2: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Text(
                      'Số dư nợ',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.n800,
                      ),
                    ),
                  ),
                },
                onValueChanged: (v) {
                  if (v != null) setState(() => _tab = v);
                },
              ),
            ),
            const SizedBox(height: 14),

            // Tab contents
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator.adaptive()),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    children: [
                      Text(_error!, style: const TextStyle(color: AppColors.error)),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Thử lại'),
                      ),
                    ],
                  ),
                ),
              )
            else if (_tab == 0) ...[
              // Tab 0: Danh sách chi tiêu
              if (_expenses.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppColors.n0,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: AppDimensions.shadowSm,
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.receipt_long_outlined,
                        size: 44,
                        color: AppColors.n400,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Chưa có khoản chi tiêu nào',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.n800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Nhấn "Thêm chi tiêu" để bắt đầu chia tiền cùng nhóm.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: AppColors.n500),
                      ),
                    ],
                  ),
                )
              else
                ..._expenses.map((e) {
                  final myShare = (e['participants'] as List)
                      .where((p) => p['userId'] == _user)
                      .fold<num>(0, (sum, p) => sum + (p['amount'] as num));

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: AppColors.n0,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: AppDimensions.shadowSm,
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.p50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.receipt_outlined,
                          color: AppColors.p500,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        e['title'] ?? 'Chi tiêu',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.n800,
                        ),
                      ),
                      subtitle: Text(
                        '${e['payerName']} đã trả • ${e['expenseDate']}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.n500,
                        ),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            money(e['totalAmount']),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.n800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Bạn: ${money(myShare)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.p500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      onTap: () => _open(ExpenseReadScreen(expense: e)),
                    ),
                  );
                }),
            ] else if (_tab == 1) ...[
              // Tab 1: Thành viên nhóm
              members.when(
                data: (list) => Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.n0,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: AppDimensions.shadowSm,
                      ),
                      child: Column(
                        children: [
                          for (int i = 0; i < list.length; i++) ...[
                            ListTile(
                              leading: CircleAvatar(
                                radius: 20,
                                backgroundColor: AppColors.p50,
                                backgroundImage: (list[i].avatarUrl != null &&
                                        list[i].avatarUrl!.isNotEmpty)
                                    ? NetworkImage(list[i].avatarUrl!)
                                    : null,
                                child: (list[i].avatarUrl != null &&
                                        list[i].avatarUrl!.isNotEmpty)
                                    ? null
                                    : Text(
                                        list[i].fullName.isEmpty
                                            ? '?'
                                            : list[i].fullName.characters.first,
                                        style: const TextStyle(
                                          color: AppColors.p500,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                              title: Text(
                                '${list[i].fullName}${list[i].userId == _user.toString() ? ' (Bạn)' : ''}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.n800,
                                ),
                              ),
                              subtitle: Text(
                                list[i].role == 'OWNER'
                                    ? 'Trưởng nhóm'
                                    : 'Thành viên',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.n500,
                                ),
                              ),
                              trailing: widget.group.isAdminOrOwner && !list[i].isOwner
                                  ? IconButton(
                                      tooltip: 'Xoá thành viên',
                                      icon: const Icon(
                                        Icons.person_remove_outlined,
                                        size: 18,
                                        color: AppColors.error,
                                      ),
                                      onPressed: () => _removeMember(list[i]),
                                    )
                                  : null,
                            ),
                            if (i < list.length - 1)
                              const Divider(
                                height: 1,
                                indent: 56,
                                color: AppColors.n200,
                              ),
                          ],
                        ],
                      ),
                    ),
                    if (widget.group.isAdminOrOwner) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: AppColors.p500),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () async {
                            await showDialog(
                              context: context,
                              builder: (_) =>
                                  AddMemberDialog(groupId: widget.group.id),
                            );
                            ref.invalidate(groupMembersProvider(widget.group.id));
                          },
                          icon: const Icon(
                            Icons.person_add_outlined,
                            size: 18,
                            color: AppColors.p500,
                          ),
                          label: const Text(
                            'Thêm thành viên',
                            style: TextStyle(
                              color: AppColors.p500,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                loading: () =>
                    const Center(child: CircularProgressIndicator.adaptive()),
                error: (e, _) => Text('$e'),
              ),
            ] else ...[
              // Tab 2: Số dư nợ & Tối ưu hoá
              if ((_debt['netBalances'] as List? ?? []).isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppColors.n0,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: AppDimensions.shadowSm,
                  ),
                  child: const Center(
                    child: Text(
                      'Không có dữ liệu số dư nợ.',
                      style: TextStyle(color: AppColors.n500),
                    ),
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.n0,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: AppDimensions.shadowSm,
                  ),
                  child: Column(
                    children: [
                      for (int i = 0;
                          i < (_debt['netBalances'] as List? ?? []).length;
                          i++) ...[
                        Builder(
                          builder: (_) {
                            final b = (_debt['netBalances'] as List)[i];
                            final net = (b['netBalance'] as num?) ?? 0;
                            final isPositive = net > 0.01;
                            final isNegative = net < -0.01;

                            return ListTile(
                              leading: CircleAvatar(
                                radius: 20,
                                backgroundColor: AppColors.p50,
                                child: Text(
                                  b['fullName'] != null &&
                                          (b['fullName'] as String).isNotEmpty
                                      ? (b['fullName'] as String).characters.first
                                      : '?',
                                  style: const TextStyle(
                                    color: AppColors.p500,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                b['fullName'] ?? 'Thành viên',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.n800,
                                ),
                              ),
                              subtitle: Text(
                                isPositive
                                    ? 'Cần nhận lại'
                                    : isNegative
                                        ? 'Đang cần trả'
                                        : 'Đã cân bằng',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isPositive
                                      ? AppColors.success
                                      : isNegative
                                          ? AppColors.error
                                          : AppColors.n500,
                                ),
                              ),
                              trailing: Text(
                                '${isPositive ? '+' : ''}${money(net)}',
                                style: TextStyle(
                                  color: isPositive
                                      ? AppColors.success
                                      : isNegative
                                          ? AppColors.error
                                          : AppColors.n800,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            );
                          },
                        ),
                        if (i < (_debt['netBalances'] as List).length - 1)
                          const Divider(
                            height: 1,
                            indent: 56,
                            color: AppColors.n200,
                          ),
                      ],
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.p500,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => _open(
                    GroupSettlementScreen(
                      groupId: int.parse(widget.group.id),
                    ),
                  ),
                  icon: const Icon(Icons.auto_fix_high_rounded, size: 18),
                  label: const Text(
                    'Tối ưu công nợ (Xén nợ)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
