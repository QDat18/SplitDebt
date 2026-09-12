import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/premium_ui.dart';
import '../../data/api.dart';
import '../../widgets/design.dart';
import '../help/quick_guide_screen.dart';
import 'forms.dart';

class DebtsReferenceView extends StatelessWidget {
  const DebtsReferenceView({
    super.key,
    required this.groups,
    required this.onOpenGroup,
    required this.onOpenHistory,
    required this.onRefresh,
  });

  final List<Map<String, dynamic>> groups;
  final Future<void> Function(Map<String, dynamic>) onOpenGroup;
  final VoidCallback onOpenHistory;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final payable = groups.fold<int>(0, (sum, g) => sum + math.max(0, -asInt(g['balance'])));
    final receivable = groups.fold<int>(0, (sum, g) => sum + math.max(0, asInt(g['balance'])));
    final oweCount = groups.where((g) => asInt(g['balance']) < 0).length;
    final receiveCount = groups.where((g) => asInt(g['balance']) > 0).length;
    final actionable = groups.where((g) {
      final b = asInt(g['balance']);
      return b != 0 || asInt(g['pendingOutgoing'] ?? 0) > 0 || asInt(g['pendingIncoming'] ?? 0) > 0;
    }).toList();
    final currency = groups.isEmpty ? 'VND' : groups.first['currency']?.toString() ?? 'VND';

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        key: const ValueKey('debts-reference-view'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 34),
        children: [
          StaggerReveal(
            index: 0,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Lẽ ra phải thế.',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: AppColors.textPrimary,
                          fontSize: 32,
                          height: 1.06,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Theo dõi chi tiết các khoản nợ của bạn.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Image.asset(
                  'assets/reference/debt-ledger-3d.png',
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: _DebtSummaryMetric(
                  index: 1,
                  icon: Icons.north_east_rounded,
                  label: 'BẠN NỢ',
                  count: oweCount,
                  amount: payable,
                  currency: currency,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DebtSummaryMetric(
                  index: 2,
                  icon: Icons.south_west_rounded,
                  label: 'ĐƯỢC NHẬN',
                  count: receiveCount,
                  amount: receivable,
                  currency: currency,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Text('Chi tiết khoản nợ', style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              Text('${actionable.length} mục', style: Theme.of(context).textTheme.labelMedium),
            ],
          ),
          const SizedBox(height: 12),
          if (actionable.isEmpty)
            const EmptyState(
              title: 'Tất cả đã cân bằng',
              description: 'Không còn khoản nào cần trả hoặc cần thu trong các nhóm.',
              icon: Icons.verified_rounded,
            )
          else
            ...actionable.asMap().entries.map((entry) {
              final i = entry.key;
              final g = entry.value;
              final balance = asInt(g['balance']);
              final pendingOut = asInt(g['pendingOutgoing'] ?? 0);
              final pendingIn = asInt(g['pendingIncoming'] ?? 0);
              final waiting = balance == 0 && (pendingOut > 0 || pendingIn > 0);
              final amount = waiting ? (pendingOut > 0 ? pendingOut : pendingIn) : balance.abs();
              final positive = waiting ? pendingIn > 0 : balance > 0;
              return StaggerReveal(
                index: 3 + i,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _DebtReferenceCard(
                    group: g,
                    amount: amount,
                    positive: positive,
                    waiting: waiting,
                    onTap: () => onOpenGroup(g),
                  ),
                ),
              );
            }),
          const SizedBox(height: 4),
          TextButton.icon(
            onPressed: onOpenHistory,
            icon: const Icon(Icons.history_rounded),
            label: const Text('Xem lịch sử đã thanh toán'),
          ),
        ],
      ),
    );
  }
}

class _DebtSummaryMetric extends StatelessWidget {
  const _DebtSummaryMetric({
    required this.index,
    required this.icon,
    required this.label,
    required this.count,
    required this.amount,
    required this.currency,
    required this.color,
  });

  final int index;
  final IconData icon;
  final String label;
  final int count;
  final int amount;
  final String currency;
  final Color color;

  @override
  Widget build(BuildContext context) => StaggerReveal(
        index: index,
        child: Surface(
          interactive: false,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: color),
                  const Spacer(),
                  Text('$count', style: TextStyle(color: color, fontWeight: FontWeight.w900)),
                ],
              ),
              const SizedBox(height: 16),
              Text(label, style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 5),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: AnimatedMoneyText(
                  amount: amount,
                  currency: currency,
                  style: TextStyle(
                    fontFamily: 'Geist',
                    color: color,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.8,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

class _DebtReferenceCard extends StatelessWidget {
  const _DebtReferenceCard({
    required this.group,
    required this.amount,
    required this.positive,
    required this.waiting,
    required this.onTap,
  });

  final Map<String, dynamic> group;
  final int amount;
  final bool positive;
  final bool waiting;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = waiting ? AppColors.warning : positive ? AppColors.primary : AppColors.error;
    final currency = group['currency']?.toString() ?? 'VND';
    final memberCount = asInt(group['memberCount'] ?? 0);
    final pendingOut = asInt(group['pendingOutgoing'] ?? 0);
    return Surface(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border(top: BorderSide(color: color.withValues(alpha: .56), width: 1.4)),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: .08), blurRadius: 24, spreadRadius: -8),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                GroupArtwork(group['name']?.toString() ?? 'Nhóm', size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(group['name']?.toString() ?? 'Nhóm', style: const TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 3),
                      Text('$memberCount thành viên', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    AnimatedMoneyText(
                      amount: amount,
                      currency: currency,
                      prefix: positive ? '+' : '-',
                      style: TextStyle(
                        fontFamily: 'Geist',
                        color: color,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      waiting
                          ? pendingOut > 0
                              ? 'Chờ xác nhận'
                              : 'Cần xác nhận'
                          : positive
                              ? 'Họ nợ bạn'
                              : 'Bạn cần trả',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: onTap,
                icon: Icon(waiting ? Icons.schedule_rounded : positive ? Icons.notifications_active_outlined : Icons.payments_outlined),
                label: Text(waiting ? 'Mở chi tiết' : positive ? 'Nhắc nợ' : 'Thanh toán'),
                style: FilledButton.styleFrom(
                  backgroundColor: color.withValues(alpha: .16),
                  foregroundColor: color,
                  shadowColor: Colors.transparent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StatsReferenceView extends StatefulWidget {
  const StatsReferenceView({
    super.key,
    required this.groups,
    required this.onRefresh,
  });

  final List<Map<String, dynamic>> groups;
  final Future<void> Function() onRefresh;

  @override
  State<StatsReferenceView> createState() => _StatsReferenceViewState();
}

class _StatsReferenceViewState extends State<StatsReferenceView> {
  int? groupId;
  String range = 'MONTH';
  Future<Map<String, dynamic>>? future;

  @override
  void initState() {
    super.initState();
    _syncGroup();
  }

  @override
  void didUpdateWidget(covariant StatsReferenceView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncGroup();
  }

  void _syncGroup() {
    if (widget.groups.isEmpty) {
      groupId = null;
      future = null;
      return;
    }
    final ids = widget.groups.map((g) => asInt(g['id'])).toSet();
    final nextId = groupId != null && ids.contains(groupId) ? groupId! : asInt(widget.groups.first['id']);
    if (groupId != nextId || future == null) {
      groupId = nextId;
      future = _load();
    }
  }

  Future<Map<String, dynamic>> _load() async => Map<String, dynamic>.from(
        await Api.call('/groups/$groupId/statistics?range=$range') as Map,
      );

  void _selectGroup(int? value) {
    if (value == null || value == groupId) return;
    setState(() {
      groupId = value;
      future = _load();
    });
  }

  void _selectRange(String value) {
    if (value == range) return;
    setState(() {
      range = value;
      future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.groups.isEmpty) {
      return RefreshIndicator(
        onRefresh: widget.onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            EmptyState(
              title: 'Chưa có dữ liệu thống kê',
              description: 'Tạo nhóm và thêm khoản chi để bắt đầu.',
              icon: Icons.analytics_outlined,
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async {
        await widget.onRefresh();
        if (!mounted) return;
        setState(() {
          future = _load();
        });
      },
      child: FutureBuilder<Map<String, dynamic>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              children: [
                EmptyState(
                  title: 'Không thể tải thống kê',
                  description: snapshot.error.toString(),
                  icon: Icons.cloud_off_rounded,
                ),
              ],
            );
          }
          final d = snapshot.data!;
          final categories = maps(d['byCategory']);
          final payers = maps(d['byPayer']);
          final currency = d['currency']?.toString() ?? 'VND';
          final total = asInt(d['totalExpense']);
          final mySpent = asInt(d['mySpent'] ?? 0);
          return ListView(
            key: const ValueKey('stats-reference-view'),
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 34),
            children: [
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: groupId,
                      decoration: const InputDecoration(labelText: 'Nhóm'),
                      items: widget.groups
                          .map((g) => DropdownMenuItem<int>(value: asInt(g['id']), child: Text(g['name'].toString())))
                          .toList(),
                      onChanged: _selectGroup,
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 126,
                    child: DropdownButtonFormField<String>(
                      initialValue: range,
                      decoration: const InputDecoration(labelText: 'Kỳ'),
                      items: const [
                        DropdownMenuItem(value: 'DAY', child: Text('Ngày')),
                        DropdownMenuItem(value: 'MONTH', child: Text('Tháng')),
                        DropdownMenuItem(value: 'YEAR', child: Text('Năm')),
                      ],
                      onChanged: (value) {
                        if (value != null) _selectRange(value);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _StatMetricCard(
                      index: 0,
                      label: 'MÌNH ĐÃ\nCHI',
                      value: mySpent,
                      currency: currency,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatMetricCard(
                      index: 1,
                      label: 'TỔNG CHI\nCỦA NHÓM',
                      value: total,
                      currency: currency,
                      color: AppColors.tertiary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Surface(
                interactive: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Chi theo danh mục', style: Theme.of(context).textTheme.titleMedium),
                        const Spacer(),
                        const Icon(Icons.more_horiz_rounded, color: AppColors.textSecondary),
                      ],
                    ),
                    const SizedBox(height: 18),
                    if (categories.isEmpty)
                      const SizedBox(
                        height: 190,
                        child: Center(child: Text('Chưa có dữ liệu danh mục')),
                      )
                    else
                      Center(child: _ReferenceDonut(entries: categories, total: total, currency: currency)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Surface(
                interactive: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Ai đã chi trong nhóm', style: Theme.of(context).textTheme.titleMedium),
                        const Spacer(),
                        Text('Chi tiết ›', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.primary)),
                      ],
                    ),
                    const SizedBox(height: 22),
                    if (payers.isEmpty)
                      const SizedBox(height: 150, child: Center(child: Text('Chưa có dữ liệu thành viên')))
                    else
                      _MemberBars(payers: payers, currency: currency),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatMetricCard extends StatelessWidget {
  const _StatMetricCard({
    required this.index,
    required this.label,
    required this.value,
    required this.currency,
    required this.color,
  });
  final int index;
  final String label;
  final int value;
  final String currency;
  final Color color;

  @override
  Widget build(BuildContext context) => StaggerReveal(
        index: index,
        child: Surface(
          interactive: false,
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelSmall, maxLines: 2),
              const SizedBox(height: 13),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: AnimatedMoneyText(
                  amount: value,
                  currency: currency,
                  style: TextStyle(
                    fontFamily: 'Geist',
                    color: color,
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.8,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

class _ReferenceDonut extends StatelessWidget {
  const _ReferenceDonut({required this.entries, required this.total, required this.currency});
  final List<Map<String, dynamic>> entries;
  final int total;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final top = entries.isEmpty ? '—' : entries.first['label']?.toString() ?? '—';
    return SizedBox(
      width: 230,
      height: 230,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 850),
            curve: Curves.easeOutCubic,
            tween: Tween(begin: 0, end: 1),
            builder: (context, progress, _) => CustomPaint(
              size: const Size.square(220),
              painter: _DonutPainter(entries: entries, progress: progress),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Top', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 2),
              Text(top, style: const TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 3),
              Text(money(total, currency), style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({required this.entries, required this.progress});
  final List<Map<String, dynamic>> entries;
  final double progress;
  static const colors = [AppColors.primary, AppColors.tertiary, AppColors.secondary, Color(0xFF7D8CFF), Color(0xFF68D8FF)];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 22;
    final total = entries.fold<double>(0, (s, e) => s + asInt(e['amount']).toDouble());
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 22
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: .05);
    canvas.drawCircle(center, radius, track);
    if (total <= 0) return;
    var start = -math.pi / 2;
    for (var i = 0; i < entries.length; i++) {
      final share = asInt(entries[i]['amount']) / total;
      final sweep = math.pi * 2 * share * progress;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 22
        ..strokeCap = StrokeCap.round
        ..shader = LinearGradient(
          colors: [colors[i % colors.length], colors[(i + 1) % colors.length]],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), start, math.max(0, sweep - .035), false, paint);
      start += math.pi * 2 * share;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) => oldDelegate.progress != progress || oldDelegate.entries != entries;
}

class _MemberBars extends StatelessWidget {
  const _MemberBars({required this.payers, required this.currency});
  final List<Map<String, dynamic>> payers;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final data = payers.take(5).toList();
    final maxValue = data.fold<int>(1, (m, e) => math.max(m, asInt(e['amount'])));
    return SizedBox(
      height: 176,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: data.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          final value = asInt(item['amount']);
          final ratio = value / maxValue;
          final colors = [AppColors.primary, AppColors.tertiary, AppColors.secondary, const Color(0xFF7D8CFF), AppColors.textSecondary];
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Tooltip(message: money(value, currency), child: Text('${(ratio * 100).round()}%', style: Theme.of(context).textTheme.labelSmall)),
                  const SizedBox(height: 5),
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: ratio.clamp(.08, 1.0).toDouble()),
                    duration: Duration(milliseconds: 500 + i * 90),
                    curve: Curves.easeOutBack,
                    builder: (context, h, _) => Container(
                      height: 112 * h,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [colors[i % colors.length].withValues(alpha: .35), colors[i % colors.length]],
                        ),
                        boxShadow: [BoxShadow(color: colors[i % colors.length].withValues(alpha: .20), blurRadius: 12)],
                      ),
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    item['label']?.toString().split(' ').first ?? '?',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class ActivityHistoryScreen extends StatefulWidget {
  const ActivityHistoryScreen({super.key, required this.onOpenGroup, required this.onAdd});
  final Future<void> Function(Map<String, dynamic>) onOpenGroup;
  final VoidCallback onAdd;

  @override
  State<ActivityHistoryScreen> createState() => _ActivityHistoryScreenState();
}

class _ActivityHistoryScreenState extends State<ActivityHistoryScreen> {
  late Future<Map<String, dynamic>> future;

  @override
  void initState() {
    super.initState();
    future = _load();
  }

  Future<Map<String, dynamic>> _load() async => Map<String, dynamic>.from(await Api.call('/activity?limit=60&offset=0') as Map);

  Future<void> _refresh() async {
    final next = _load();
    setState(() {
      future = next;
    });
    try { await next; } catch (_) {}
  }

  void _nav(int index) {
    if (index == 3) return;
    Navigator.pop(context, index);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.transparent,
        body: PremiumBackground(
          child: SafeArea(
            child: Column(
              children: [
                LuminousBrandHeader(
                  section: 'Lịch sử',
                  trailing: IconButton(
                    tooltip: 'Đóng',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ),
                Expanded(
                  child: FutureBuilder<Map<String, dynamic>>(
                    future: future,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
                      if (snapshot.hasError) {
                        return EmptyState(title: 'Không thể tải lịch sử', description: snapshot.error.toString(), icon: Icons.cloud_off_rounded);
                      }
                      final items = maps(snapshot.data!['items']);
                      return RefreshIndicator(
                        onRefresh: _refresh,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 22, 20, 40),
                          children: [
                            const Text(
                              'Lịch sử hoạt động',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                color: AppColors.textPrimary,
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -.9,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text('Theo dõi các mốc tài chính và cập nhật nhóm gần đây.', style: Theme.of(context).textTheme.bodyMedium),
                            const SizedBox(height: 22),
                            if (items.isEmpty)
                              const EmptyState(title: 'Chưa có hoạt động', description: 'Hoạt động chi tiêu và thanh toán sẽ xuất hiện tại đây.', icon: Icons.history_rounded)
                            else
                              _HistoryTimeline(items: items, onOpenGroup: widget.onOpenGroup),
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
        bottomNavigationBar: LuminousExtendedBottomNav(selectedIndex: 3, onSelected: _nav, onAdd: widget.onAdd),
      );
}

class _HistoryTimeline extends StatelessWidget {
  const _HistoryTimeline({required this.items, required this.onOpenGroup});
  final List<Map<String, dynamic>> items;
  final Future<void> Function(Map<String, dynamic>) onOpenGroup;

  @override
  Widget build(BuildContext context) => Column(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final kind = item['kind']?.toString() ?? '';
          final amount = asInt(item['amount'] ?? item['totalAmount'] ?? 0);
          final currency = item['currency']?.toString() ?? 'VND';
          final positive = kind.contains('RECEIVE') || kind.contains('CONFIRM') || kind.contains('SETTLED');
          final color = positive ? AppColors.primary : kind.contains('EXPENSE') ? AppColors.secondary : AppColors.tertiary;
          final title = item['title']?.toString() ?? item['description']?.toString() ?? kind;
          final groupName = item['groupName']?.toString() ?? 'Nhóm';
          final time = item['createdAt']?.toString() ?? item['expenseDate']?.toString() ?? '';
          return StaggerReveal(
            index: index,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 32,
                    child: Stack(
                      alignment: Alignment.topCenter,
                      children: [
                        if (index < items.length - 1)
                          Positioned(top: 20, bottom: -12, child: Container(width: 1, color: AppColors.glassBorder)),
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color.withValues(alpha: .15),
                            border: Border.all(color: color.withValues(alpha: .5)),
                            boxShadow: [BoxShadow(color: color.withValues(alpha: .15), blurRadius: 12)],
                          ),
                          child: Icon(kind.contains('EXPENSE') ? Icons.receipt_long_rounded : Icons.swap_horiz_rounded, size: 12, color: color),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Surface(
                        onTap: () {
                          final groupId = item['groupId'];
                          if (groupId != null) onOpenGroup({'id': groupId, 'name': groupName});
                        },
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(child: Text(time, style: Theme.of(context).textTheme.labelSmall)),
                                if (positive)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: .12), borderRadius: BorderRadius.circular(99)),
                                    child: const Text('Đã xong', style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w800)),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                            const SizedBox(height: 6),
                            Text('Nhóm: $groupName', style: Theme.of(context).textTheme.bodySmall),
                            if (kind.contains('expense')) ...[
                              const SizedBox(height: 2),
                              Text('Người trả: ${item['payerName'] ?? 'Không rõ'}', style: Theme.of(context).textTheme.bodySmall),
                            ],
                            const SizedBox(height: 2),
                            Text('Lúc: ${dateLabel(time)}', style: Theme.of(context).textTheme.bodySmall),
                            if (amount != 0) ...[
                              const SizedBox(height: 8),
                              Text(
                                '${positive ? '+' : '-'}${money(amount.abs(), currency)}',
                                style: TextStyle(fontFamily: 'Geist', color: color, fontWeight: FontWeight.w900),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      );
}

class ProfileReferenceScreen extends StatefulWidget {
  const ProfileReferenceScreen({super.key, required this.onAdd});
  final VoidCallback onAdd;

  @override
  State<ProfileReferenceScreen> createState() => _ProfileReferenceScreenState();
}

class _ProfileReferenceScreenState extends State<ProfileReferenceScreen> {
  late Future<Map<String, dynamic>> future;

  @override
  void initState() {
    super.initState();
    future = _load();
  }

  Future<Map<String, dynamic>> _load() async => Map<String, dynamic>.from(await Api.call('/overview') as Map);

  Future<void> _refresh() async {
    final next = _load();
    setState(() {
      future = next;
    });
    try { await next; } catch (_) {}
  }

  void _nav(int index) {
    if (index == 5) return;
    Navigator.pop(context, index);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.transparent,
        body: PremiumBackground(
          child: SafeArea(
            child: Column(
              children: [
                LuminousBrandHeader(
                  section: 'Profile',
                  trailing: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
                ),
                Expanded(
                  child: FutureBuilder<Map<String, dynamic>>(
                    future: future,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
                      if (snapshot.hasError) return EmptyState(title: 'Không thể tải hồ sơ', description: snapshot.error.toString());
                      final me = Map<String, dynamic>.from(snapshot.data!['me'] as Map);
                      final name = me['name']?.toString() ?? 'Người dùng';
                      final email = me['email']?.toString() ?? '';
                      final phone = me['phone']?.toString() ?? '';
                      final avatarUrl = me['avatarUrl']?.toString();
                      return RefreshIndicator(
                        onRefresh: _refresh,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                          children: [
                            Center(
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: 132,
                                    height: 132,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: const SweepGradient(colors: [AppColors.tertiary, AppColors.primary, AppColors.tertiary]),
                                      boxShadow: [
                                        BoxShadow(color: AppColors.tertiary.withValues(alpha: .22), blurRadius: 28),
                                        BoxShadow(color: AppColors.primary.withValues(alpha: .18), blurRadius: 42),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    width: 120,
                                    height: 120,
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.background),
                                    child: Avatar(name, radius: 56, imageUrl: avatarUrl),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(name, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                            const SizedBox(height: 5),
                            Text(email, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
                            const SizedBox(height: 22),
                            Surface(
                              onTap: () => showInfo(context, 'SplitDebt ghi nhận giao dịch; tiền được chuyển qua phương thức thanh toán bên ngoài ứng dụng.', title: 'Nhận Tiền Nhanh'),
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: .12),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(Icons.qr_code_2_rounded, color: AppColors.primary, size: 30),
                                  ),
                                  const SizedBox(width: 13),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Nhận Tiền Nhanh', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                                        const SizedBox(height: 3),
                                        Text('Hiển thị mã nhận tiền của bạn', style: Theme.of(context).textTheme.bodySmall),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.qr_code_rounded, color: AppColors.textSecondary),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text('CÀI ĐẶT', style: Theme.of(context).textTheme.labelSmall),
                            const SizedBox(height: 10),
                            Surface(
                              padding: EdgeInsets.zero,
                              child: Column(
                                children: [
                                  _ProfileSettingTile(
                                    icon: Icons.account_balance_rounded,
                                    color: AppColors.tertiary,
                                    title: 'Phương thức thanh toán',
                                    onTap: () => showInfo(context, 'Bạn có thể ghi chú phương thức thanh toán ở từng lần thanh toán.', title: 'Phương thức thanh toán'),
                                  ),
                                  const Divider(height: 1),
                                  _ProfileSettingTile(
                                    icon: Icons.notifications_none_rounded,
                                    color: AppColors.tertiary,
                                    title: 'Thông báo',
                                    onTap: () => showInfo(context, 'Nhấn chuông trên Trang chủ để xem và đánh dấu thông báo đã đọc.', title: 'Thông báo'),
                                  ),
                                  const Divider(height: 1),
                                  _ProfileSettingTile(
                                    icon: Icons.lock_outline_rounded,
                                    color: AppColors.primary,
                                    title: 'Đổi mật khẩu',
                                    onTap: () => showInfo(context, 'Dùng chức năng Quên mật khẩu tại màn đăng nhập để đặt mật khẩu mới.', title: 'Đổi mật khẩu'),
                                  ),
                                  const Divider(height: 1),
                                  _ProfileSettingTile(
                                    icon: Icons.person_outline_rounded,
                                    color: AppColors.primary,
                                    title: 'Chỉnh sửa hồ sơ',
                                    onTap: () async {
                                      final changed = await Navigator.push<bool>(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => EditProfileScreen(name: name, phone: phone, avatarUrl: avatarUrl ?? ''),
                                        ),
                                      );
                                      if (changed == true && mounted) await _refresh();
                                    },
                                  ),
                                  const Divider(height: 1),
                                  _ProfileSettingTile(
                                    icon: Icons.school_outlined,
                                    color: AppColors.primary,
                                    title: 'Hướng dẫn sử dụng',
                                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QuickGuideScreen())),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            OutlinedButton.icon(
                              onPressed: () async {
                                await Session.signOut();
                                if (!context.mounted) return;
                                // Profile/History/Group đều có thể nằm trên HomeScreen.
                                // Sau khi xóa session, đưa Navigator về route gốc để
                                // SessionGate hiển thị lại màn Đăng nhập / Đăng ký.
                                Navigator.of(context).popUntil((route) => route.isFirst);
                              },
                              icon: const Icon(Icons.logout_rounded, color: AppColors.error),
                              label: const Text('ĐĂNG XUẤT', style: TextStyle(color: AppColors.error, letterSpacing: .8)),
                            ),
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
        bottomNavigationBar: LuminousExtendedBottomNav(selectedIndex: 5, onSelected: _nav, onAdd: widget.onAdd),
      );
}

class _ProfileSettingTile extends StatelessWidget {
  const _ProfileSettingTile({required this.icon, required this.color, required this.title, required this.onTap});
  final IconData icon;
  final Color color;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        onTap: onTap,
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(color: color.withValues(alpha: .12), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        trailing: const Icon(Icons.chevron_right_rounded),
      );
}
