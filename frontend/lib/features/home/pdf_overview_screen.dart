import 'package:flutter/material.dart';
import '../../core/network/dio_client.dart';
import '../../core/theme/pdf_components.dart';
import '../auth/data/auth_repository.dart';
import '../settlement/data/settlement_api_service.dart';
import '../settlement/models/settlement_models.dart';
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

  static List<Map<String, dynamic>>? _cachedGroups;
  static final Map<int, List<Map<String, dynamic>>> _cachedEventsByGroup = {};
  static final Map<String, FinancialStats> _cachedStats = {};

  List<Map<String, dynamic>> _groups = [], _events = [];
  FinancialStats? _stats;
  int? _group, _user;
  int _period = 1, _filter = 0;
  bool _loading = true;
  String? _error;

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
  }

  Future<void> _initialize() async {
    try {
      _user = await AuthRepository().getCurrentUserId();
      final r = await dioClient.get('/groups');
      final fetchedGroups = (r.data['data'] as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      _cachedGroups = fetchedGroups;
      _groups = fetchedGroups;
      _group ??= _groups.isEmpty ? null : (_groups.first['id'] as num).toInt();
      await _load();
    } catch (_) {
      if (mounted && _groups.isEmpty) {
        setState(() {
          _error = 'Không tải được dữ liệu.';
          _loading = false;
        });
      }
    }
  }

  Future<void> _load() async {
    if (_group == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    final hasCache = widget.history
        ? _cachedEventsByGroup.containsKey(_group)
        : _cachedStats.containsKey('$_group-$_period');

    if (!hasCache) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      if (!widget.history) {
        final stats = await SettlementApiService()
            .getStats(_group!, _user!, ['WEEK', 'MONTH', 'ALL'][_period]);
        _cachedStats['$_group-$_period'] = stats;
        _stats = stats;
      } else {
        final results = await Future.wait([
          dioClient.get('/v1/expenses/group/$_group'),
          dioClient.get('/groups/$_group/settlements',
              queryParameters: {'userId': _user})
        ]);
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
        _cachedEventsByGroup[_group!] = newEvents;
        _events = newEvents;
      }
      if (mounted) setState(() => _loading = false);
    } catch (_) {
      if (mounted && !hasCache) {
        setState(() {
          _error = 'Không tải được dữ liệu. Hãy thử lại.';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
        appBar: AppBar(
            title: Text(widget.history ? 'Lịch sử' : 'Thống kê'),
            actions: const [NotificationBell()]),
        body: RefreshIndicator(
            onRefresh: _initialize,
            child: ListView(padding: const EdgeInsets.all(20), children: [
              if (_groups.isNotEmpty)
                DropdownButtonFormField<int>(
                    value: _group,
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
                for (final e in _events
                    .where((e) => _filter == 0 || e['kind'] == _filter))
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
                          Text(
                              'TỔNG CHI TIÊU ${['TUẦN', 'THÁNG', ''][_period]}',
                              style: const TextStyle(
                                  color: pdfMuted, fontSize: 12)),
                          const SizedBox(height: 8),
                          Text(money(_stats!.totalExpense),
                              style: const TextStyle(
                                  fontSize: 30,
                                  color: pdfPurple,
                                  fontWeight: FontWeight.w800))
                        ]))),
                const SizedBox(height: 20),
                const Text('Chi tiêu theo danh mục',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
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
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
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
