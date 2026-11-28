// Trách nhiệm file: Màn hình chi tiết nhóm chuẩn Fintech: tổng quan công nợ, danh sách khoản chi, thành viên, công nợ và thao tác thanh toán.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/state/app_sync.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/pdf_components.dart';
import '../../../core/widgets/fintech_components.dart';
import '../../../core/widgets/motion_kit.dart';
import '../../../core/widgets/premium_shell.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../expenses/create_expense_screen.dart';
import '../../expenses/pdf_expense_detail.dart';
import '../../settlements/group_settlement_screen.dart';
import '../models/group_member_model.dart';
import '../models/group_model.dart';
import '../providers/group_provider.dart';
import '../widgets/member_list_skeleton.dart';
import '../widgets/member_tile.dart';
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
    appDataSyncSignal.addListener(_load);
  }

  @override
  void dispose() {
    appDataSyncSignal.removeListener(_load);
    super.dispose();
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
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _debt = Map<String, dynamic>.from(result[1].data['data'] as Map);
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = tr(
            context,
            'Không tải được dữ liệu nhóm. Kiểm tra kết nối và thử lại.',
            'Could not load group data. Check your connection and retry.',
          );
          _loading = false;
        });
      }
    }
  }

  Future<void> _open(Widget screen) async {
    await Navigator.push(context, fintechRoute(screen));
    if (mounted) _load();
  }

  Future<void> _leaveGroup() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr(ctx, 'Rời khỏi nhóm', 'Leave group')),
        content: Text(
          tr(
            ctx,
            'Bạn có chắc chắn muốn rời nhóm "${widget.group.name}"?',
            'Are you sure you want to leave "${widget.group.name}"?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr(ctx, 'Hủy', 'Cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.errorFor(ctx),
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr(ctx, 'Rời nhóm', 'Leave')),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    try {
      await ref.read(userGroupsProvider.notifier).leaveGroup(widget.group.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr(context, 'Đã rời khỏi nhóm.', 'Left group.')),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  Future<void> _removeMember(GroupMemberModel member) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr(ctx, 'Xóa thành viên', 'Remove member')),
        content: Text(
          tr(
            ctx,
            'Bạn có chắc muốn xóa "${member.fullName}" khỏi nhóm?',
            'Remove "${member.fullName}" from this group?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr(ctx, 'Hủy', 'Cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.errorFor(ctx),
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr(ctx, 'Xóa', 'Remove')),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    try {
      await ref
          .read(userGroupsProvider.notifier)
          .removeMember(widget.group.id, member.userId);
      ref.invalidate(groupMembersProvider(widget.group.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr(
                context,
                'Đã xóa thành viên khỏi nhóm.',
                'Member removed from group.',
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final members = ref.watch(groupMembersProvider(widget.group.id));
    final total = _expenses.fold<num>(
      0,
      (sum, e) => sum + ((e['totalAmount'] as num?) ?? 0),
    );
    final toPay = ((_debt['totalToPay'] as num?) ?? 0).toDouble();
    final toReceive = ((_debt['totalToReceive'] as num?) ?? 0).toDouble();
    final net = toReceive - toPay;
    final groupIdInt = int.tryParse(widget.group.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.group.name),
        actions: [
          PopupMenuButton<String>(
            tooltip: tr(context, 'Tùy chọn nhóm', 'Group options'),
            onSelected: (v) {
              if (v == 'leave') {
                _leaveGroup();
              } else {
                _open(GroupSettingsScreen(group: widget.group));
              }
            },
            itemBuilder: (ctx) => [
              if (widget.group.isAdminOrOwner)
                PopupMenuItem(
                  value: 'settings',
                  child: Text(tr(ctx, 'Cài đặt nhóm', 'Group settings')),
                ),
              PopupMenuItem(
                value: 'leave',
                child: Text(
                  tr(ctx, 'Rời nhóm', 'Leave group'),
                  style: TextStyle(color: AppColors.errorFor(ctx)),
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        color: scheme.primary,
        onRefresh: _load,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppDimensions.maxContentWidth,
            ),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.s16,
                AppDimensions.s12,
                AppDimensions.s16,
                AppDimensions.s32,
              ),
              children: [
                BalanceSummaryCard(
                  net: net,
                  receivable: toReceive,
                  payable: toPay,
                  title: tr(
                    context,
                    'Số dư của bạn trong nhóm',
                    'Your group balance',
                  ),
                  subtitle: _loading
                      ? null
                      : tr(
                          context,
                          'Tổng chi tiêu nhóm: ${money(total)}',
                          'Total group spend: ${money(total)}',
                        ),
                ),
                const SizedBox(height: AppDimensions.s12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: groupIdInt == null
                            ? null
                            : () => _open(
                                CreateExpenseScreen(groupId: groupIdInt),
                              ),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: Text(tr(context, 'Thêm chi', 'Add expense')),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.s8),
                    Expanded(
                      child: NavyActionButton(
                        onPressed: groupIdInt == null
                            ? null
                            : () => _open(
                                GroupSettlementScreen(groupId: groupIdInt),
                              ),
                        icon: CupertinoIcons.arrow_2_squarepath,
                        label: tr(context, 'Thanh toán', 'Settle up'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.s20),
                PdfTabs(
                  labels: [
                    tr(context, 'Chi tiêu', 'Expenses'),
                    tr(context, 'Thành viên', 'Members'),
                    tr(context, 'Công nợ', 'Balances'),
                  ],
                  selected: _tab,
                  onChanged: (v) => setState(() => _tab = v),
                ),
                const SizedBox(height: AppDimensions.s16),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      children: [
                        ShimmerBox(
                          width: double.infinity,
                          height: 64,
                          radius: 12,
                        ),
                        SizedBox(height: 8),
                        ShimmerBox(
                          width: double.infinity,
                          height: 64,
                          radius: 12,
                        ),
                      ],
                    ),
                  )
                else if (_error != null)
                  AppErrorState(
                    title: tr(context, 'Lỗi tải dữ liệu', 'Load error'),
                    message: _error!,
                    onRetry: _load,
                  )
                else if (_tab == 0)
                  _buildExpensesTab(scheme)
                else if (_tab == 1)
                  _buildMembersTab(members)
                else
                  _buildBalancesTab(scheme, groupIdInt),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpensesTab(ColorScheme scheme) {
    if (_expenses.isEmpty) {
      return AppEmptyState(
        icon: CupertinoIcons.doc_text,
        title: tr(context, 'Chưa có khoản chi', 'No expenses yet'),
        message: tr(
          context,
          'Nhấn "Thêm chi" để ghi lại khoản chi đầu tiên của nhóm.',
          'Tap "Add expense" to record your first group expense.',
        ),
      );
    }

    return PremiumSurface(
      padding: EdgeInsets.zero,
      radius: AppDimensions.r12,
      child: Column(
        children: [
          for (int i = 0; i < _expenses.length; i++) ...[
            _expenseRow(_expenses[i], scheme),
            if (i < _expenses.length - 1) const Divider(height: 1, indent: 64),
          ],
        ],
      ),
    );
  }

  Widget _expenseRow(Map<String, dynamic> e, ColorScheme scheme) {
    final participants = e['participants'] as List? ?? [];
    final myShare = participants
        .where((p) => p['userId'] == _user)
        .fold<num>(0, (sum, p) => sum + ((p['amount'] as num?) ?? 0));

    return InkWell(
      onTap: () => _open(ExpenseReadScreen(expense: e)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            ExpenseIconBadge(
              title: e['title']?.toString() ?? '',
              categoryName: e['categoryName']?.toString(),
              size: 40,
            ),
            const SizedBox(width: AppDimensions.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e['title']?.toString() ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${e['payerName'] ?? ''} · ${e['expenseDate'] ?? ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppDimensions.s8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  money((e['totalAmount'] as num?) ?? 0),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  tr(
                    context,
                    'Bạn: ${money(myShare)}',
                    'You: ${money(myShare)}',
                  ),
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMembersTab(AsyncValue<List<GroupMemberModel>> members) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        members.when(
          data: (list) => PremiumSurface(
            padding: EdgeInsets.zero,
            radius: AppDimensions.r12,
            child: Column(
              children: [
                for (int i = 0; i < list.length; i++) ...[
                  MemberTile(
                    member: list[i],
                    canManage: widget.group.isAdminOrOwner,
                    onRemove: () => _removeMember(list[i]),
                  ),
                  if (i < list.length - 1) const Divider(height: 1, indent: 64),
                ],
              ],
            ),
          ),
          loading: () => const MemberListSkeleton(),
          error: (e, _) => AppErrorState(
            title: tr(context, 'Không tải được thành viên', 'Load error'),
            message: e.toString().replaceAll('Exception: ', ''),
            onRetry: () =>
                ref.invalidate(groupMembersProvider(widget.group.id)),
          ),
        ),
        if (widget.group.isAdminOrOwner) ...[
          const SizedBox(height: AppDimensions.s16),
          OutlinedButton.icon(
            onPressed: () async {
              await showDialog(
                context: context,
                builder: (_) => AddMemberDialog(groupId: widget.group.id),
              );
              ref.invalidate(groupMembersProvider(widget.group.id));
            },
            icon: const Icon(Icons.person_add_outlined, size: 18),
            label: Text(tr(context, 'Thêm thành viên', 'Add member')),
          ),
        ],
      ],
    );
  }

  Widget _buildBalancesTab(ColorScheme scheme, int? groupIdInt) {
    final balances = (_debt['netBalances'] as List? ?? [])
        .whereType<Map>()
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (balances.isEmpty)
          AppEmptyState(
            icon: CupertinoIcons.checkmark_circle,
            title: tr(context, 'Chưa có công nợ', 'No balances yet'),
            message: tr(
              context,
              'Công nợ của từng thành viên sẽ hiển thị sau khi có khoản chi.',
              'Member balances will appear after expenses are added.',
            ),
          )
        else
          PremiumSurface(
            padding: EdgeInsets.zero,
            radius: AppDimensions.r12,
            child: Column(
              children: [
                for (int i = 0; i < balances.length; i++) ...[
                  _balanceRow(balances[i], scheme),
                  if (i < balances.length - 1)
                    const Divider(height: 1, indent: 64),
                ],
              ],
            ),
          ),
        const SizedBox(height: AppDimensions.s16),
        FilledButton.icon(
          onPressed: groupIdInt == null
              ? null
              : () => _open(GroupSettlementScreen(groupId: groupIdInt)),
          icon: const Icon(CupertinoIcons.arrow_2_squarepath, size: 18),
          label: Text(
            tr(context, 'Xem đề xuất thanh toán', 'View settlement plan'),
          ),
        ),
      ],
    );
  }

  Widget _balanceRow(Map b, ColorScheme scheme) {
    final bal = (b['netBalance'] as num?) ?? 0;
    final name = b['fullName']?.toString() ?? '';
    final color = bal > 0
        ? AppColors.successFor(context)
        : bal < 0
        ? AppColors.errorFor(context)
        : scheme.onSurfaceVariant;
    final subtitle = bal > 0
        ? tr(context, 'Được nhận', 'Owed')
        : bal < 0
        ? tr(context, 'Cần trả', 'Owes')
        : tr(context, 'Đã cân bằng', 'Settled');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          PersonBadge(
            name,
            color: bal < 0 ? AppColors.errorFor(context) : scheme.primary,
          ),
          const SizedBox(width: AppDimensions.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            bal == 0 ? money(0) : '${bal > 0 ? '+' : '-'}${money(bal.abs())}',
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
