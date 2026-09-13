import 'dart:async';
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
  FinancialStats? _stats;
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
        _api.getStats(group, user, 'ALL'),
        _api.getSmartSettlement(group, user),
        _api.getSettlements(group, user),
      ]);
      if (!mounted || version != _version) return;
      setState(() {
        _debt = results[0] as DebtSummary;
        _stats = results[1] as FinancialStats;
        _smart = results[2] as SmartSettlementResult;
        _settlements = results[3] as List<SettlementRecord>;
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
    await showDialog<void>(
        context: context,
        builder: (_) => PaymentDialog(
            groupId: record.groupId,
            currentUserId: _userId!,
            settlement: record,
            onUpdated: () {}));
    await _load();
  }

  Future<void> _create(DebtEdge edge) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final record = await _api.createSettlement(
          groupId: _groupId!, currentUserId: _userId!, suggestion: edge);
      if (mounted) await _openPayment(record);
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
        backgroundColor: AppColors.n50,
        appBar: AppBar(
            title: const Text('Quyết toán Nợ nhóm'),
            centerTitle: true,
            actions: [
              IconButton(
                  tooltip: 'Tải lại',
                  onPressed: _loading ? null : _initialize,
                  icon: const Icon(Icons.refresh))
            ]),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text('Không tải được quyết toán: $_error'),
                    TextButton(
                        onPressed: _initialize, child: const Text('Thử lại'))
                  ]))
                : _groups.isEmpty
                    ? const Center(child: Text('Bạn chưa tham gia nhóm nào.'))
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(20),
                            children: [
                              DropdownButton<int>(
                                  value: _groupId,
                                  isExpanded: true,
                                  items: _groups
                                      .map((g) => DropdownMenuItem<int>(
                                          value: (g['id'] as num).toInt(),
                                          child: Text(g['name'] as String)))
                                      .toList(),
                                  onChanged: _busy
                                      ? null
                                      : (value) {
                                          _groupId = value;
                                          _load();
                                        }),
                              Card(
                                  color: AppColors.p500,
                                  child: Padding(
                                      padding: const EdgeInsets.all(24),
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text('TỔNG CHI TIÊU NHÓM',
                                                style: TextStyle(
                                                    color: Colors.white)),
                                            Text(
                                                _currency.format(
                                                    _stats?.totalExpense ?? 0),
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 32,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            const SizedBox(height: 12),
                                            Text(
                                                'Bạn cần trả: ${_currency.format(_debt?.totalToPay ?? 0)}\nBạn cần nhận: ${_currency.format(_debt?.totalToReceive ?? 0)}',
                                                style: const TextStyle(
                                                    color: Colors.white)),
                                          ]))),
                              const SizedBox(height: 16),
                              SegmentedButton<int>(
                                  segments: const [
                                    ButtonSegment(
                                        value: 0, label: Text('Dư nợ ròng')),
                                    ButtonSegment(
                                        value: 1,
                                        label: Text('Giao dịch tối ưu'))
                                  ],
                                  selected: {
                                    _tab
                                  },
                                  onSelectionChanged: (value) =>
                                      setState(() => _tab = value.first)),
                              const SizedBox(height: 16),
                              if (_tab == 0) ...[
                                for (final balance in _debt!.netBalances)
                                  Card(
                                      child: ListTile(
                                          title: Text(
                                              '${balance.fullName}${balance.userId == _userId ? ' (Tôi)' : ''}'),
                                          subtitle: Text(balance.netBalance > 0
                                              ? 'Cần nhận lại từ nhóm'
                                              : balance.netBalance < 0
                                                  ? 'Còn thiếu tiền nhóm'
                                                  : 'Đã cân bằng'),
                                          trailing: Text(
                                              _currency
                                                  .format(balance.netBalance),
                                              style: TextStyle(
                                                  color: balance.netBalance < 0
                                                      ? AppColors.error
                                                      : AppColors.success)))),
                              ] else ...[
                                const Text('GIAO DỊCH THANH TOÁN'),
                                for (final record in _settlements)
                                  _recordCard(record),
                                const SizedBox(height: 16),
                                const Text('ĐỀ XUẤT THANH TOÁN'),
                                if (_smart!.suggestions.isEmpty)
                                  const Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Text(
                                          'Không còn công nợ cần thanh toán.')),
                                for (final edge in _smart!.suggestions)
                                  Card(
                                      child: ListTile(
                                          title: Text(
                                              '${edge.debtorName} → ${edge.creditorName}'),
                                          subtitle: Text(
                                              _currency.format(edge.amount)),
                                          trailing: (_userId == edge.debtorId ||
                                                  _userId == edge.creditorId)
                                              ? TextButton(
                                                  onPressed: _busy ||
                                                          _settlements.any((s) =>
                                                              (s.status ==
                                                                      'PENDING' ||
                                                                  s.status ==
                                                                      'PAID') &&
                                                              s.debtorId ==
                                                                  edge.debtorId &&
                                                              s.creditorId == edge.creditorId)
                                                      ? null
                                                      : () => _create(edge),
                                                  child: const Text('Tạo thanh toán'))
                                              : null)),
                              ],
                            ])),
      );
  Widget _recordCard(SettlementRecord record) {
    final canPay = record.status == 'PENDING' && record.debtorId == _userId;
    final canConfirm = record.status == 'PAID' && record.creditorId == _userId;
    final label = switch (record.status) {
      'PENDING' => 'Chờ người trả chuyển tiền',
      'PAID' => 'Chờ người nhận xác nhận',
      'CONFIRMED' => 'Hoàn tất thanh toán',
      _ => record.status,
    };
    return Card(
        child: ListTile(
            title: Text('${record.debtorName} → ${record.creditorName}'),
            subtitle: Text('${_currency.format(record.amount)} • $label'),
            trailing: canPay || canConfirm
                ? TextButton(
                    onPressed: () => _openPayment(record),
                    child: Text(canPay ? 'Tôi đã chuyển tiền' : 'Đã nhận tiền'))
                : null));
  }
}
