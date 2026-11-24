// Trách nhiệm file: Xây dựng màn hình lịch sử giao dịch và tổng quan (history screen) theo chuẩn Apple HIG.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../core/network/dio_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/pdf_components.dart';
import '../../data/repositories/auth_repository.dart';
import '../settlements/data/settlement_api_service.dart';
import '../settlements/models/settlement_models.dart';
import '../notifications/notification_screen.dart';

class HistoryScreen extends StatefulWidget {
  final bool history;
  const HistoryScreen({super.key, this.history = false});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
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
            .getStats(_group!, ['WEEK', 'MONTH', 'ALL'][_period]);
        _cachedStats['$_group-$_period'] = stats;
        _stats = stats;
      } else {
        final results = await Future.wait([
          dioClient.get('/v1/expenses/group/$_group'),
          dioClient.get('/groups/$_group/settlements')
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

  String _formatDate(dynamic value) {
    if (value == null) return '';
    final str = value.toString();
    final date = DateTime.tryParse(str);
    if (date != null) {
      final local = date.toLocal();
      return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    }
    return str.replaceAll('T', ' ');
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: AppColors.n100,
      appBar: AppBar(
        title: Text(
          widget.history ? 'Lịch sử' : 'Thống kê',
          style: AppTypography.title.copyWith(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: AppColors.n0,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: const [NotificationBell()],
      ),
      body: RefreshIndicator(
        onRefresh: _initialize,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          children: [
            // iOS Group Selector Card
            if (_groups.isNotEmpty) ...[
              Container(
                decoration: BoxDecoration(
                  color: AppColors.n0,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: AppDimensions.shadowSm,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _group,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.n500),
                    items: _groups
                        .map((g) => DropdownMenuItem(
                              value: (g['id'] as num).toInt(),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: AppColors.p50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.groups_rounded, size: 16, color: AppColors.p500),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      g['name'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.n800,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _group = v);
                      _load();
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Apple HIG Sliding Segmented Control
            SizedBox(
              width: double.infinity,
              child: CupertinoSlidingSegmentedControl<int>(
                groupValue: widget.history ? _filter : _period,
                backgroundColor: AppColors.n200,
                thumbColor: AppColors.n0,
                padding: const EdgeInsets.all(3),
                children: widget.history
                    ? {
                        0: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          child: Text('Tất cả', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                        1: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          child: Text('Chi tiêu', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                        2: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          child: Text('Thanh toán', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                        3: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          child: Text('Nhận tiền', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                      }
                    : {
                        0: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Text('Tuần', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                        1: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Text('Tháng', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                        2: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Text('Tất cả', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                      },
                onValueChanged: (v) {
                  if (v == null) return;
                  setState(() {
                    if (widget.history) {
                      _filter = v;
                    } else {
                      _period = v;
                    }
                  });
                  if (!widget.history) _load();
                },
              ),
            ),
            const SizedBox(height: 14),

            // Content Sections
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_error != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(_error!, style: const TextStyle(color: AppColors.n600)),
                      const SizedBox(height: 8),
                      TextButton(onPressed: _initialize, child: const Text('Thử lại')),
                    ],
                  ),
                ),
              )
            else if (_groups.isEmpty)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.n0,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.group_off_rounded, size: 48, color: AppColors.n400),
                    SizedBox(height: 10),
                    Text(
                      'Chưa có nhóm để hiển thị dữ liệu',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.n700),
                    ),
                  ],
                ),
              )
            else if (widget.history) ...[
              // --- HISTORY LIST ---
              if (_events.where((e) => _filter == 0 || e['kind'] == _filter).isEmpty)
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 24),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppColors.n0,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 44, color: AppColors.n400),
                      SizedBox(height: 10),
                      Text(
                        'Chưa có giao dịch trong mục này',
                        style: TextStyle(fontSize: 14, color: AppColors.n600),
                      ),
                    ],
                  ),
                )
              else
                for (final e in _events.where((e) => _filter == 0 || e['kind'] == _filter))
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.n0,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: AppDimensions.shadowSm,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: e['kind'] == 3
                                ? AppColors.success.withValues(alpha: 0.1)
                                : (e['kind'] == 2
                                    ? AppColors.error.withValues(alpha: 0.1)
                                    : AppColors.p50),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            e['kind'] == 3
                                ? Icons.arrow_downward_rounded
                                : (e['kind'] == 2
                                    ? Icons.arrow_upward_rounded
                                    : Icons.receipt_rounded),
                            color: e['kind'] == 3
                                ? AppColors.success
                                : (e['kind'] == 2 ? AppColors.error : AppColors.p500),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                e['title'] ?? '',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.n800,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _formatDate(e['date']),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.n500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${e['amount'] > 0 ? '+' : ''}${money(e['amount'])}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: e['amount'] > 0 ? AppColors.success : AppColors.n800,
                          ),
                        ),
                      ],
                    ),
                  ),
            ] else if (_stats != null) ...[
              // --- STATS MODE ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.n0,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppDimensions.shadowSm,
                ),
                child: Column(
                  children: [
                    Text(
                      'TỔNG CHI TIÊU ${['TUẦN', 'THÁNG', ''][_period]}',
                      style: const TextStyle(
                        color: AppColors.n500,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      money(_stats!.totalExpense),
                      style: const TextStyle(
                        fontSize: 28,
                        color: AppColors.p500,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  'CHI TIÊU THEO DANH MỤC',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.n500,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.n0,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: AppDimensions.shadowSm,
                ),
                child: Column(
                  children: [
                    if (_stats!.byCategory.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('Chưa có khoản chi nào.', style: TextStyle(color: AppColors.n500)),
                      ),
                    for (int i = 0; i < _stats!.byCategory.length; i++) ...[
                      if (i > 0) const SizedBox(height: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _stats!.byCategory[i].label,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.n800),
                              ),
                              Text(
                                money(_stats!.byCategory[i].amount),
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.n800),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: _stats!.totalExpense <= 0
                                  ? 0
                                  : (_stats!.byCategory[i].amount / _stats!.totalExpense).clamp(0.0, 1.0),
                              minHeight: 6,
                              backgroundColor: AppColors.n200,
                              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.p500),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  'TOP THÀNH VIÊN CHI TIÊU',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.n500,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.n0,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: AppDimensions.shadowSm,
                ),
                child: Column(
                  children: [
                    for (final entry in (_stats!.byMember.toList()
                          ..sort((a, b) => b.amount.compareTo(a.amount)))
                        .asMap()
                        .entries) ...[
                      if (entry.key > 0)
                        const Divider(height: 1, indent: 56, endIndent: 16, color: AppColors.n100),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: entry.key == 0
                                    ? Colors.amber.shade100
                                    : (entry.key == 1
                                        ? Colors.blueGrey.shade100
                                        : (entry.key == 2
                                            ? Colors.brown.shade100
                                            : AppColors.n100)),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${entry.key + 1}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: entry.key == 0
                                      ? Colors.amber.shade900
                                      : (entry.key == 1
                                          ? Colors.blueGrey.shade800
                                          : (entry.key == 2
                                              ? Colors.brown.shade800
                                              : AppColors.n600)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                entry.value.label,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.n800,
                                ),
                              ),
                            ),
                            Text(
                              money(entry.value.amount),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.n800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
