// Trách nhiệm file: Xây dựng màn hình PDF overview screen và điều phối tương tác người dùng với trạng thái nghiệp vụ.

import 'package:flutter/material.dart';
import '../../core/network/dio_client.dart';
import '../../core/state/app_sync.dart';
import '../../core/theme/pdf_components.dart';
import '../../data/repositories/auth_repository.dart';
import '../settlements/data/settlement_api_service.dart';
import '../settlements/models/settlement_models.dart';
import '../notifications/notification_screen.dart';

class OverviewScreen extends StatefulWidget {
  final bool history;
  const OverviewScreen({super.key, this.history = false});
  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<Map<String, dynamic>>? _cachedGroups;
  final Map<int, List<Map<String, dynamic>>> _cachedEventsByGroup = {};
  final Map<String, FinancialStats> _cachedStats = {};

  List<Map<String, dynamic>> _groups = [], _events = [];
  FinancialStats? _stats;
  int? _group, _user;
  int _period = 1, _filter = 0;
  bool _loading = true;
  String? _error;
  int _generation = 0;
  bool _initializing = false;
  bool _refreshPending = false;

  @override
  void initState() {
    super.initState();
    if (_cachedGroups != null && _cachedGroups!.isNotEmpty) {
      _groups = List.from(_cachedGroups!);
      _group = (_groups.first['id'] as num).toInt();
      if (widget.history && _cachedEventsByGroup.containsKey(_group)) {
        _events = List.from(_cachedEventsByGroup[_group]!);
        _loading = false;
      }
    }
    _initialize();
    appDataSyncSignal.addListener(_onRealtimeSync);
  }

  @override
  void dispose() {
    appDataSyncSignal.removeListener(_onRealtimeSync);
    super.dispose();
  }

  void _onRealtimeSync() {
    if (mounted) _initialize();
  }

  Future<void> _initialize() async {
    if (_initializing) {
      _refreshPending = true;
      return;
    }
    _initializing = true;
    try {
      do {
        _refreshPending = false;
        final result = await Future.wait(
            [AuthRepository().getCurrentUserId(), dioClient.get('/groups')]);
        if (!mounted) return;
        _user = result[0] as int;
        final r = result[1] as dynamic;
        final groups = (r.data['data'] as List)
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        setState(() {
          _cachedGroups = groups;
          _groups = groups;
          if (!_groups.any((g) => g['id'] == _group))
            _group =
                _groups.isEmpty ? null : (_groups.first['id'] as num).toInt();
        });
        await _load();
      } while (_refreshPending && mounted);
    } catch (_) {
      if (mounted)
        setState(() {
          _error = 'Không tải được dữ liệu. Hãy thử lại.';
          _loading = false;
        });
    } finally {
      _initializing = false;
    }
  }

  Future<void> _load() async {
    final group = _group;
    final period = _period;
    final generation = ++_generation;
    if (!mounted) return;
    if (group == null) {
      setState(() {
        _loading = false;
        _error = null;
        _events = [];
        _stats = null;
      });
      return;
    }
    final cacheKey = '$group-$period';
    final hasCache = widget.history
        ? _cachedEventsByGroup.containsKey(group)
        : _cachedStats.containsKey(cacheKey);
    setState(() {
      _error = null;
      _loading = !hasCache;
      if (widget.history) {
        _events = _cachedEventsByGroup[group] ?? [];
      } else {
        _stats = _cachedStats[cacheKey];
      }
    });
    try {
      if (!widget.history) {
        final stats = await SettlementApiService()
            .getStats(group, ['WEEK', 'MONTH', 'ALL'][period]);
        if (!mounted || generation != _generation) return;
        _cachedStats[cacheKey] = stats;
        _stats = stats;
      } else {
        final results = await Future.wait([
          dioClient.get('/v1/expenses/group/$group'),
          dioClient.get('/groups/$group/settlements')
        ]);
        if (!mounted || generation != _generation) return;
        final newEvents = <Map<String, dynamic>>[];
        for (final e in results[0].data['data'] as List) {
          final parts = (e['participants'] as List? ?? [])
              .where((p) => p['userId'] == _user);
          if (parts.isEmpty) continue;
          newEvents.add({
            'title': e['title'],
            'amount': -(parts.first['amount'] as num).toDouble(),
            'date': e['expenseDate'] ?? e['createdAt'],
            'kind': 1
          });
        }
        for (final e in results[1].data['data'] as List) {
          if (e['status'] != 'CONFIRMED' ||
              (e['debtorId'] != _user && e['creditorId'] != _user)) continue;
          final received = e['creditorId'] == _user;
          newEvents.add({
            'title': received
                ? 'Nhận từ ${e['debtorName']}'
                : 'Thanh toán cho ${e['creditorName']}',
            'amount': (e['amount'] as num) * (received ? 1 : -1),
            'date': e['confirmedAt'] ?? e['paidAt'] ?? e['requestedAt'],
            'kind': received ? 3 : 2
          });
        }
        newEvents.sort((a, b) => (b['date'] ?? '')
            .toString()
            .compareTo((a['date'] ?? '').toString()));
        _cachedEventsByGroup[group] = newEvents;
        _events = newEvents;
      }
      if (mounted && generation == _generation)
        setState(() => _loading = false);
    } catch (_) {
      if (mounted && generation == _generation)
        setState(() {
          _error = 'Không tải được dữ liệu. Hãy thử lại.';
          _loading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.history
              ? tr(context, 'Lịch sử', 'History')
              : tr(context, 'Thống kê', 'Statistics')),
          actions: const [NotificationBell()]),
      body: RefreshIndicator(
          onRefresh: _initialize,
          child: ListView(padding: const EdgeInsets.all(20), children: [
            if (_groups.isNotEmpty)
              DropdownButtonFormField<int>(
                  initialValue: _group,
                  items: _groups
                      .map((g) => DropdownMenuItem(
                          value: (g['id'] as num).toInt(),
                          child: Text(g['name'])))
                      .toList(),
                  onChanged: (v) {
                    _group = v;
                    _load();
                  }),
            const SizedBox(height: 16),
            PdfTabs(
                labels: widget.history
                    ? ['Tất cả', 'Chi tiêu', 'Thanh toán', 'Nhận tiền']
                    : ['Tuần', 'Tháng', 'Tất cả'],
                selected: widget.history ? _filter : _period,
                onChanged: (v) {
                  setState(() {
                    if (widget.history) {
                      _filter = v;
                    } else {
                      _period = v;
                    }
                  });
                  if (!widget.history) _load();
                }),
            const SizedBox(height: 20),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_error != null)
              TextButton(onPressed: _initialize, child: Text(_error!))
            else if (_groups.isEmpty)
              const Text('Chưa có nhóm để hiển thị dữ liệu.')
            else if (widget.history) ...[
              if (_events
                  .where((e) => _filter == 0 || e['kind'] == _filter)
                  .isEmpty)
                const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Chưa có giao dịch trong mục này.',
                        textAlign: TextAlign.center)),
              for (final e
                  in _events.where((e) => _filter == 0 || e['kind'] == _filter))
                Card(
                    child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        leading: PersonBadge(e['kind'] == 3 ? '↙' : '▤',
                            color: e['kind'] == 3 ? pdfGreen : pdfPurple),
                        title: Text(e['title'] ?? '',
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w700)),
                        subtitle: Text(
                            (e['date'] ?? '').toString().replaceAll('T', ' '),
                            style: const TextStyle(fontSize: 11)),
                        trailing: Text(
                            '${e['amount'] > 0 ? '+' : ''}${money(e['amount'])}',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: e['amount'] > 0
                                    ? pdfGreen
                                    : const Color(0xFF202127))))),
            ] else if (_stats != null) ...[
              Card(
                  child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(children: [
                        Text('TỔNG CHI TIÊU ${['TUẦN', 'THÁNG', ''][_period]}',
                            style:
                                const TextStyle(color: pdfMuted, fontSize: 12)),
                        const SizedBox(height: 8),
                        Text(money(_stats!.totalExpense),
                            style: const TextStyle(
                                fontSize: 30,
                                color: pdfPurple,
                                fontWeight: FontWeight.w800))
                      ]))),
              const SizedBox(height: 20),
              const Text('Chi tiêu theo danh mục',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 14),
              Card(
                  child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(children: [
                        if (_stats!.byCategory.isEmpty)
                          const Text('Chưa có khoản chi.'),
                        for (final item in _stats!.byCategory)
                          Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Column(children: [
                                Row(children: [
                                  Expanded(child: Text(item.label)),
                                  Text(money(item.amount),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700))
                                ]),
                                const SizedBox(height: 7),
                                LinearProgressIndicator(
                                    value: _stats!.totalExpense <= 0
                                        ? 0
                                        : (item.amount / _stats!.totalExpense)
                                            .clamp(0, 1),
                                    minHeight: 7,
                                    borderRadius: BorderRadius.circular(8),
                                    color: pdfPurple,
                                    backgroundColor: const Color(0xFFEFEFF5))
                              ])),
                      ]))),
              const SizedBox(height: 20),
              const Text('Top người chi tiêu',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 14),
              Card(
                  child: Column(children: [
                for (final entry in (_stats!.byMember.toList()
                      ..sort((a, b) => b.amount.compareTo(a.amount)))
                    .asMap()
                    .entries)
                  ListTile(
                      leading: PersonBadge(entry.value.label),
                      title: Text('#${entry.key + 1}  ${entry.value.label}',
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600)),
                      trailing: Text(money(entry.value.amount),
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold)))
              ])),
            ],
          ])),
    );
  }
}
