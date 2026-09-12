import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/premium_ui.dart';
import '../../core/widgets/reference_ui.dart';
import '../../data/api.dart';
import '../../widgets/design.dart';
import '../help/quick_guide_screen.dart';
import 'forms.dart';
import 'group_screen.dart';
import 'reference_pages.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int tab = 0;
  String query = '';
  late Future<Map<String, dynamic>> future;

  @override
  void initState() {
    super.initState();
    future = load();
  }

  Future<void> _openGuide() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const QuickGuideScreen()));
  }

  Future<void> _openNotifications() async {
    try {
      await Api.call('/notifications/read-all', method: 'POST');
    } catch (_) {
      // Notification list should still be reachable during a temporary network failure.
    }
    if (!mounted) return;
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
    if (mounted) await refresh();
  }

  Future<Map<String, dynamic>> load() async =>
      Map<String, dynamic>.from(await Api.call('/overview') as Map);

  Future<void> refresh() async {
    final next = load();
    setState(() {
      future = next;
    });
    try {
      await next;
    } catch (_) {}
  }

  void _selectTab(int value) {
    final next = value.clamp(0, 3).toInt();
    if (next == tab) return;
    HapticFeedback.selectionClick();
    setState(() => tab = next);
  }

  Future<void> _selectExtendedNav(int value) async {
    HapticFeedback.selectionClick();
    switch (value) {
      case 0:
        _selectTab(0);
        break;
      case 1:
        _selectTab(1);
        break;
      case 2:
        _selectTab(2);
        break;
      case 3:
        await _openHistory();
        break;
      case 4:
        _selectTab(3);
        break;
      case 5:
        await _openProfile();
        break;
    }
  }

  Widget _tabTransition(Widget child) => AnimatedSwitcher(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 360),
        reverseDuration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 240),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        layoutBuilder: (currentChild, previousChildren) => Stack(
          alignment: Alignment.topCenter,
          children: [
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        ),
        transitionBuilder: (child, animation) {
          final eased = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
          return FadeTransition(
            opacity: eased,
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(.035, .015), end: Offset.zero).animate(eased),
              child: ScaleTransition(
                scale: Tween<double>(begin: .988, end: 1).animate(eased),
                child: child,
              ),
            ),
          );
        },
        child: child,
      );

  Future<void> openGroup(Map<String, dynamic> group) async {
    final nav = await Navigator.push<int>(
      context,
      MaterialPageRoute(builder: (_) => GroupScreen(id: asInt(group['id']))),
    );
    if (!mounted) return;
    if (nav != null) await _handleExtendedNav(nav);
    await refresh();
  }

  Future<void> create() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
    );
    if (result == true && mounted) {
      showSuccess(
        context,
        'Nhóm mới đã sẵn sàng. Bạn có thể mời thành viên và thêm khoản chi đầu tiên.',
        title: 'Đã tạo nhóm',
      );
      await refresh();
    }
  }

  Future<void> join() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const JoinGroupScreen()),
    );
    if (result == true && mounted) {
      showSuccess(
        context,
        'Bạn đã tham gia nhóm và có thể xem các khoản chi chung.',
        title: 'Đã tham gia nhóm',
      );
      await refresh();
    }
  }

  Future<void> _openHistory() async {
    final nav = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (_) => ActivityHistoryScreen(
          onOpenGroup: openGroup,
          onAdd: create,
        ),
      ),
    );
    if (!mounted) return;
    await _handleExtendedNav(nav);
  }

  Future<void> _openProfile() async {
    final nav = await Navigator.push<int>(
      context,
      MaterialPageRoute(builder: (_) => ProfileReferenceScreen(onAdd: create)),
    );
    if (!mounted) return;
    await refresh();
    if (!mounted) return;
    await _handleExtendedNav(nav);
  }

  Future<void> _handleExtendedNav(int? nav) async {
    if (nav == null) return;
    switch (nav) {
      case 0:
        _selectTab(0);
        break;
      case 1:
        _selectTab(1);
        break;
      case 2:
        _selectTab(2);
        break;
      case 3:
        await _openHistory();
        break;
      case 4:
        _selectTab(3);
        break;
      case 5:
        await _openProfile();
        break;
    }
  }

  Widget _header(Map<String, dynamic> data, Map<String, dynamic> me) {
    const sections = ['Tổng quan', 'Nhóm', 'Thanh toán', 'Thống kê'];
    return LuminousBrandHeader(
      section: sections[tab],
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Thông báo · nhấn để đánh dấu đã đọc',
            onPressed: _openNotifications,
            visualDensity: VisualDensity.compact,
            icon: Badge(
              isLabelVisible: asInt(data['unreadNotifications'] ?? 0) > 0,
              backgroundColor: AppColors.tertiary,
              textColor: const Color(0xFF472A00),
              label: Text('${data['unreadNotifications'] ?? 0}'),
              child: const Icon(Icons.notifications_none_rounded, size: 20),
            ),
          ),
          const SizedBox(width: 3),
          GestureDetector(
            onTap: _openProfile,
            child: Avatar(
              me['name']?.toString() ?? 'U',
              radius: 17,
              imageUrl: me['avatarUrl']?.toString(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dashboard(
    Map<String, dynamic> data,
    Map<String, dynamic> me,
    List<Map<String, dynamic>> groups,
  ) {
    final balances = maps(data['balances']);
    final summary = balances.isEmpty ? <String, dynamic>{} : balances.first;
    final currency = (summary['currency'] ??
            (groups.isEmpty ? 'VND' : groups.first['currency']) ??
            'VND')
        .toString();
    final payable = asInt(summary['payable'] ?? 0);
    final receivable = asInt(summary['receivable'] ?? 0);
    final rawName = (me['name']?.toString().trim().isNotEmpty == true)
        ? me['name'].toString().trim()
        : 'bạn';
    final firstName = rawName.split(RegExp(r'\s+')).last;
    final now = DateTime.now();
    const weekdays = <String>[
      'Thứ Hai',
      'Thứ Ba',
      'Thứ Tư',
      'Thứ Năm',
      'Thứ Sáu',
      'Thứ Bảy',
      'Chủ Nhật',
    ];
    final today = '${weekdays[now.weekday - 1]}, ${now.day} tháng ${now.month}';

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final phone = width < 600;
        final narrow = width < 380;
        final horizontal = narrow ? 12.0 : phone ? 20.0 : 28.0;
        final available = math.max(280.0, width - horizontal * 2).toDouble();
        final contentWidth = math.min(1120.0, available).toDouble();
        final twoColumns = contentWidth >= 760;
        final groupCardWidth = twoColumns ? (contentWidth - 14) / 2 : contentWidth;

        final quickActions = <Widget>[
          _DashboardActionChip(
            icon: Icons.group_add_rounded,
            label: 'Tạo nhóm mới',
            color: AppColors.primary,
            onTap: create,
          ),
          _DashboardActionChip(
            icon: Icons.login_rounded,
            label: 'Tham gia nhóm',
            color: AppColors.tertiary,
            onTap: join,
          ),
          _DashboardActionChip(
            icon: Icons.account_balance_wallet_rounded,
            label: 'Thanh toán',
            color: AppColors.secondary,
            onTap: () => _selectTab(2),
          ),
          _DashboardActionChip(
            icon: Icons.analytics_rounded,
            label: 'Thống kê',
            color: AppColors.primary,
            onTap: () => _selectTab(3),
          ),
        ];

        Widget groupsBody;
        if (groups.isEmpty) {
          groupsBody = EmptyState(
            title: 'Chưa có nhóm nào',
            description: 'Tạo nhóm đầu tiên hoặc tham gia bằng mã mời để bắt đầu chia chi phí.',
            icon: Icons.groups_2_outlined,
            action: FilledButton.icon(
              onPressed: create,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Tạo nhóm đầu tiên'),
            ),
          );
        } else if (twoColumns) {
          groupsBody = Wrap(
            spacing: 14,
            runSpacing: 14,
            children: groups.asMap().entries.map((entry) {
              final i = entry.key;
              final g = entry.value;
              return SizedBox(
                width: groupCardWidth,
                child: ReferenceGroupCard(
                  name: g['name'].toString(),
                  memberCount: asInt(g['memberCount']),
                  balance: asInt(g['balance']),
                  currency: g['currency']?.toString() ?? currency,
                  pending: asInt(g['pendingOutgoing'] ?? 0) > 0 ||
                      asInt(g['pendingIncoming'] ?? 0) > 0,
                  total: asInt(g['total'] ?? 0),
                  index: i,
                  onTap: () => openGroup(g),
                ),
              );
            }).toList(),
          );
        } else {
          groupsBody = Column(
            children: groups.asMap().entries.map((entry) {
              final i = entry.key;
              final g = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ReferenceGroupCard(
                  name: g['name'].toString(),
                  memberCount: asInt(g['memberCount']),
                  balance: asInt(g['balance']),
                  currency: g['currency']?.toString() ?? currency,
                  pending: asInt(g['pendingOutgoing'] ?? 0) > 0 ||
                      asInt(g['pendingIncoming'] ?? 0) > 0,
                  total: asInt(g['total'] ?? 0),
                  index: i,
                  onTap: () => openGroup(g),
                ),
              );
            }).toList(),
          );
        }

        return RefreshIndicator(
          onRefresh: refresh,
          child: ListView(
            key: const ValueKey('dashboard-reference'),
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(horizontal, phone ? 12 : 22, horizontal, 34),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      StaggerReveal(
                        index: 0,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Xin chào, $firstName 👋',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                          fontSize: narrow ? 23 : phone ? 27 : 32,
                                          letterSpacing: -.55,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    today,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: AppColors.textSecondary,
                                          fontSize: phone ? 12 : 14,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: narrow ? 10 : 13,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: .08),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: AppColors.primary.withValues(alpha: .16),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.groups_rounded, color: AppColors.primary, size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${groups.length}',
                                    style: const TextStyle(
                                      fontFamily: 'Geist',
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: phone ? 18 : 24),
                      if (phone)
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: [
                              for (var i = 0; i < quickActions.length; i++) ...[
                                if (i > 0) const SizedBox(width: 10),
                                quickActions[i],
                              ],
                            ],
                          ),
                        )
                      else
                        Wrap(spacing: 10, runSpacing: 10, children: quickActions),
                      SizedBox(height: phone ? 20 : 26),
                      SplitSummaryCard(
                        name: firstName,
                        payable: payable,
                        receivable: receivable,
                        currency: currency,
                        groupCount: groups.length,
                        onGuide: _openGuide,
                      ),
                      SizedBox(height: phone ? 22 : 30),
                      SectionTitle(
                        'Nhóm đang hoạt động',
                        trailing: TextButton(
                          onPressed: () => _selectTab(1),
                          child: Text(groups.isEmpty ? 'Tạo nhóm' : 'Xem tất cả (${groups.length})'),
                        ),
                      ),
                      const SizedBox(height: 4),
                      groupsBody,
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _groups(List<Map<String, dynamic>> groups) {
    final filtered = groups
        .where((g) => g['name'].toString().toLowerCase().contains(query.toLowerCase()))
        .toList();
    return RefreshIndicator(
      onRefresh: refresh,
      child: ListView(
        key: const ValueKey('groups-reference'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 34),
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Tìm nhóm',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                  onChanged: (value) => setState(() => query = value),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filledTonal(
                tooltip: 'Tham gia bằng mã',
                onPressed: join,
                icon: const Icon(Icons.login_rounded),
              ),
            ],
          ),
          SectionTitle(
            '${groups.length} Groups',
            trailing: TextButton.icon(
              onPressed: create,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Tạo nhóm'),
            ),
          ),
          if (groups.isEmpty)
            EmptyState(
              title: 'Chưa có nhóm',
              description: 'Tạo nhóm hoặc nhập mã mời do trưởng nhóm chia sẻ.',
              action: FilledButton(onPressed: create, child: const Text('Tạo nhóm')),
            )
          else if (filtered.isEmpty)
            const EmptyState(
              title: 'Không tìm thấy nhóm',
              description: 'Thử tên nhóm khác.',
              icon: Icons.search_off_rounded,
            )
          else
            ...filtered.asMap().entries.map((entry) {
              final i = entry.key;
              final g = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ReferenceGroupCard(
                  name: g['name'].toString(),
                  memberCount: asInt(g['memberCount']),
                  balance: asInt(g['balance']),
                  currency: g['currency']?.toString() ?? 'VND',
                  pending: asInt(g['pendingOutgoing'] ?? 0) > 0 ||
                      asInt(g['pendingIncoming'] ?? 0) > 0,
                  total: asInt(g['total'] ?? 0),
                  index: i,
                  onTap: () => openGroup(g),
                ),
              );
            }),
          const SizedBox(height: 6),
          OutlinedButton.icon(
            onPressed: join,
            icon: const Icon(Icons.qr_code_2_rounded),
            label: const Text('Tham gia bằng mã nhóm'),
          ),
        ],
      ),
    );
  }

  Widget _loadingOverview() {
    const sections = ['Tổng quan', 'Nhóm', 'Thanh toán', 'Thống kê'];
    Widget skeleton(double width, double height, {double radius = 12}) => Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: AppColors.surfaceHigh.withValues(alpha: .72),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: AppColors.glassBorder),
          ),
        );

    return Column(
      children: [
        LuminousBrandHeader(section: sections[tab]),
        Expanded(
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 34),
            children: [
              Surface(
                interactive: false,
                padding: const EdgeInsets.fromLTRB(20, 30, 20, 30),
                child: Column(
                  children: [
                    skeleton(160, 14),
                    const SizedBox(height: 22),
                    skeleton(220, 42, radius: 14),
                    const SizedBox(height: 22),
                    skeleton(132, 34, radius: 999),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: skeleton(double.infinity, 86, radius: 16)),
                  const SizedBox(width: 16),
                  Expanded(child: skeleton(double.infinity, 86, radius: 16)),
                ],
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  skeleton(120, 18),
                  const Spacer(),
                  skeleton(62, 16),
                ],
              ),
              const SizedBox(height: 14),
              skeleton(double.infinity, 144, radius: 16),
              const SizedBox(height: 12),
              skeleton(double.infinity, 144, radius: 16),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        body: PremiumBackground(
          child: SafeArea(
            child: FutureBuilder<Map<String, dynamic>>(
              future: future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return _loadingOverview();
                }
                if (snapshot.hasError) {
                  return Center(
                    child: EmptyState(
                      title: 'Không thể tải dữ liệu',
                      description: snapshot.error.toString(),
                      icon: Icons.cloud_off_rounded,
                      action: FilledButton(onPressed: refresh, child: const Text('Thử lại')),
                    ),
                  );
                }
                final data = snapshot.data!;
                final me = Map<String, dynamic>.from(data['me'] as Map);
                final groups = maps(data['groups']);
                Widget view;
                switch (tab) {
                  case 0:
                    view = _dashboard(data, me, groups);
                    break;
                  case 1:
                    view = _groups(groups);
                    break;
                  case 2:
                    view = DebtsReferenceView(
                      groups: groups,
                      onOpenGroup: openGroup,
                      onOpenHistory: _openHistory,
                      onRefresh: refresh,
                    );
                    break;
                  case 3:
                    view = StatsReferenceView(groups: groups, onRefresh: refresh);
                    break;
                  default:
                    view = _dashboard(data, me, groups);
                    break;
                }
                return Column(
                  children: [
                    _header(data, me),
                    Expanded(child: _tabTransition(view)),
                  ],
                );
              },
            ),
          ),
        ),
        bottomNavigationBar: LuminousExtendedBottomNav(
          selectedIndex: switch (tab) { 0 => 0, 1 => 1, 2 => 2, _ => 4 },
          onSelected: (value) => _selectExtendedNav(value),
          onAdd: create,
        ),
      );
}


class _DashboardActionChip extends StatelessWidget {
  const _DashboardActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
            decoration: BoxDecoration(
              color: AppColors.surfaceHigh.withValues(alpha: .82),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: color.withValues(alpha: .15)),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: .07),
                  blurRadius: 16,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Geist',
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class ActivityView extends StatefulWidget {
  final void Function(Map<String, dynamic>) onOpen;
  const ActivityView({super.key, required this.onOpen});
  @override State<ActivityView> createState() => _ActivityViewState();
}

class _ActivityViewState extends State<ActivityView> {
  late Future<void> initial;
  final items = <Map<String, dynamic>>[];
  int? nextOffset;
  bool loadingMore = false;
  String filter = 'ALL';

  @override void initState() { super.initState(); initial = loadFirst(); }

  Future<void> loadFirst() async {
    final page = Map<String, dynamic>.from(await Api.call('/activity?limit=30&offset=0') as Map);
    items..clear()..addAll(maps(page['items']));
    nextOffset = page['nextOffset'] == null ? null : asInt(page['nextOffset']);
  }

  Future<void> refresh() async {
    final task = loadFirst();
    setState(() { initial = task; });
    try { await task; } catch (_) {}
  }

  Future<void> more() async {
    if (loadingMore || nextOffset == null) return;
    setState(() => loadingMore = true);
    try {
      final page = Map<String, dynamic>.from(await Api.call('/activity?limit=30&offset=$nextOffset') as Map);
      if (!mounted) return;
      setState(() {
        final known = items.map((e) => '${e['kind']}:${e['id']}').toSet();
        items.addAll(maps(page['items']).where((e) => known.add('${e['kind']}:${e['id']}')));
        nextOffset = page['nextOffset'] == null ? null : asInt(page['nextOffset']);
      });
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => loadingMore = false);
    }
  }

  bool _matches(Map<String, dynamic> item) {
    if (filter == 'ALL') return true;
    final kind = (item['kind'] ?? '').toString().toLowerCase();
    final me = Session.userId ?? -1;
    if (filter == 'EXPENSE') return kind != 'settlement';
    if (filter == 'PAYMENT') return kind == 'settlement' && asInt(item['debtorId'] ?? -1) == me;
    if (filter == 'RECEIVE') return kind == 'settlement' && asInt(item['creditorId'] ?? -1) == me;
    return true;
  }

  String _settlementStatus(String status) => switch (status.toUpperCase()) {
    'PAID' => 'Chờ người nhận xác nhận',
    'CONFIRMED' => 'Đã hoàn thành',
    'CANCELLED' => 'Đã hủy',
    'PENDING' => 'Chờ thanh toán',
    _ => status,
  };

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
    future: initial,
    builder: (context, snapshot) => RefreshIndicator(
      onRefresh: loadingMore ? () async {} : refresh,
      child: ListView(
        padding: const EdgeInsets.all(24),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Row(
            children: [
              const SplitDebtBrandMark(size: 34),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SplitDebt', style: Theme.of(context).textTheme.titleMedium),
                    Text('LỊCH SỬ HOẠT ĐỘNG', style: Theme.of(context).textTheme.labelMedium),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceHigh.withValues(alpha: .72),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: const Icon(Icons.history_rounded, size: 17, color: AppColors.tertiary),
              ),
            ],
          ),
          const SizedBox(height: 26),
          Text('Lịch sử', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          const Text('Theo dõi chi tiêu, tiền bạn đã trả và tiền bạn đã nhận theo thời gian.'),
          const SizedBox(height: 18),
          PillSegment<String>(
            items: const [
              ('ALL', 'Tất cả'),
              ('EXPENSE', 'Chi tiêu'),
              ('PAYMENT', 'Thanh toán'),
              ('RECEIVE', 'Nhận tiền'),
            ],
            value: filter,
            onChanged: (value) => setState(() => filter = value),
          ),
          const SizedBox(height: 24),
          if (snapshot.connectionState != ConnectionState.done) const Center(child: CircularProgressIndicator())
          else if (snapshot.hasError) EmptyState(
            title: 'Không thể tải lịch sử', description: snapshot.error.toString(),
            action: FilledButton(onPressed: refresh, child: const Text('Thử lại')),
          ) else ...[
            if (items.where(_matches).isEmpty) const EmptyState(title: 'Chưa có hoạt động phù hợp', description: 'Thử chọn bộ lọc khác hoặc tạo khoản chi mới.', icon: Icons.receipt_long_rounded),
            ...items.where(_matches).map((e) {
              final isSettlement = e['kind'] == 'settlement';
              final me = Session.userId ?? -1;
              final debtorId = asInt(e['debtorId'] ?? -1);
              final creditorId = asInt(e['creditorId'] ?? -1);
              final isPayment = isSettlement && debtorId == me;
              final isReceive = isSettlement && creditorId == me;
              final currency = e['currency'].toString();
              final amount = asInt(e['amount']);
              final title = isSettlement
                  ? isPayment
                      ? 'Thanh toán · Tôi trả ${money(amount, currency)}'
                      : isReceive
                          ? 'Nhận tiền · Tôi thu về ${money(amount, currency)}'
                          : 'Quyết toán trong nhóm'
                  : 'Chi tiêu · ${e['title']}';
              final subtitle = isSettlement
                  ? 'Nhóm: ${e['groupName']}\n${e['debtorName'] ?? 'Thành viên'} → ${e['creditorName'] ?? 'Thành viên'} · ${_settlementStatus((e['status'] ?? '').toString())}\n${dateLabel(e['createdAt']?.toString())}'
                  : 'Nhóm: ${e['groupName']}\nKhoản chi: ${e['title']} · Người trả: ${e['payerName']}\n${dateLabel(e['createdAt']?.toString())}';
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Surface(
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Icon(
                      isPayment ? Icons.north_east_rounded : isReceive ? Icons.south_west_rounded : isSettlement ? Icons.payments_outlined : Icons.receipt_long_rounded,
                      color: isPayment ? Theme.of(context).colorScheme.error : isReceive ? AppColors.success : Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text(subtitle),
                    isThreeLine: true,
                    trailing: isSettlement
                        ? StatusPill(
                            label: (e['status'] ?? '') == 'CONFIRMED' ? 'Xong' : (e['status'] ?? '') == 'PAID' ? 'Chờ xác nhận' : 'Chi tiết',
                            kind: (e['status'] ?? '') == 'CONFIRMED' ? FeedbackKind.success : (e['status'] ?? '') == 'PAID' ? FeedbackKind.warning : FeedbackKind.info,
                          )
                        : Text(money(amount, currency), style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary)),
                    onTap: () => widget.onOpen({'id': e['groupId']}),
                  ),
                ),
              );
            }),
            if (nextOffset != null) BusyButton(busy: loadingMore, label: 'Tải thêm', onPressed: more),
          ],
        ],
      ),
    ),
  );
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<List<Map<String, dynamic>>> future;

  @override
  void initState() {
    super.initState();
    future = load();
  }

  Future<List<Map<String, dynamic>>> load() async => maps(await Api.call('/notifications'));

  FeedbackKind _kind(Map<String, dynamic> n) {
    final type = (n['type'] ?? '').toString().toUpperCase();
    if (type.contains('CONFIRM') || type.contains('SUCCESS') || type.contains('PAID')) {
      return FeedbackKind.success;
    }
    if (type.contains('REMIND') || type.contains('DEBT')) return FeedbackKind.warning;
    if (type.contains('ERROR') || type.contains('FAIL')) return FeedbackKind.error;
    return FeedbackKind.info;
  }

  IconData _icon(Map<String, dynamic> n) {
    final type = (n['type'] ?? '').toString().toUpperCase();
    if (type.contains('EXPENSE')) return Icons.receipt_long_rounded;
    if (type.contains('SETTLEMENT') || type.contains('PAY')) return Icons.payments_rounded;
    if (type.contains('MEMBER') || type.contains('JOIN')) return Icons.person_add_alt_1_rounded;
    if (type.contains('DEBT') || type.contains('REMIND')) return Icons.notifications_active_rounded;
    return Icons.notifications_rounded;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.transparent,
        body: PremiumBackground(
          child: SafeArea(
            child: Column(
              children: [
                LuminousBrandHeader(
                  section: 'Notifications',
                  trailing: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ),
                Expanded(
                  child: FutureBuilder<List<Map<String, dynamic>>>(
            future: future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return EmptyState(
                  title: 'Không thể tải thông báo',
                  description: snapshot.error.toString(),
                );
              }
              final items = snapshot.data!;
              if (items.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset('assets/reference/notification-bell-3d.png', width: 116, height: 116, fit: BoxFit.cover),
                        const SizedBox(height: 14),
                        Text('Chưa có thông báo', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 6),
                        Text('Các sự kiện quan trọng sẽ xuất hiện tại đây.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(18),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final n = items[i];
                  final kind = _kind(n);
                  return Surface(
                    padding: const EdgeInsets.all(15),
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: .08),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Icon(_icon(n), color: Theme.of(context).colorScheme.primary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        n['title'].toString(),
                                        style: TextStyle(
                                          fontWeight: n['isRead'] == true ? FontWeight.w600 : FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    StatusPill(
                                      label: n['isRead'] == true ? 'Đã đọc' : 'Mới',
                                      kind: n['isRead'] == true ? FeedbackKind.info : kind,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(n['content'].toString()),
                                const SizedBox(height: 7),
                                Text(
                                  dateLabel(n['createdAt']?.toString()),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                  );
                },
              );
            },
          ),
                ),
              ],
            ),
          ),
        ),
      );
}
