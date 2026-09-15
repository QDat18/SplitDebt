import 'dart:async';
import '../../core/theme/pdf_components.dart';
import '../notifications/notification_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/network/dio_client.dart';
import '../../core/theme/app_colors.dart';
import '../auth/data/auth_repository.dart';
import '../settlement/data/settlement_api_service.dart';
import '../settlement/models/settlement_models.dart';
import '../settlement/presentation/payment_dialog.dart';

class GroupSettlementScreen extends StatefulWidget {
  final int? groupId;
  final bool isActive;
  const GroupSettlementScreen({super.key, this.groupId, this.isActive = true});
  @override
  State<GroupSettlementScreen> createState() => _GroupSettlementScreenState();
}

class _GroupSettlementScreenState extends State<GroupSettlementScreen>
    with WidgetsBindingObserver {
  final _api = SettlementApiService();
  final _currency =
      NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
  StreamSubscription<RemoteMessage>? _messages;
  List<Map<String, dynamic>> _groups = [];
  int? _userId;
  int? _groupId;
  DebtSummary? _debt;
  SmartSettlementResult? _smart;
  List<SettlementRecord> _settlements = [];
  bool _loading = true;
  bool _busy = false;
  String? _error;
  int _tab = 0;
  int _version = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _messages = FirebaseMessaging.onMessage.listen((message) {
      if (message.data['groupId']?.toString() == _groupId?.toString()) _load();
    });
    _initialize();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messages?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant GroupSettlementScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) _initialize();
  }

  Future<void> _initialize() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final userId = await AuthRepository().getCurrentUserId();
      final response = await dioClient.get('/groups');
      final groups = (response.data['data'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      if (!mounted) return;
      _userId = userId;
      _groups = groups;
      final preferred = _groupId ?? widget.groupId;
      _groupId = groups.any((g) => g['id'] == preferred)
          ? preferred
          : (groups.isEmpty ? null : (groups.first['id'] as num).toInt());
      if (_groupId != null) {
        await _load();
      } else {
        setState(() => _loading = false);
      }
    } catch (error) {
      if (mounted)
        setState(() {
          _error = '$error';
          _loading = false;
        });
    }
  }

  Future<void> _load() async {
    final group = _groupId;
    final user = _userId;
    if (group == null || user == null || !mounted) return;
    final version = ++_version;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait<Object>([
        _api.getDebtSummary(group, user),
        _api.getSmartSettlement(group, user),
        _api.getSettlements(group, user),
      ]);
      if (!mounted || version != _version) return;
      setState(() {
        _debt = results[0] as DebtSummary;
        _smart = results[1] as SmartSettlementResult;
        _settlements = results[2] as List<SettlementRecord>;
        _loading = false;
      });
    } catch (error) {
      if (mounted && version == _version)
        setState(() {
          _error = '$error';
          _loading = false;
        });
    }
  }

  Future<void> _openPayment(SettlementRecord record) async {
    await Navigator.push<void>(
        context,
        MaterialPageRoute(
            builder: (_) => PaymentDialog(
                groupId: record.groupId,
                currentUserId: _userId!,
                settlement: record,
                onUpdated: () {})));
    await _load();
  }

  Future<void> _create(DebtEdge edge) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final record = await _api.createSettlement(
          groupId: _groupId!, currentUserId: _userId!, suggestion: edge);
      if (mounted && record.debtorId == _userId) {
        await _openPayment(record);
      } else {
        await _load();
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text(
                  'Đã tạo yêu cầu. Người trả cần mở tài khoản của họ và báo đã thanh toán.')));
      }
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
            title: Text(_tab == 0 ? 'Khoản nợ' : 'Kết quả xén nợ'),
            actions: [
              const NotificationBell(),
              IconButton(
                  onPressed: _loading ? null : _initialize,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Tải lại')
            ]),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: TextButton(
                        onPressed: _initialize,
                        child: Text('Không tải được công nợ. Thử lại')))
                : _groups.isEmpty
                    ? const Center(child: Text('Bạn chưa tham gia nhóm nào.'))
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView(
                            padding: const EdgeInsets.all(20),
                            children: [
                              if (widget.groupId == null) ...[
                                DropdownButtonFormField<int>(
                                    value: _groupId,
                                    items: _groups
                                        .map((g) => DropdownMenuItem(
                                            value: (g['id'] as num).toInt(),
                                            child: Text(g['name'])))
                                        .toList(),
                                    onChanged: (v) {
                                      _groupId = v;
                                      _load();
                                    }),
                                const SizedBox(height: 20)
                              ],
                              if (_tab == 0) ...[
                                Row(children: [
                                  Expanded(
                                      child: _totalBox('Tổng bạn cần trả',
                                          _debt!.totalToPay, pdfRed)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                      child: _totalBox('Tổng bạn được nhận',
                                          _debt!.totalToReceive, pdfGreen))
                                ]),
                                const SizedBox(height: 28),
                                const Text('BẠN CẦN TRẢ',
                                    style: TextStyle(
                                        color: pdfMuted,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(height: 12),
                                if (_debt!.youOwe.isEmpty)
                                  const Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Text(
                                          'Bạn không còn khoản phải trả.',
                                          style: TextStyle(color: pdfMuted))),
                                for (final e in _debt!.youOwe)
                                  _debtCard(e.creditorName,
                                      'Bạn trả ${e.creditorName}', -e.amount),
                                const SizedBox(height: 20),
                                const Text('BẠN SẼ NHẬN',
                                    style: TextStyle(
                                        color: pdfMuted,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(height: 12),
                                if (_debt!.owedToYou.isEmpty)
                                  const Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Text(
                                          'Bạn không còn khoản cần nhận.',
                                          style: TextStyle(color: pdfMuted))),
                                for (final e in _debt!.owedToYou)
                                  _debtCard(e.debtorName,
                                      '${e.debtorName} trả bạn', e.amount),
                              ] else ...[
                                const Center(
                                    child: CircleAvatar(
                                        radius: 32,
                                        backgroundColor: Color(0xFFE7FBF1),
                                        child: Text('✂️',
                                            style: TextStyle(fontSize: 28)))),
                                const SizedBox(height: 18),
                                const Text('Đã tối ưu giao dịch!',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800)),
                                const SizedBox(height: 8),
                                const Text(
                                    'Gộp các khoản nợ chéo để giảm số lần thanh toán trong nhóm.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: pdfMuted, fontSize: 13)),
                                const SizedBox(height: 22),
                                Row(children: [
                                  Expanded(
                                      child: _countBox(
                                          'Trước tối ưu',
                                          _smart!.beforeTransactionCount,
                                          false)),
                                  const Padding(
                                      padding: EdgeInsets.all(12),
                                      child: Icon(Icons.arrow_forward,
                                          color: pdfMuted, size: 18)),
                                  Expanded(
                                      child: _countBox('Sau tối ưu',
                                          _smart!.afterTransactionCount, true))
                                ]),
                                const SizedBox(height: 24),
                                if (_settlements.isNotEmpty) ...[
                                  const Text('GIAO DỊCH THANH TOÁN',
                                      style: TextStyle(
                                          color: pdfMuted,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600)),
                                  for (final r in _settlements) _recordCard(r),
                                  const SizedBox(height: 16)
                                ],
                                const Text('ĐỀ XUẤT THANH TOÁN',
                                    style: TextStyle(
                                        color: pdfMuted,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(height: 12),
                                if (_smart!.suggestions.isEmpty)
                                  const Text(
                                      'Không còn công nợ cần thanh toán.',
                                      style: TextStyle(color: pdfMuted)),
                                for (final e in _smart!.suggestions.where((e) =>
                                    !_settlements.any((s) =>
                                        (s.status == 'PENDING' ||
                                            s.status == 'PAID') &&
                                        s.debtorId == e.debtorId &&
                                        s.creditorId == e.creditorId)))
                                  Card(
                                      child: Padding(
                                          padding: const EdgeInsets.all(14),
                                          child: Column(children: [
                                            Row(children: [
                                              PersonBadge(e.debtorName),
                                              const Padding(
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal: 8),
                                                  child: Icon(
                                                      Icons.arrow_forward,
                                                      size: 16,
                                                      color: pdfPurple)),
                                              PersonBadge(e.creditorName,
                                                  color: pdfGreen),
                                              const Spacer(),
                                              Text(money(e.amount),
                                                  style: const TextStyle(
                                                      color: pdfPurple,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontSize: 14))
                                            ]),
                                            const SizedBox(height: 8),
                                            Text(
                                                '${e.debtorName} trả ${e.creditorName}',
                                                style: const TextStyle(
                                                    color: pdfMuted,
                                                    fontSize: 12)),
                                            if (_userId == e.debtorId ||
                                                _userId == e.creditorId)
                                              TextButton(
                                                  onPressed: _busy
                                                      ? null
                                                      : () => _create(e),
                                                  child: Text(_userId ==
                                                          e.debtorId
                                                      ? 'Thanh toán'
                                                      : 'Yêu cầu thanh toán'))
                                          ]))),
                              ],
                            ])),
        bottomNavigationBar: _loading || _groupId == null
            ? null
            : SafeArea(
                child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: FilledButton(
                        onPressed: () => setState(() => _tab = 1 - _tab),
                        child: Text(_tab == 0 ? '✂  Xén nợ' : 'Về khoản nợ')))),
      );
  Widget _totalBox(String title, double amount, Color color) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: color.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(fontSize: 11, color: color)),
        const SizedBox(height: 8),
        Text(money(amount),
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w800, color: color))
      ]));
  Widget _countBox(String title, int count, bool after) => Card(
      color: after ? const Color(0xFFE8FCF3) : Colors.white,
      child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(children: [
            Text(title,
                style: TextStyle(
                    fontSize: 11, color: after ? pdfGreen : pdfMuted)),
            const SizedBox(height: 6),
            Text('$count giao dịch',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: after ? pdfGreen : const Color(0xFF202127)))
          ])));
  Widget _debtCard(String name, String subtitle, double amount) => Card(
      child: ListTile(
          leading: PersonBadge(name, color: amount < 0 ? pdfRed : pdfGreen),
          title: Text(name,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
          trailing: Text('${amount > 0 ? '+' : ''}${money(amount)}',
              style: TextStyle(
                  color: amount < 0 ? pdfRed : pdfGreen,
                  fontSize: 12,
                  fontWeight: FontWeight.w700))));
  Widget _recordCard(SettlementRecord record) {
    final canPay = record.status == 'PENDING' && record.debtorId == _userId;
    final canConfirm = record.status == 'PAID' && record.creditorId == _userId;
    final label = switch (record.status) {
      'PENDING' => 'Chờ người trả chuyển tiền',
      'PAID' => 'Chờ người nhận xác nhận',
      'CONFIRMED' => 'Hoàn tất thanh toán',
      _ => record.status,
    };
    final color = record.status == 'CONFIRMED'
        ? AppColors.success
        : record.status == 'PAID'
            ? Colors.orange
            : AppColors.p500;
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(
              color: record.status == 'PAID'
                  ? Colors.orange
                  : const Color(0xFFEDEDF3))),
      child: Padding(
          padding: const EdgeInsets.all(18),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              CircleAvatar(
                  backgroundColor: const Color(0xFFE5DFFF),
                  child: Text(
                      record.debtorName.isEmpty ? '?' : record.debtorName[0])),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(
                      '${record.debtorName}${record.debtorId == _userId ? ' (Bạn)' : ''} → ${record.creditorName}${record.creditorId == _userId ? ' (Bạn)' : ''}',
                      style: const TextStyle(fontWeight: FontWeight.w600))),
            ]),
            Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(_currency.format(record.amount),
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.p500))),
            const Divider(),
            Wrap(
                spacing: 16,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(label,
                      style:
                          TextStyle(color: color, fontWeight: FontWeight.w600)),
                  if (canPay || canConfirm)
                    FilledButton.icon(
                        onPressed: _busy ? null : () => _openPayment(record),
                        icon: Icon(canPay
                            ? Icons.payments_outlined
                            : Icons.verified_outlined),
                        label: Text(
                            canPay ? 'Thanh toán' : 'Xác nhận đã nhận tiền')),
                ]),
            if (record.status == 'PENDING' && record.creditorId == _userId)
              Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                      'Bạn là người nhận. Chờ ${record.debtorName} chọn “Đã thanh toán”, sau đó bạn có thể xác nhận nhận tiền.',
                      style: const TextStyle(color: Colors.black54))),
            if (record.status == 'PAID' && record.debtorId == _userId)
              const Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Text(
                      'Bạn đã báo thanh toán. Công nợ được cập nhật khi người nhận xác nhận.',
                      style: TextStyle(color: Colors.black54))),
          ])),
    );
  }
}
