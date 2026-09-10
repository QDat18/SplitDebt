import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/premium_ui.dart';
import '../../core/widgets/reference_ui.dart';
import '../../data/api.dart';
import '../../widgets/design.dart';
import 'forms.dart';

class GroupScreen extends StatefulWidget {
  final int id;
  const GroupScreen({super.key, required this.id});
  @override State<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen> {
  late Future<dynamic> future;
  int tab = 0;
  int get user => Session.userId ?? -1;

  @override void initState() { super.initState(); future = Api.call('/groups/${widget.id}'); }

  Future<void> refresh() async {
    final next = Api.call('/groups/${widget.id}');
    setState(() => future = next);
    try { await next; } catch (_) {}
  }

  Future<void> open(Widget screen, {String? successMessage, String successTitle = 'Đã cập nhật'}) async {
    final changed = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => screen));
    if (changed == true && mounted) {
      if (successMessage != null) showSuccess(context, successMessage, title: successTitle);
      await refresh();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.transparent,
    appBar: AppBar(
      title: const Text('Nhóm'),
      actions: [
        IconButton(tooltip: 'Thống kê', onPressed: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => StatisticsScreen(groupId: widget.id))), icon: const Icon(Icons.insights_rounded)),
      ],
    ),
    body: PremiumBackground(
      child: FutureBuilder<dynamic>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: EmptyState(
          title: 'Không thể tải nhóm', description: snapshot.error.toString(),
          action: FilledButton(onPressed: refresh, child: const Text('Thử lại')),
        ));
        final d = Map<String, dynamic>.from(snapshot.data as Map);
        final g = Map<String, dynamic>.from(d['group'] as Map);
        final members = maps(d['members']);
        final currency = g['currency'].toString();
        final expenses = maps(d['expenses']);
        final settlements = maps(d['settlements']);
        final suggestions = maps(d['suggestions']);
        final balancesRaw = Map<dynamic, dynamic>.from(d['balances'] as Map);
        int balanceFor(int id) => asInt(balancesRaw['$id'] ?? balancesRaw[id] ?? 0);
        String name(int id) => members.firstWhere((m) => asInt(m['id']) == id, orElse: () => {'name': 'Thành viên #$id'})['name'].toString();
        final ownerId = asInt(g['ownerId']);
        final payable = suggestions
            .where((x) => asInt(x['fromId']) == user)
            .fold<int>(0, (sum, x) => sum + asInt(x['amount']));
        final receivable = suggestions
            .where((x) => asInt(x['toId']) == user)
            .fold<int>(0, (sum, x) => sum + asInt(x['amount']));

        return RefreshIndicator(
          onRefresh: refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              Row(children: [
                GroupArtwork(g['name'].toString(), size: 54),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(g['name'].toString(), style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 3),
                  Text('${members.length} thành viên · $currency'),
                ])),
                IconButton(
                  tooltip: 'Sao chép mã mời',
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: g['inviteCode']?.toString() ?? ''));
                    if (context.mounted) showSuccess(context, 'Đã sao chép mã mời của nhóm.', title: 'Mã mời');
                  },
                  icon: const Icon(Icons.ios_share_rounded),
                ),
              ]),
              if (g['description'] != null && g['description'].toString().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(g['description'].toString(), style: Theme.of(context).textTheme.bodyMedium),
              ],
              const SizedBox(height: 22),
              GroupHeroSummary(
                total: asInt(g['total']),
                payable: payable,
                receivable: receivable,
                currency: currency,
                onAddExpense: () => open(
                  AddExpenseScreen(detail: d),
                  successTitle: 'Đã lưu khoản chi',
                  successMessage: 'Khoản chi đã được thêm và công nợ của nhóm đã được tính lại.',
                ),
                onSettlement: () => setState(() => tab = 1),
              ),
              const SizedBox(height: 22),
              GroupTabs(selected: tab, onChanged: (value) => setState(() => tab = value)),
              if (tab == 0) ...[
                const SectionTitle('Khoản chi'),
                if (expenses.isEmpty) const EmptyState(
                  title: 'Chưa có khoản chi',
                  description: 'Thêm khoản chi đầu tiên để bắt đầu chia tiền.',
                  icon: Icons.receipt_long_rounded,
                ),
                ...expenses.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Surface(
                    padding: EdgeInsets.zero,
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: const Icon(Icons.receipt_long_rounded, color: AppColors.primary),
                      title: Text(e['title'].toString()),
                      subtitle: Text('${name(asInt(e['payerId']))} đã trả ${money(asInt(e['amount']), currency)}\n${e['categoryName'] ?? 'Khác'} · ${e['expenseDate']}'),
                      isThreeLine: true,
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () async {
                        final changed = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) =>
                          ExpenseDetailScreen(detail: d, expense: e)));
                        if (changed == true && mounted) await refresh();
                      },
                    ),
                  ),
                )),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => open(
                    AddExpenseScreen(detail: d),
                    successTitle: 'Đã lưu khoản chi',
                    successMessage: 'Khoản chi đã được thêm và công nợ của nhóm đã được tính lại.',
                  ),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Thêm khoản chi khác'),
                ),
              ],
              if (tab == 1) ...[
                const SectionTitle('Số dư từng thành viên'),
                Surface(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(children: members.map((m) {
                    final id = asInt(m['id']);
                    final amount = balanceFor(id);
                    return ListTile(
                      leading: Avatar(m['name'].toString()),
                      title: Text(id == user ? '${m['name']} (bạn)' : m['name'].toString()),
                      subtitle: Text(
                        amount == 0 ? 'Đã cân bằng' : amount > 0 ? 'Được nhận ${money(amount, currency)}' : 'Cần trả ${money(-amount, currency)}',
                        style: TextStyle(color: amount >= 0
                            ? (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF73D6BB) : AppColors.success)
                            : Theme.of(context).colorScheme.error),
                      ),
                    );
                  }).toList()),
                ),
                const SectionTitle('Smart Settlement · Xén nợ'),
                Text(g['smartSettlementEnabled'] == true
                    ? 'Đề xuất dựa trên số dư ròng để giảm số giao dịch cần thực hiện.'
                    : 'Smart Settlement đang tắt trong cài đặt nhóm.'),
                const SizedBox(height: 14),
                if (suggestions.isEmpty) const EmptyState(
                  title: 'Cả nhóm đã cân bằng', description: 'Không còn giao dịch cần quyết toán.', icon: Icons.check_circle_outline_rounded,
                ),
                ...suggestions.map((s) {
                  final fromId = asInt(s['fromId']);
                  final toId = asInt(s['toId']);
                  final waiting = settlements.any((p) => p['status'] == 'PAID' && asInt(p['debtorId']) == fromId && asInt(p['creditorId']) == toId);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Surface(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Text('${name(fromId)} → ${name(toId)}', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text(money(asInt(s['amount']), currency),
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.primary)),
                      if (waiting) ...[
                        const SizedBox(height: 12),
                        const Text('Đã ghi nhận thanh toán, đang chờ người nhận xác nhận.'),
                      ] else if (fromId == user) ...[
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () => open(SettlementScreen(
                            groupId: widget.id, creditorId: toId, name: name(toId), maximum: asInt(s['amount']), currency: currency,
                          )),
                          child: const Text('Đánh dấu đã thanh toán'),
                        ),
                      ],
                    ])),
                  );
                }),
                if (settlements.isNotEmpty) const SectionTitle('Lịch sử quyết toán'),
                ...settlements.map((p) {
                  final debtorId = asInt(p['debtorId']);
                  final creditorId = asInt(p['creditorId']);
                  final status = p['status'].toString();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Surface(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${name(debtorId)} → ${name(creditorId)}', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(money(asInt(p['amount']), currency), style: const TextStyle(fontWeight: FontWeight.w800)),
                      Text('${_statusLabel(status)} · ${p['paymentMethod'] ?? 'Không ghi phương thức'}'),
                      Text(dateLabel(p['confirmedAt']?.toString() ?? p['paidAt']?.toString() ?? p['requestedAt']?.toString())),
                      if (status == 'PAID' && creditorId == user) ...[
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: () async {
                            try {
                              await Api.call('/settlements/${p['id']}/confirm', method: 'POST');
                              if (mounted) {
                                await showSuccessDialog(
                                  context,
                                  title: 'Thanh toán đã được xác nhận',
                                  message: 'Công nợ của nhóm đã được cập nhật và giao dịch được đánh dấu hoàn tất.',
                                  actionLabel: 'Hoàn tất',
                                );
                                if (mounted) await refresh();
                              }
                            } catch (e) { if (mounted) showError(context, e); }
                          },
                          icon: const Icon(Icons.verified_rounded),
                          label: const Text('Xác nhận đã nhận tiền'),
                        ),
                      ],
                      if (status == 'PAID' && debtorId == user) ...[
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () async {
                            try {
                              await Api.call('/settlements/${p['id']}/cancel', method: 'POST');
                              if (mounted) {
                                showInfo(context, 'Bản ghi thanh toán đã được hủy.');
                                await refresh();
                              }
                            } catch (e) { if (mounted) showError(context, e); }
                          },
                          child: const Text('Hủy bản ghi thanh toán'),
                        ),
                      ],
                    ])),
                  );
                }),
              ],
              if (tab == 2) ...[
                SectionTitle('Thành viên', trailing: ownerId == user ? IconButton(
                  tooltip: 'Thêm thành viên', onPressed: () => open(
                    AddMemberScreen(groupId: widget.id),
                    successTitle: 'Đã thêm thành viên',
                    successMessage: 'Thành viên đã được thêm vào nhóm thành công.',
                  ),
                  icon: const Icon(Icons.person_add_alt_1_rounded),
                ) : null),
                Surface(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(children: members.map((m) {
                    final id = asInt(m['id']);
                    return ListTile(
                      leading: Avatar(m['name'].toString()),
                      title: Text('${m['name']}${id == user ? ' (bạn)' : ''}'),
                      subtitle: Text('${m['email']} · ${m['role'] == 'OWNER' ? 'Trưởng nhóm' : 'Thành viên'}'),
                      trailing: ownerId == user && id != ownerId ? IconButton(
                        tooltip: 'Xóa khỏi nhóm',
                        icon: const Icon(Icons.person_remove_outlined),
                        onPressed: () => _removeMember(id, m['name'].toString()),
                      ) : null,
                    );
                  }).toList()),
                ),
                const SectionTitle('Mã mời'),
                Surface(child: Row(children: [
                  Expanded(child: SelectableText(g['inviteCode'].toString(), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 2))),
                  IconButton(
                    tooltip: 'Sao chép',
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: g['inviteCode'].toString()));
                      if (context.mounted) showSuccess(context, 'Mã mời đã được sao chép vào clipboard.', title: 'Đã sao chép');
                    },
                    icon: const Icon(Icons.copy_rounded),
                  ),
                ])),
                if (ownerId == user) ...[
                  const SectionTitle('Cài đặt nhóm'),
                  OutlinedButton.icon(
                    onPressed: () => open(GroupSettingsScreen(groupId: widget.id)),
                    icon: const Icon(Icons.settings_outlined),
                    label: const Text('Mở cài đặt nhóm'),
                  ),
                ],
              ],
            ],
          ),
        );
      },
    ),
    ),
  );

  Future<void> _removeMember(int id, String name) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa thành viên?'),
        content: Text('Xóa $name khỏi nhóm? Thành viên có số dư chưa cân bằng sẽ không thể bị xóa.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xóa')),
        ],
      ),
    );
    if (yes != true) return;
    try {
      await Api.call('/groups/${widget.id}/members/$id', method: 'DELETE');
      if (mounted) {
        showSuccess(context, '$name đã được xóa khỏi nhóm.', title: 'Đã cập nhật thành viên');
        await refresh();
      }
    } catch (e) { if (mounted) showError(context, e); }
  }

  static String _statusLabel(String status) => switch (status) {
    'PENDING' => 'Chờ thanh toán',
    'PAID' => 'Chờ xác nhận',
    'CONFIRMED' => 'Đã xác nhận',
    'CANCELLED' => 'Đã hủy',
    _ => status,
  };
}

class ExpenseDetailScreen extends StatefulWidget {
  final Map<String, dynamic> detail;
  final Map<String, dynamic> expense;
  const ExpenseDetailScreen({super.key, required this.detail, required this.expense});
  @override State<ExpenseDetailScreen> createState() => _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends State<ExpenseDetailScreen> {
  bool deleting = false;

  @override
  Widget build(BuildContext context) {
    final group = Map<String, dynamic>.from(widget.detail['group'] as Map);
    final members = maps(widget.detail['members']);
    final currency = group['currency'].toString();
    final expense = widget.expense;
    final canEdit = Session.userId == asInt(expense['payerId']) || Session.userId == asInt(group['ownerId']);
    String name(int id) => members.firstWhere((m) => asInt(m['id']) == id, orElse: () => {'name': 'Thành viên'})['name'].toString();
    final shares = maps(expense['shares']);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết khoản chi'),
        actions: canEdit ? [
          IconButton(
            tooltip: 'Chỉnh sửa',
            onPressed: () async {
              final changed = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) =>
                AddExpenseScreen(detail: widget.detail, existing: expense)));
              if (changed == true && mounted) Navigator.pop(context, true);
            },
            icon: const Icon(Icons.edit_outlined),
          ),
        ] : null,
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 34),
              children: [
                Center(
                  child: Container(
                    width: 74,
                    height: 74,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(Icons.restaurant_rounded, color: AppColors.primary, size: 34),
                  ),
                ),
                const SizedBox(height: 18),
                Text(expense['title'].toString(), textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  money(asInt(expense['amount']), currency),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: AppColors.primary),
                ),
                const SizedBox(height: 22),
                Surface(
                  interactive: false,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _row('Người trả', name(asInt(expense['payerId']))),
                    _row('Danh mục', expense['categoryName']?.toString() ?? 'Khác'),
                    _row('Ngày chi', expense['expenseDate'].toString()),
                    if (expense['description'] != null && expense['description'].toString().isNotEmpty)
                      _row('Ghi chú', expense['description'].toString()),
                    if (expense['receiptUrl'] != null && expense['receiptUrl'].toString().isNotEmpty)
                      _row('Hóa đơn', expense['receiptUrl'].toString()),
                  ]),
                ),
                const SectionTitle('Chia cho'),
                ...shares.map((share) {
                  final userName = name(asInt(share['userId']));
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Surface(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(children: [
                        Avatar(userName, radius: 18),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(userName, style: const TextStyle(fontWeight: FontWeight.w800)),
                          Text(_splitLabel(share['splitType']?.toString() ?? ''), style: Theme.of(context).textTheme.bodySmall),
                        ])),
                        Text(money(asInt(share['amount']), currency), style: const TextStyle(fontWeight: FontWeight.w900)),
                      ]),
                    ),
                  );
                }),
                if (maps(expense['items']).isNotEmpty) ...[
                  const SectionTitle('Theo từng món'),
                  ...maps(expense['items']).map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Surface(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(child: Text(item['itemName'].toString(), style: Theme.of(context).textTheme.titleMedium)),
                        Text(money(asInt(item['totalPrice']), currency), style: const TextStyle(fontWeight: FontWeight.w900)),
                      ]),
                      const SizedBox(height: 8),
                      ...maps(item['participants']).map((participant) => Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('${name(asInt(participant['userId']))}: ${money(asInt(participant['shareAmount']), currency)}'),
                      )),
                    ])),
                  )),
                ],
                if (canEdit) ...[
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: deleting ? null : _delete,
                    icon: deleting
                        ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                    label: const Text('Xóa khoản chi', style: TextStyle(color: AppColors.error)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _splitLabel(String value) => switch (value) {
    'EQUAL' => 'Chia đều',
    'AMOUNT' => 'Theo số tiền',
    'PERCENT' => 'Theo phần trăm',
    'WEIGHT' => 'Theo trọng số',
    'ITEM' => 'Theo từng món',
    _ => value,
  };

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 90, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700))),
      Expanded(child: Text(value)),
    ]),
  );

  Future<void> _delete() async {
    final groupId = asInt(Map<String, dynamic>.from(widget.detail['group'] as Map)['id']);
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa khoản chi?'),
        content: const Text('Công nợ của nhóm sẽ được tính lại sau khi xóa.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xóa')),
        ],
      ),
    );
    if (yes != true) return;
    setState(() => deleting = true);
    try {
      await Api.call('/groups/$groupId/expenses/${widget.expense['id']}', method: 'DELETE');
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => deleting = false);
    }
  }
}

class SettlementScreen extends StatefulWidget {
  final int groupId;
  final int creditorId;
  final String name;
  final int maximum;
  final String currency;
  const SettlementScreen({super.key, required this.groupId, required this.creditorId,
    required this.name, required this.maximum, required this.currency});
  @override State<SettlementScreen> createState() => _SettlementScreenState();
}

class _SettlementScreenState extends State<SettlementScreen> {
  late final amount = TextEditingController(text: widget.currency == 'VND'
      ? '${widget.maximum}' : '${widget.maximum ~/ 100}.${(widget.maximum % 100).toString().padLeft(2, '0')}');
  final form = GlobalKey<FormState>();
  String method = 'BANK_TRANSFER';
  bool busy = false;
  @override void dispose() { amount.dispose(); super.dispose(); }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    final paidAmount = parseMoney(amount.text, widget.currency);
    if (paidAmount == null) return;
    setState(() => busy = true);
    try {
      final response = await Api.call('/groups/${widget.groupId}/settlements', method: 'POST', body: {
        'creditorId': widget.creditorId,
        'amount': paidAmount,
        'paymentMethod': method,
      });
      if (!mounted) return;
      String? reference;
      if (response is Map && response['id'] != null) reference = '#${response['id']}';
      await Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentSuccessScreen(
            amount: paidAmount,
            currency: widget.currency,
            name: widget.name,
            reference: reference,
          ),
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const methods = [
      ('CASH', 'Tiền mặt', Icons.payments_outlined),
      ('BANK_TRANSFER', 'Chuyển khoản ngân hàng', Icons.account_balance_rounded),
      ('MOMO', 'MoMo', Icons.wallet_rounded),
      ('ZALOPAY', 'ZaloPay', Icons.account_balance_wallet_outlined),
      ('OTHER', 'Khác', Icons.more_horiz_rounded),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Thanh toán')),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 34),
              child: Form(
                key: form,
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Text('Thanh toán cho', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 8),
                  Avatar(widget.name, radius: 28),
                  const SizedBox(height: 10),
                  Text(widget.name, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 18),
                  Text(
                    money(widget.maximum, widget.currency),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.primary, fontSize: 30, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 28),
                  TextFormField(
                    controller: amount,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: 'Số tiền đã trả', suffixText: widget.currency),
                    validator: (v) {
                      final value = parseMoney(v ?? '', widget.currency);
                      return value == null || value > widget.maximum ? 'Nhập số tiền tối đa ${money(widget.maximum, widget.currency)}.' : null;
                    },
                  ),
                  const SizedBox(height: 22),
                  Text('Phương thức thanh toán', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 10),
                  ...methods.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: busy ? null : () => setState(() => method = item.$1),
                        child: Ink(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: method == item.$1 ? AppColors.primary : Theme.of(context).dividerColor,
                              width: method == item.$1 ? 1.5 : 1,
                            ),
                          ),
                          child: RadioListTile<String>(
                            value: item.$1,
                            groupValue: method,
                            onChanged: busy ? null : (v) => setState(() => method = v!),
                            secondary: Icon(item.$3, color: method == item.$1 ? AppColors.primary : null),
                            title: Text(item.$2, style: const TextStyle(fontWeight: FontWeight.w800)),
                          ),
                        ),
                      ),
                    ),
                  )),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 20),
                      SizedBox(width: 10),
                      Expanded(child: Text('SplitDebt chỉ ghi nhận giao dịch bạn đã thực hiện bên ngoài hệ thống.')),
                    ]),
                  ),
                  const SizedBox(height: 24),
                  BusyButton(busy: busy, label: 'Đã thanh toán', onPressed: save),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class StatisticsScreen extends StatefulWidget {
  final int groupId;
  const StatisticsScreen({super.key, required this.groupId});
  @override State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  String range = 'MONTH';
  late Future<Map<String, dynamic>> future;
  @override void initState() { super.initState(); future = load(); }
  Future<Map<String, dynamic>> load() async => Map<String, dynamic>.from(await Api.call('/groups/${widget.groupId}/statistics?range=$range') as Map);
  void setRange(String value) { setState(() { range = value; future = load(); }); }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Thống kê')),
    body: FutureBuilder<Map<String, dynamic>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return EmptyState(title: 'Không thể tải thống kê', description: snapshot.error.toString());
        final d = snapshot.data!;
        final currency = d['currency'].toString();
        final categories = maps(d['byCategory']);
        final payers = maps(d['byPayer']);
        final maxCategory = categories.fold<int>(1, (value, x) {
          final amount = asInt(x['amount']);
          return amount > value ? amount : value;
        });
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 34),
              children: [
                PillSegment<String>(
                  items: const [
                    ('WEEK', 'Tuần'),
                    ('MONTH', 'Tháng'),
                    ('ALL', 'Tất cả'),
                  ],
                  value: range,
                  onChanged: setRange,
                ),
                const SizedBox(height: 22),
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Column(children: [
                    Text('TỔNG CHI TIÊU', style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                    )),
                    const SizedBox(height: 8),
                    FittedBox(
                      child: Text(
                        money(asInt(d['totalExpense']), currency),
                        style: const TextStyle(color: AppColors.primary, fontSize: 34, fontWeight: FontWeight.w900),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text('${d['from']} → ${d['to']}', style: Theme.of(context).textTheme.bodyMedium),
                  ]),
                ),
                const SectionTitle('Chi tiêu theo danh mục'),
                if (categories.isEmpty)
                  const EmptyState(
                    title: 'Chưa có dữ liệu',
                    description: 'Thêm khoản chi để xem phân bố theo danh mục.',
                    icon: Icons.donut_large_rounded,
                  )
                else
                  Surface(
                    interactive: false,
                    child: Column(
                      children: categories.map((x) {
                        final amount = asInt(x['amount']);
                        final ratio = amount / maxCategory;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Expanded(child: Text(x['label'].toString(), style: const TextStyle(fontWeight: FontWeight.w800))),
                              Text(money(amount, currency), style: const TextStyle(fontWeight: FontWeight.w900)),
                            ]),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(99),
                              child: LinearProgressIndicator(
                                value: ratio.clamp(0.0, 1.0).toDouble(),
                                minHeight: 8,
                                backgroundColor: AppColors.primaryLight,
                              ),
                            ),
                          ]),
                        );
                      }).toList(),
                    ),
                  ),
                const SectionTitle('Top người chi tiêu'),
                if (payers.isEmpty)
                  const EmptyState(
                    title: 'Chưa có dữ liệu người trả',
                    description: 'Các thành viên đã thanh toán sẽ xuất hiện tại đây.',
                    icon: Icons.people_outline_rounded,
                  )
                else
                  ...payers.take(5).toList().asMap().entries.map((entry) {
                    final index = entry.key;
                    final x = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Surface(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(children: [
                          Container(
                            width: 30,
                            height: 30,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: index == 0 ? AppColors.primary : AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: index == 0 ? Colors.white : AppColors.primary,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Avatar(x['label'].toString(), radius: 17),
                          const SizedBox(width: 10),
                          Expanded(child: Text(x['label'].toString(), style: const TextStyle(fontWeight: FontWeight.w800))),
                          Text(money(asInt(x['amount']), currency), style: const TextStyle(fontWeight: FontWeight.w900)),
                        ]),
                      ),
                    );
                  }),
              ],
            ),
          ),
        );
      },
    ),
  );
}

class GroupSettingsScreen extends StatefulWidget {
  final int groupId;
  const GroupSettingsScreen({super.key, required this.groupId});
  @override State<GroupSettingsScreen> createState() => _GroupSettingsScreenState();
}

class _GroupSettingsScreenState extends State<GroupSettingsScreen> {
  late Future<Map<String, dynamic>> future;
  bool busy = false;
  @override void initState() { super.initState(); future = load(); }
  Future<Map<String, dynamic>> load() async => Map<String, dynamic>.from(await Api.call('/groups/${widget.groupId}/settings') as Map);

  Future<void> update(Map<String, dynamic> body) async {
    setState(() => busy = true);
    try {
      await Api.call('/groups/${widget.groupId}/settings', method: 'PATCH', body: body);
      if (mounted) {
        showSuccess(context, 'Cài đặt nhóm đã được lưu.');
        setState(() => future = load());
      }
    } catch (e) { if (mounted) showError(context, e); }
    finally { if (mounted) setState(() => busy = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Cài đặt nhóm')),
    body: FutureBuilder<Map<String, dynamic>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return EmptyState(title: 'Không thể tải cài đặt', description: snapshot.error.toString());
        final d = snapshot.data!;
        return ListView(padding: const EdgeInsets.all(24), children: [
          Surface(child: Column(children: [
            ListTile(title: const Text('Tiền tệ'), subtitle: Text('${d['currencyCode']} · ${d['decimalScale']} chữ số thập phân')),
            SwitchListTile(
              value: d['smartSettlementEnabled'] == true,
              onChanged: busy ? null : (v) => update({'smartSettlementEnabled': v}),
              title: const Text('Smart Settlement'),
              subtitle: const Text('Đề xuất xén nợ dựa trên số dư ròng.'),
            ),
            SwitchListTile(
              value: d['imageOptimizationEnabled'] == true,
              onChanged: busy ? null : (v) => update({'imageOptimizationEnabled': v}),
              title: const Text('Tối ưu ảnh hóa đơn'),
            ),
          ])),
        ]);
      },
    ),
  );
}
