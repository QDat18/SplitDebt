import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/group_model.dart';
import '../models/group_member_model.dart';
import '../providers/group_provider.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/theme/pdf_components.dart';
import '../../auth/data/auth_repository.dart';
import '../../expenses/pdf_expense_detail.dart';
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
        dioClient.get('/groups/${widget.group.id}/debts',
            queryParameters: {'userId': _user})
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
      if (mounted)
        setState(() {
          _error = 'Không tải được khoản chi.';
          _loading = false;
        });
    }
  }

  Future<void> _open(Widget screen) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final members = ref.watch(groupMembersProvider(widget.group.id));
    final total =
        _expenses.fold<num>(0, (sum, e) => sum + (e['totalAmount'] as num));
    return Scaffold(
      appBar: AppBar(title: Text(widget.group.name), actions: [
        PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'leave') {
                _leaveGroup();
              } else {
                _open(GroupSettingsScreen(group: widget.group));
              }
            },
            itemBuilder: (_) => [
                  if (widget.group.isAdminOrOwner)
                    const PopupMenuItem(
                        value: 'settings', child: Text('Cài đặt nhóm')),
                  const PopupMenuItem(value: 'leave', child: Text('Rời nhóm'))
                ])
      ]),
      body: RefreshIndicator(
          onRefresh: _load,
          child: ListView(padding: const EdgeInsets.all(20), children: [
            Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: const Color(0xFF261C60),
                    borderRadius: BorderRadius.circular(20)),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('TỔNG CHI TIÊU',
                          style: TextStyle(
                              fontSize: 11, color: Color(0xFFC4BAEF))),
                      const SizedBox(height: 6),
                      Text(_loading ? '…' : money(total),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 18),
                      const Divider(color: Color(0xFF433783)),
                      Row(children: [
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              const Text('Bạn đang nợ',
                                  style: TextStyle(
                                      color: Color(0xFFC4BAEF), fontSize: 11)),
                              Text(money(_debt['totalToPay'] ?? 0),
                                  style: const TextStyle(
                                      color: pdfRed,
                                      fontWeight: FontWeight.bold))
                            ])),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              const Text('Bạn được nhận',
                                  style: TextStyle(
                                      color: Color(0xFFC4BAEF), fontSize: 11)),
                              Text(money(_debt['totalToReceive'] ?? 0),
                                  style: const TextStyle(
                                      color: pdfGreen,
                                      fontWeight: FontWeight.bold))
                            ]))
                      ]),
                      const SizedBox(height: 16),
                      Row(children: [
                        Expanded(
                            child: FilledButton.icon(
                                onPressed: () => _open(CreateExpenseScreen(
                                    groupId: int.parse(widget.group.id))),
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Thêm chi'))),
                        const SizedBox(width: 10),
                        Expanded(
                            child: FilledButton(
                                style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFF493D7E)),
                                onPressed: () => _open(GroupSettlementScreen(
                                    groupId: int.parse(widget.group.id))),
                                child: const Text('Thanh toán')))
                      ]),
                    ])),
            const SizedBox(height: 20),
            PdfTabs(
                labels: const ['Chi tiêu', 'Thành viên', 'Nợ'],
                selected: _tab,
                onChanged: (v) => setState(() => _tab = v)),
            const SizedBox(height: 20),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_error != null)
              TextButton(onPressed: _load, child: Text(_error!))
            else if (_tab == 0) ...[
              if (_expenses.isEmpty)
                const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                        'Chưa có khoản chi. Nhấn “Thêm chi” để bắt đầu.',
                        textAlign: TextAlign.center)),
              for (final e in _expenses)
                Card(
                    child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        leading: const PersonBadge('🍲'),
                        title: Text(e['title'] ?? '',
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w700)),
                        subtitle: Text(
                            '${e['payerName']} đã trả • ${e['expenseDate']}',
                            style: const TextStyle(fontSize: 10)),
                        trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(money(e['totalAmount']),
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(height: 4),
                              Text(
                                  'Bạn: ${money((e['participants'] as List).where((p) => p['userId'] == _user).fold<num>(0, (sum, p) => sum + (p['amount'] as num)))}',
                                  style: const TextStyle(
                                      fontSize: 10, color: Color(0xFFFFA000)))
                            ]),
                        onTap: () => _open(ExpenseReadScreen(expense: e)))),
            ] else if (_tab == 1) ...[
              members.when(
                  data: (list) => Column(children: [
                        for (final m in list)
                          Card(
                              child: ListTile(
                                  leading: PersonBadge(m.fullName),
                                  title: Text(
                                      '${m.fullName}${m.userId == _user.toString() ? ' (Bạn)' : ''}',
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700)),
                                  subtitle: Text(
                                      m.role == 'OWNER'
                                          ? 'Trưởng nhóm'
                                          : 'Thành viên',
                                      style: const TextStyle(fontSize: 12)),
                                  trailing:
                                      widget.group.isAdminOrOwner && !m.isOwner
                                          ? IconButton(
                                              tooltip: 'Xóa thành viên',
                                              icon: const Icon(
                                                  Icons.person_remove_outlined,
                                                  size: 18),
                                              onPressed: () => _removeMember(m))
                                          : null))
                      ]),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('$e')),
              if (widget.group.isAdminOrOwner)
                OutlinedButton(
                    onPressed: () async {
                      await showDialog(
                          context: context,
                          builder: (_) =>
                              AddMemberDialog(groupId: widget.group.id));
                      ref.invalidate(groupMembersProvider(widget.group.id));
                    },
                    child: const Text('Thêm thành viên')),
            ] else ...[
              for (final b in _debt['netBalances'] as List? ?? [])
                Card(
                    child: ListTile(
                        leading: PersonBadge(b['fullName']),
                        title: Text(b['fullName'],
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600)),
                        subtitle: Text(
                            b['netBalance'] > 0
                                ? 'Được nhận'
                                : b['netBalance'] < 0
                                    ? 'Đang nợ'
                                    : 'Đã cân bằng',
                            style: const TextStyle(fontSize: 12)),
                        trailing: Text(
                            '${b['netBalance'] > 0 ? '+' : ''}${money(b['netBalance'])}',
                            style: TextStyle(
                                color: b['netBalance'] < 0 ? pdfRed : pdfGreen,
                                fontSize: 12,
                                fontWeight: FontWeight.bold)))),
              FilledButton.icon(
                  onPressed: () => _open(GroupSettlementScreen(
                      groupId: int.parse(widget.group.id))),
                  icon: const Text('✂', style: TextStyle(fontSize: 20)),
                  label: const Text('Xén nợ')),
            ],
          ])),
    );
  }
}
