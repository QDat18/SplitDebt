import 'dart:math' as math;
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
  Map<String, dynamic>? _latestDetail;
  int tab = 0;
  int get user => Session.userId ?? -1;

  @override void initState() { super.initState(); future = Api.call('/groups/${widget.id}'); }

  Future<void> refresh() async {
    final next = Api.call('/groups/${widget.id}');
    setState(() { future = next; });
    try { await next; } catch (_) {}
  }

  Future<void> _openLatestExpense() async {
    final detail = _latestDetail;
    if (detail == null) return;
    await open(
      AddExpenseScreen(detail: detail),
      successTitle: 'Đã lưu khoản chi',
      successMessage: 'Khoản chi đã được thêm và công nợ của nhóm đã được tính lại.',
    );
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
    body: PremiumBackground(
      child: SafeArea(
        child: Column(
          children: [
            LuminousBrandHeader(
              section: 'Groups',
              trailing: IconButton(
                tooltip: 'Quay lại',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ),
            Expanded(
              child: FutureBuilder<dynamic>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: EmptyState(
          title: 'Không thể tải nhóm', description: snapshot.error.toString(),
          action: FilledButton(onPressed: refresh, child: const Text('Thử lại')),
        ));
        final d = Map<String, dynamic>.from(snapshot.data as Map);
        _latestDetail = d;
        final g = Map<String, dynamic>.from(d['group'] as Map);
        final members = maps(d['members']);
        final currency = g['currency'].toString();
        final expenses = maps(d['expenses']);
        final settlements = maps(d['settlements']);
        final suggestions = maps(d['suggestions']);
        final balancesSource = d['effectiveBalances'] ?? d['balances'];
        final balancesRaw = Map<dynamic, dynamic>.from(balancesSource as Map);
        int balanceFor(int id) => asInt(balancesRaw['$id'] ?? balancesRaw[id] ?? 0);
        String name(int id) => members.firstWhere((m) => asInt(m['id']) == id, orElse: () => {'name': 'Thành viên #$id'})['name'].toString();
        final ownerId = asInt(g['ownerId']);
        final payable = suggestions
            .where((x) => asInt(x['fromId']) == user)
            .fold<int>(0, (sum, x) => sum + asInt(x['amount']));
        final receivable = suggestions
            .where((x) => asInt(x['toId']) == user)
            .fold<int>(0, (sum, x) => sum + asInt(x['amount']));
        final paidByMe = settlements
            .where((p) => asInt(p['debtorId']) == user && {'PAID', 'CONFIRMED'}.contains(p['status']))
            .fold<int>(0, (sum, p) => sum + asInt(p['amount']));
        final receivedByMe = settlements
            .where((p) => asInt(p['creditorId']) == user && p['status'] == 'CONFIRMED')
            .fold<int>(0, (sum, p) => sum + asInt(p['amount']));
        final pendingOut = settlements
            .where((p) => asInt(p['debtorId']) == user && p['status'] == 'PAID')
            .fold<int>(0, (sum, p) => sum + asInt(p['amount']));
        final pendingIn = settlements
            .where((p) => asInt(p['creditorId']) == user && p['status'] == 'PAID')
            .fold<int>(0, (sum, p) => sum + asInt(p['amount']));

        return RefreshIndicator(
          onRefresh: refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              _GroupReferenceHero(
                name: g['name'].toString(),
                description: g['description']?.toString() ?? '',
                memberCount: members.length,
                total: asInt(g['total']),
                currency: currency,
                inviteCode: g['inviteCode']?.toString() ?? '',
                onInvite: () async {
                  await Clipboard.setData(ClipboardData(text: g['inviteCode']?.toString() ?? ''));
                  if (context.mounted) {
                    showSuccess(context, 'Đã sao chép mã mời của nhóm.', title: 'Mã mời');
                  }
                },
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
                      title: Text(e['title'].toString(), style: const TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: Text(
                        'Nhóm: ${g['name']}\nNgười trả: ${name(asInt(e['payerId']))} · ${e['categoryName'] ?? 'Khác'}\nThời gian: ${dateLabel(e['createdAt']?.toString() ?? e['expenseDate']?.toString())}',
                      ),
                      isThreeLine: true,
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(money(asInt(e['amount']), currency), style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary)),
                          const SizedBox(height: 4),
                          const Icon(Icons.chevron_right_rounded, size: 20),
                        ],
                      ),
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
                const SizedBox(height: 16),
                _SettlementSnapshot(
                  payable: payable,
                  receivable: receivable,
                  paid: paidByMe,
                  received: receivedByMe,
                  pendingOut: pendingOut,
                  pendingIn: pendingIn,
                  currency: currency,
                ),
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
                const SizedBox(height: 22),
                Surface(
                  interactive: false,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          gradient: AppColors.fabGradient,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: .18),
                              blurRadius: 22,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF173025)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text('Smart Simplify', style: Theme.of(context).textTheme.titleLarge),
                                ),
                                StatusPill(
                                  label: g['smartSettlementEnabled'] == true ? 'Đang bật' : 'Đang tắt',
                                  kind: g['smartSettlementEnabled'] == true ? FeedbackKind.success : FeedbackKind.warning,
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(
                              g['smartSettlementEnabled'] == true
                                  ? '${suggestions.length} giao dịch tối ưu từ số dư ròng của nhóm.'
                                  : 'Bật Smart Settlement trong cài đặt nhóm để tối ưu số lần chuyển tiền.',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (suggestions.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _SmartSettlementNetwork(
                    suggestions: suggestions,
                    members: members,
                    currentUserId: user,
                    currency: currency,
                  ),
                ],
                const SectionTitle('Gợi ý thanh toán'),
                if (suggestions.isEmpty)
                  EmptyState(
                    title: pendingOut > 0 || pendingIn > 0 ? 'Không còn khoản cần xử lý ngay' : 'Cả nhóm đã hoàn tất',
                    description: pendingOut > 0 || pendingIn > 0
                        ? 'Khoản đã thanh toán đang chờ người nhận xác nhận. Số cần trả/nhận hiện tại đã về 0 để tránh thanh toán lặp.'
                        : 'Bạn không còn nợ và cũng không còn khoản phải thu trong nhóm này.',
                    icon: pendingOut > 0 || pendingIn > 0 ? Icons.hourglass_top_rounded : Icons.verified_rounded,
                  ),
                ...suggestions.map((s) {
                  final fromId = asInt(s['fromId']);
                  final toId = asInt(s['toId']);
                  final waiting = settlements.any((p) => p['status'] == 'PAID' && asInt(p['debtorId']) == fromId && asInt(p['creditorId']) == toId);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Surface(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Text(
                        fromId == user ? 'Bạn trả cho ${name(toId)}' : toId == user ? 'Bạn nhận từ ${name(fromId)}' : '${name(fromId)} → ${name(toId)}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
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
                          child: Text('Tôi trả ${money(asInt(s['amount']), currency)}'),
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
                      Row(children: [
                        Expanded(child: Text(
                          debtorId == user
                              ? 'Bạn đã trả cho ${name(creditorId)}'
                              : creditorId == user
                                  ? 'Bạn nhận từ ${name(debtorId)}'
                                  : '${name(debtorId)} trả cho ${name(creditorId)}',
                          style: Theme.of(context).textTheme.titleMedium,
                        )),
                        StatusPill(
                          label: status == 'CONFIRMED' ? 'Hoàn thành' : _statusLabel(status),
                          kind: status == 'CONFIRMED'
                              ? FeedbackKind.success
                              : status == 'PAID'
                                  ? FeedbackKind.warning
                                  : status == 'CANCELLED'
                                      ? FeedbackKind.error
                                      : FeedbackKind.info,
                        ),
                      ]),
                      const SizedBox(height: 7),
                      Text(
                        money(asInt(p['amount']), currency),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: debtorId == user ? Theme.of(context).colorScheme.error : AppColors.success,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('${p['paymentMethod'] ?? 'Không ghi phương thức'} · ${dateLabel(p['confirmedAt']?.toString() ?? p['paidAt']?.toString() ?? p['requestedAt']?.toString())}'),
                      if (status == 'CONFIRMED') ...[
                        const SizedBox(height: 8),
                        const Row(children: [
                          Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
                          SizedBox(width: 7),
                          Expanded(child: Text('Đã trừ vào công nợ. Số dư của hai bên đã được cập nhật.')),
                        ]),
                      ] else if (status == 'PAID') ...[
                        const SizedBox(height: 8),
                        const Row(children: [
                          Icon(Icons.schedule_rounded, color: AppColors.warning, size: 18),
                          SizedBox(width: 7),
                          Expanded(child: Text('Đã ghi nhận thanh toán; đang chờ người nhận xác nhận.')),
                        ]),
                      ],
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
                      subtitle: Text(
                        '${m['role'] == 'OWNER' ? 'Trưởng nhóm' : 'Thành viên'} · ${m['email']}'
                        '${m['phone'] == null || m['phone'].toString().isEmpty ? '' : ' · ${m['phone']}'}',
                      ),
                      trailing: ownerId == user && id != ownerId ? IconButton(
                        tooltip: 'Xóa khỏi nhóm',
                        icon: const Icon(Icons.person_remove_outlined),
                        onPressed: () => _removeMember(id, m['name'].toString()),
                      ) : null,
                    );
                  }).toList()),
                ),
                const SectionTitle('Thêm thành viên'),
                Surface(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  const Text('Cách 1 · Thành viên tự tham gia bằng mã nhóm', style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: SelectableText(g['inviteCode'].toString(), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 2))),
                    IconButton(
                      tooltip: 'Sao chép mã nhóm',
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: g['inviteCode'].toString()));
                        if (context.mounted) showSuccess(context, 'Mã nhóm đã được sao chép. Thành viên có thể nhập mã này ở “Tham gia nhóm”.', title: 'Đã sao chép');
                      },
                      icon: const Icon(Icons.copy_rounded),
                    ),
                  ]),
                  if (ownerId == user) ...[
                    const Divider(height: 26),
                    const Text('Cách 2 · Trưởng nhóm thêm trực tiếp', style: TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () => open(
                        AddMemberScreen(groupId: widget.id),
                        successTitle: 'Đã thêm thành viên',
                        successMessage: 'Tài khoản đã được thêm vào nhóm.',
                      ),
                      icon: const Icon(Icons.person_search_rounded),
                      label: const Text('Thêm bằng email hoặc số điện thoại'),
                    ),
                  ],
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
              if (tab == 3) ...[
                const SizedBox(height: 18),
                Surface(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => StatisticsScreen(groupId: widget.id)),
                  ),
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/reference/analytics-donut-3d.png',
                        width: 78,
                        height: 78,
                        fit: BoxFit.cover,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Visual Analytics', style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 5),
                            Text('Phân tích tổng chi, danh mục và thành viên chi nhiều nhất.', style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    ),
            ),
          ],
        ),
      ),
    ),
    bottomNavigationBar: LuminousExtendedBottomNav(
      selectedIndex: 1,
      onSelected: (index) {
        if (index == 1) return;
        Navigator.pop(context, index);
      },
      onAdd: _openLatestExpense,
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

class _SmartSettlementNetwork extends StatelessWidget {
  const _SmartSettlementNetwork({
    required this.suggestions,
    required this.members,
    required this.currentUserId,
    required this.currency,
  });

  final List<Map<String, dynamic>> suggestions;
  final List<Map<String, dynamic>> members;
  final int currentUserId;
  final String currency;

  Map<String, dynamic> member(int id) => members.firstWhere(
        (m) => asInt(m['id']) == id,
        orElse: () => {'id': id, 'name': 'Thành viên'},
      );

  @override
  Widget build(BuildContext context) {
    final first = suggestions.first;
    final fromId = asInt(first['fromId']);
    final toId = asInt(first['toId']);
    final from = member(fromId);
    final to = member(toId);
    final me = member(currentUserId);
    return Surface(
      interactive: false,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('OPTIMIZED NETWORK', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.primary)),
          const SizedBox(height: 10),
          SizedBox(
            height: 196,
            child: Stack(
              children: [
                const Positioned.fill(child: CustomPaint(painter: _SettlementNetworkPainter())),
                Align(
                  alignment: Alignment.topLeft,
                  child: _NetworkPerson(
                    name: fromId == currentUserId ? 'Bạn' : from['name'].toString(),
                    avatarUrl: from['avatarUrl']?.toString(),
                    color: AppColors.secondary,
                  ),
                ),
                Align(
                  alignment: Alignment.topRight,
                  child: _NetworkPerson(
                    name: toId == currentUserId ? 'Bạn' : to['name'].toString(),
                    avatarUrl: to['avatarUrl']?.toString(),
                    color: AppColors.tertiary,
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: _NetworkPerson(
                    name: me['name']?.toString() ?? 'Bạn',
                    avatarUrl: me['avatarUrl']?.toString(),
                    color: AppColors.primary,
                    emphasized: true,
                  ),
                ),
                Positioned(
                  top: 78,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLowest.withValues(alpha: .82),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppColors.glassBorder),
                      ),
                      child: Text(
                        money(asInt(first['amount']), currency),
                        style: const TextStyle(fontFamily: 'Geist', color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NetworkPerson extends StatelessWidget {
  const _NetworkPerson({
    required this.name,
    required this.avatarUrl,
    required this.color,
    this.emphasized = false,
  });
  final String name;
  final String? avatarUrl;
  final Color color;
  final bool emphasized;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 96,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(emphasized ? 4 : 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color.withValues(alpha: .72), width: emphasized ? 2 : 1),
                boxShadow: [BoxShadow(color: color.withValues(alpha: emphasized ? .30 : .14), blurRadius: emphasized ? 22 : 12)],
              ),
              child: Avatar(name, radius: emphasized ? 28 : 23, imageUrl: avatarUrl),
            ),
            const SizedBox(height: 6),
            Text(name, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
          ],
        ),
      );
}

class _SettlementNetworkPainter extends CustomPainter {
  const _SettlementNetworkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.outline.withValues(alpha: .42)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    final left = Offset(48, 48);
    final right = Offset(size.width - 48, 48);
    final bottom = Offset(size.width / 2, size.height - 50);
    _dotted(canvas, left, bottom, paint);
    _dotted(canvas, right, bottom, paint);
  }

  void _dotted(Canvas canvas, Offset a, Offset b, Paint paint) {
    const dash = 4.0;
    const gap = 5.0;
    final delta = b - a;
    final distance = delta.distance;
    if (distance == 0) return;
    final direction = delta / distance;
    var traveled = 0.0;
    while (traveled < distance) {
      final start = a + direction * traveled;
      final end = a + direction * math.min(traveled + dash, distance);
      canvas.drawLine(start, end, paint);
      traveled += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GroupReferenceHero extends StatelessWidget {
  const _GroupReferenceHero({
    required this.name,
    required this.description,
    required this.memberCount,
    required this.total,
    required this.currency,
    required this.inviteCode,
    required this.onInvite,
  });

  final String name;
  final String description;
  final int memberCount;
  final int total;
  final String currency;
  final String inviteCode;
  final VoidCallback onInvite;

  @override
  Widget build(BuildContext context) => StaggerReveal(
        index: 0,
        child: Surface(
          interactive: false,
          padding: EdgeInsets.zero,
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primary.withValues(alpha: .055),
                  Colors.transparent,
                ],
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surfaceHigh.withValues(alpha: .86),
                    border: Border.all(color: AppColors.glassBorder),
                    boxShadow: [
                      BoxShadow(color: AppColors.primary.withValues(alpha: .15), blurRadius: 24),
                    ],
                  ),
                  child: const Icon(Icons.flight_land_rounded, color: AppColors.primary, size: 34),
                ),
                const SizedBox(height: 15),
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.6,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  description.trim().isEmpty ? '$memberCount thành viên' : '$description · $memberCount thành viên',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLowest.withValues(alpha: .62),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.glassBorder),
                  ),
                  child: Column(
                    children: [
                      Text('TOTAL TRIP SPEND', style: Theme.of(context).textTheme.labelSmall),
                      const SizedBox(height: 7),
                      AnimatedMoneyText(
                        amount: total,
                        currency: currency,
                        style: const TextStyle(
                          fontFamily: 'Geist',
                          color: AppColors.primary,
                          fontSize: 31,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.1,
                          shadows: [Shadow(color: Color(0x334EDEA3), blurRadius: 18)],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 13),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onInvite,
                    icon: const Icon(Icons.person_add_alt_1_rounded),
                    label: Text(inviteCode.isEmpty ? 'Invite Members' : 'Invite Members · $inviteCode'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
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
                    _row('Nhóm', group['name'].toString()),
                    _row('Khoản chi', expense['title'].toString()),
                    _row('Người trả', name(asInt(expense['payerId']))),
                    _row('Danh mục', expense['categoryName']?.toString() ?? 'Khác'),
                    _row('Ngày chi', expense['expenseDate'].toString()),
                    _row('Ghi nhận lúc', dateLabel(expense['createdAt']?.toString())),
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
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Thanh toán')),
      body: PremiumBackground(
        child: SafeArea(
          top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 34),
              child: Form(
                key: form,
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Text('Bạn sẽ trả cho', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
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
                    decoration: InputDecoration(
                      labelText: 'Mình trả bao nhiêu?',
                      helperText: 'Sau khi ghi nhận, số cần trả sẽ được trừ ngay để tránh trả lặp; người nhận vẫn cần xác nhận.',
                      suffixText: widget.currency,
                    ),
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
                  BusyButton(busy: busy, label: 'Ghi nhận số tiền tôi đã trả', onPressed: save),
                ]),
              ),
            ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SettlementSnapshot extends StatelessWidget {
  final int payable;
  final int receivable;
  final int paid;
  final int received;
  final int pendingOut;
  final int pendingIn;
  final String currency;

  const _SettlementSnapshot({
    required this.payable,
    required this.receivable,
    required this.paid,
    required this.received,
    required this.pendingOut,
    required this.pendingIn,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final waiting = pendingOut > 0 || pendingIn > 0;
    final done = payable == 0 && receivable == 0 && !waiting;
    return Surface(
      interactive: false,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Tình trạng của bạn', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 3),
            Text(done
                ? 'Đã hoàn thành toàn bộ công nợ trong nhóm.'
                : waiting && payable == 0 && receivable == 0
                    ? 'Không còn khoản cần xử lý ngay; đang chờ xác nhận.'
                    : 'Các số dưới đây là số còn lại sau khi trừ thanh toán.'),
          ])),
          StatusPill(
            label: done ? 'Đã hoàn tất' : waiting ? 'Chờ xác nhận' : 'Đang cân đối',
            kind: done ? FeedbackKind.success : waiting ? FeedbackKind.warning : FeedbackKind.info,
          ),
        ]),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _MiniMoney(label: 'Mình cần trả', value: payable, currency: currency, icon: Icons.north_east_rounded, negative: true),
            _MiniMoney(label: 'Mình sẽ nhận', value: receivable, currency: currency, icon: Icons.south_west_rounded),
            _MiniMoney(label: 'Mình đã trả', value: paid, currency: currency, icon: Icons.payments_rounded, negative: true),
            _MiniMoney(label: 'Mình đã thu về', value: received, currency: currency, icon: Icons.account_balance_wallet_rounded),
          ],
        ),
        if (waiting) ...[
          const SizedBox(height: 14),
          Text(
            'Chờ xác nhận: ${pendingOut > 0 ? 'đã trả ${money(pendingOut, currency)}' : ''}'
            '${pendingOut > 0 && pendingIn > 0 ? ' · ' : ''}'
            '${pendingIn > 0 ? 'sắp nhận ${money(pendingIn, currency)}' : ''}.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ]),
    );
  }
}

class _MiniMoney extends StatelessWidget {
  final String label;
  final int value;
  final String currency;
  final IconData icon;
  final bool negative;

  const _MiniMoney({required this.label, required this.value, required this.currency, required this.icon, this.negative = false});

  @override
  Widget build(BuildContext context) => Container(
    width: 220,
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: .45),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(children: [
      Icon(icon, size: 19, color: value == 0 ? Theme.of(context).colorScheme.onSurfaceVariant : negative ? Theme.of(context).colorScheme.error : AppColors.success),
      const SizedBox(width: 9),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 2),
        Text(money(value, currency), style: const TextStyle(fontWeight: FontWeight.w900)),
      ])),
    ]),
  );
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
    backgroundColor: Colors.transparent,
    appBar: AppBar(title: const Text('Thống kê')),
    body: PremiumBackground(
      child: FutureBuilder<Map<String, dynamic>>(
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
                    ('DAY', 'Ngày'),
                    ('MONTH', 'Tháng'),
                    ('YEAR', 'Năm'),
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
                    Text('MÌNH ĐÃ CHI', style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                    )),
                    const SizedBox(height: 8),
                    FittedBox(
                      child: Text(
                        money(asInt(d['mySpent'] ?? 0), currency),
                        style: const TextStyle(color: AppColors.primary, fontSize: 34, fontWeight: FontWeight.w900),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text('${d['from']} → ${d['to']}', style: Theme.of(context).textTheme.bodyMedium),
                  ]),
                ),
                if (categories.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Surface(
                    interactive: false,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final chart = _ExpenseDonutChart(
                          entries: categories,
                          currency: currency,
                        );
                        return constraints.maxWidth < 520
                            ? Column(children: [chart])
                            : chart;
                      },
                    ),
                  ),
                ],
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
    ),
  );
}

class _ExpenseDonutChart extends StatelessWidget {
  const _ExpenseDonutChart({required this.entries, required this.currency});

  final List<Map<String, dynamic>> entries;
  final String currency;

  static const palette = <Color>[
    AppColors.primary,
    AppColors.tertiary,
    AppColors.secondary,
    AppColors.info,
    Color(0xFF8FA6FF),
  ];

  @override
  Widget build(BuildContext context) {
    final total = entries.fold<int>(0, (sum, item) => sum + asInt(item['amount']));
    final legend = entries.take(5).toList();
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;
        final chart = SizedBox.square(
          dimension: compact ? 164 : 184,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size.square(compact ? 164 : 184),
                painter: _DonutPainter(entries: entries),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'TỔNG',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(fontSize: 10),
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    child: Text(
                      money(total, currency),
                      style: const TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
        final details = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Cơ cấu chi tiêu', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('Tỷ trọng các danh mục trong khoảng thời gian đã chọn.', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            ...legend.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final amount = asInt(item['amount']);
              final pct = total == 0 ? 0 : (amount * 100 / total).round();
              final color = palette[index % palette.length];
              return Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: Row(
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        item['label'].toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text('$pct%', style: TextStyle(color: color, fontWeight: FontWeight.w800)),
                  ],
                ),
              );
            }),
          ],
        );
        return compact
            ? Column(children: [chart, const SizedBox(height: 18), details])
            : Row(children: [chart, const SizedBox(width: 26), Expanded(child: details)]);
      },
    );
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({required this.entries});

  final List<Map<String, dynamic>> entries;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) * .39;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final width = math.max(14.0, radius * .22);
    final total = entries.fold<int>(0, (sum, item) => sum + asInt(item['amount']));
    final background = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..color = AppColors.surfaceHighest;
    canvas.drawCircle(center, radius, background);
    if (total <= 0) return;

    var start = -math.pi / 2;
    const gap = .035;
    for (var i = 0; i < entries.length; i++) {
      final value = asInt(entries[i]['amount']);
      if (value <= 0) continue;
      final sweep = math.pi * 2 * value / total;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..color = _ExpenseDonutChart.palette[i % _ExpenseDonutChart.palette.length];
      canvas.drawArc(rect, start + gap / 2, math.max(0, sweep - gap), false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) => oldDelegate.entries != entries;
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
        setState(() { future = load(); });
      }
    } catch (e) { if (mounted) showError(context, e); }
    finally { if (mounted) setState(() => busy = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.transparent,
    appBar: AppBar(title: const Text('Cài đặt nhóm')),
    body: PremiumBackground(
      child: FutureBuilder<Map<String, dynamic>>(
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
    ),
  );
}
