// Trách nhiệm file: Màn hình Lịch sử giao dịch (nhóm theo ngày, tìm kiếm, lọc) và Thống kê chi tiêu, hỗ trợ Light & Dark mode.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/network/dio_client.dart';
import '../../core/state/app_sync.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/pdf_components.dart';
import '../../core/widgets/fintech_components.dart';
import '../../core/widgets/motion_kit.dart';
import '../../core/widgets/premium_shell.dart';
import '../../data/repositories/auth_repository.dart';
import '../notifications/notification_screen.dart';
import '../settlements/data/settlement_api_service.dart';
import '../settlements/models/settlement_models.dart';

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

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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
    _searchController.dispose();
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
        final result = await Future.wait([
          AuthRepository().getCurrentUserId(),
          dioClient.get('/groups'),
        ]);
        if (!mounted) return;
        _user = result[0] as int;
        final r = result[1] as dynamic;
        final groups = (r.data['data'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        setState(() {
          _cachedGroups = groups;
          _groups = groups;
          if (!_groups.any((g) => g['id'] == _group)) {
            _group = _groups.isEmpty
                ? null
                : (_groups.first['id'] as num).toInt();
          }
        });
        await _load();
      } while (_refreshPending && mounted);
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = tr(
            context,
            'Không tải được dữ liệu. Kiểm tra kết nối và thử lại.',
            'Could not load data. Check your connection and retry.',
          );
          _loading = false;
        });
      }
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
        final stats = await SettlementApiService().getStats(
          group,
          ['WEEK', 'MONTH', 'ALL'][period],
        );
        if (!mounted || generation != _generation) return;
        _cachedStats[cacheKey] = stats;
        _stats = stats;
      } else {
        final results = await Future.wait([
          dioClient.get('/v1/expenses/group/$group'),
          dioClient.get('/groups/$group/settlements'),
        ]);
        if (!mounted || generation != _generation) return;
        final newEvents = <Map<String, dynamic>>[];
        for (final e in results[0].data['data'] as List) {
          final parts = (e['participants'] as List? ?? []).where(
            (p) => p['userId'] == _user,
          );
          if (parts.isEmpty) continue;
          newEvents.add({
            'title': e['title']?.toString() ?? '',
            'actor': e['payerName']?.toString() ?? '',
            'amount': -(parts.first['amount'] as num).toDouble(),
            'date': (e['expenseDate'] ?? e['createdAt'] ?? '').toString(),
            'kind': 1,
          });
        }
        for (final e in results[1].data['data'] as List) {
          if (e['status'] != 'CONFIRMED' ||
              (e['debtorId'] != _user && e['creditorId'] != _user)) {
            continue;
          }
          final received = e['creditorId'] == _user;
          newEvents.add({
            'title': received ? '${e['debtorName']}' : '${e['creditorName']}',
            'actor': received ? 'received' : 'paid',
            'amount': ((e['amount'] as num).toDouble()) * (received ? 1 : -1),
            'date': (e['confirmedAt'] ?? e['paidAt'] ?? e['requestedAt'] ?? '')
                .toString(),
            'kind': received ? 3 : 2,
          });
        }
        newEvents.sort(
          (a, b) => (b['date'] ?? '').toString().compareTo(
            (a['date'] ?? '').toString(),
          ),
        );
        _cachedEventsByGroup[group] = newEvents;
        _events = newEvents;
      }
      if (mounted && generation == _generation) {
        setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted && generation == _generation) {
        setState(() {
          _error = tr(
            context,
            'Không tải được dữ liệu. Hãy thử lại.',
            'Could not load data. Please retry.',
          );
          _loading = false;
        });
      }
    }
  }

  String _dateGroupKey(String rawDate) {
    final parsed = DateTime.tryParse(rawDate);
    if (parsed == null) return rawDate.split('T').first;
    final local = parsed.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(local.year, local.month, local.day);
    final diff = today.difference(dateOnly).inDays;
    if (diff == 0) return tr(context, 'Hôm nay', 'Today');
    if (diff == 1) return tr(context, 'Hôm qua', 'Yesterday');
    return DateFormat('dd/MM/yyyy').format(local);
  }

  String _eventTitle(Map<String, dynamic> e) {
    final kind = e['kind'] as int? ?? 1;
    final title = e['title']?.toString() ?? '';
    if (kind == 3) {
      return tr(context, 'Nhận từ $title', 'Received from $title');
    }
    if (kind == 2) {
      return tr(context, 'Thanh toán cho $title', 'Paid $title');
    }
    return title;
  }

  String _eventSubtitle(Map<String, dynamic> e) {
    final kind = e['kind'] as int? ?? 1;
    final actor = e['actor']?.toString() ?? '';
    if (kind == 3)
      return tr(context, 'Đã xác nhận nhận tiền', 'Confirmed receipt');
    if (kind == 2)
      return tr(context, 'Đã xác nhận thanh toán', 'Confirmed payment');
    if (actor.isNotEmpty) {
      return tr(context, '$actor đã trả', 'Paid by $actor');
    }
    return tr(context, 'Khoản chi', 'Expense');
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.history
              ? tr(context, 'Lịch sử', 'History')
              : tr(context, 'Thống kê', 'Statistics'),
        ),
        actions: const [NotificationBell()],
      ),
      body: RefreshIndicator(
        color: scheme.primary,
        onRefresh: _initialize,
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
                96,
              ),
              children: [
                if (_groups.isNotEmpty)
                  DropdownButtonFormField<int>(
                    initialValue: _group,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: tr(context, 'Nhóm', 'Group'),
                      prefixIcon: const Icon(Icons.group_outlined),
                    ),
                    items: _groups
                        .map(
                          (g) => DropdownMenuItem(
                            value: (g['id'] as num).toInt(),
                            child: Text(
                              g['name'].toString(),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      _group = v;
                      _load();
                    },
                  ),
                const SizedBox(height: AppDimensions.s12),
                if (widget.history && _groups.isNotEmpty) ...[
                  TextField(
                    controller: _searchController,
                    onChanged: (v) =>
                        setState(() => _searchQuery = v.trim().toLowerCase()),
                    decoration: InputDecoration(
                      hintText: tr(
                        context,
                        'Tìm theo tên khoản chi hoặc thành viên...',
                        'Search by title or member...',
                      ),
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchQuery.isEmpty
                          ? null
                          : IconButton(
                              tooltip: tr(context, 'Xóa tìm kiếm', 'Clear'),
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.s12),
                ],
                PdfTabs(
                  labels: widget.history
                      ? [
                          tr(context, 'Tất cả', 'All'),
                          tr(context, 'Chi tiêu', 'Expenses'),
                          tr(context, 'Đã trả', 'Paid'),
                          tr(context, 'Đã nhận', 'Received'),
                        ]
                      : [
                          tr(context, 'Tuần', 'Week'),
                          tr(context, 'Tháng', 'Month'),
                          tr(context, 'Tất cả', 'All'),
                        ],
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
                  },
                ),
                const SizedBox(height: AppDimensions.s16),
                if (_loading)
                  const Column(
                    children: [
                      ShimmerBox(
                        width: double.infinity,
                        height: 84,
                        radius: 12,
                      ),
                      SizedBox(height: 8),
                      ShimmerBox(
                        width: double.infinity,
                        height: 84,
                        radius: 12,
                      ),
                    ],
                  )
                else if (_error != null)
                  AppErrorState(
                    title: tr(context, 'Lỗi tải dữ liệu', 'Load error'),
                    message: _error!,
                    onRetry: _initialize,
                  )
                else if (_groups.isEmpty)
                  AppEmptyState(
                    icon: CupertinoIcons.clock,
                    title: tr(context, 'Chưa có nhóm', 'No groups yet'),
                    message: tr(
                      context,
                      'Tạo hoặc tham gia nhóm để xem lịch sử và thống kê chi tiêu.',
                      'Create or join a group to view transaction history and analytics.',
                    ),
                  )
                else if (widget.history)
                  _buildHistoryList(scheme)
                else if (_stats != null)
                  _buildStatsContent(scheme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryList(ColorScheme scheme) {
    final filtered = _events.where((e) {
      if (_filter != 0 && e['kind'] != _filter) return false;
      if (_searchQuery.isNotEmpty) {
        final haystack = '${_eventTitle(e)} ${e['actor'] ?? ''}'.toLowerCase();
        if (!haystack.contains(_searchQuery)) return false;
      }
      return true;
    }).toList();

    if (filtered.isEmpty) {
      return AppEmptyState(
        icon: CupertinoIcons.doc_text_search,
        title: tr(context, 'Chưa có giao dịch', 'No transactions'),
        message: tr(
          context,
          'Không có giao dịch nào phù hợp trong mục này.',
          'No matching transactions in this category.',
        ),
      );
    }

    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final e in filtered) {
      final key = _dateGroupKey(e['date']?.toString() ?? '');
      grouped.putIfAbsent(key, () => []).add(e);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final entry in grouped.entries) ...[
          Padding(
            padding: const EdgeInsets.only(
              top: AppDimensions.s8,
              bottom: AppDimensions.s8,
            ),
            child: SectionLabel(title: entry.key),
          ),
          PremiumSurface(
            padding: EdgeInsets.zero,
            radius: AppDimensions.r12,
            child: Column(
              children: [
                for (int i = 0; i < entry.value.length; i++) ...[
                  _historyRow(entry.value[i], scheme),
                  if (i < entry.value.length - 1)
                    const Divider(height: 1, indent: 64),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.s12),
        ],
      ],
    );
  }

  Widget _historyRow(Map<String, dynamic> e, ColorScheme scheme) {
    final kind = e['kind'] as int? ?? 1;
    final amount = (e['amount'] as num?)?.toDouble() ?? 0;
    final isIncoming = amount > 0;
    final color = kind == 3
        ? AppColors.successFor(context)
        : kind == 2
        ? scheme.primary
        : scheme.onSurface;
    final icon = kind == 3
        ? CupertinoIcons.arrow_down_left
        : kind == 2
        ? CupertinoIcons.arrow_up_right
        : Icons.receipt_long_outlined;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: (kind == 1 ? scheme.primary : color).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: kind == 1 ? scheme.primary : color),
      ),
      title: Text(
        _eventTitle(e),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
      ),
      subtitle: Text(
        _eventSubtitle(e),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
      ),
      trailing: Text(
        '${isIncoming ? '+' : '-'}${money(amount.abs())}',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isIncoming ? AppColors.successFor(context) : scheme.onSurface,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }

  Widget _buildStatsContent(ColorScheme scheme) {
    final stats = _stats!;
    final periodLabels = [
      tr(context, 'Tổng chi tiêu tuần này', 'This week total spend'),
      tr(context, 'Tổng chi tiêu tháng này', 'This month total spend'),
      tr(context, 'Tổng chi tiêu toàn thời gian', 'All-time total spend'),
    ];
    final sortedMembers = stats.byMember.toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PremiumSurface(
          padding: const EdgeInsets.all(AppDimensions.s20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                periodLabels[_period],
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppDimensions.s8),
              Text(
                money(stats.totalExpense),
                style: TextStyle(
                  fontSize: 30,
                  color: scheme.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.6,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.s20),
        SectionLabel(
          title: tr(context, 'Chi tiêu theo danh mục', 'By category'),
        ),
        const SizedBox(height: AppDimensions.s8),
        PremiumSurface(
          radius: AppDimensions.r12,
          child: stats.byCategory.isEmpty
              ? Text(
                  tr(context, 'Chưa có khoản chi.', 'No expenses yet.'),
                  style: Theme.of(context).textTheme.bodySmall,
                )
              : Column(
                  children: [
                    for (int i = 0; i < stats.byCategory.length; i++) ...[
                      _categoryBar(
                        stats.byCategory[i],
                        stats.totalExpense,
                        scheme,
                      ),
                      if (i < stats.byCategory.length - 1)
                        const SizedBox(height: AppDimensions.s16),
                    ],
                  ],
                ),
        ),
        const SizedBox(height: AppDimensions.s20),
        SectionLabel(
          title: tr(context, 'Chi tiêu theo thành viên', 'By member'),
        ),
        const SizedBox(height: AppDimensions.s8),
        PremiumSurface(
          padding: EdgeInsets.zero,
          radius: AppDimensions.r12,
          child: sortedMembers.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(AppDimensions.s16),
                  child: Text(
                    tr(context, 'Chưa có dữ liệu.', 'No data yet.'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                )
              : Column(
                  children: [
                    for (int i = 0; i < sortedMembers.length; i++) ...[
                      ListTile(
                        leading: PersonBadge(
                          sortedMembers[i].label,
                          color: scheme.primary,
                        ),
                        title: Text(
                          '${i + 1}. ${sortedMembers[i].label}',
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        trailing: Text(
                          money(sortedMembers[i].amount),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurface,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                      if (i < sortedMembers.length - 1)
                        const Divider(height: 1, indent: 64),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  Widget _categoryBar(ChartSlice item, double total, ColorScheme scheme) {
    final ratio = total <= 0 ? 0.0 : (item.amount / total).clamp(0.0, 1.0);
    final pct = (ratio * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${money(item.amount)} ($pct%)',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: ratio,
          minHeight: 6,
          borderRadius: BorderRadius.circular(4),
          color: scheme.primary,
          backgroundColor: AppColors.subtleFillFor(context),
        ),
      ],
    );
  }
}
