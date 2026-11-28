// Trách nhiệm file: Màn hình Trang chủ theo mẫu Midnight Navy Hero + thẻ nổi tổng quan công nợ + nút hành động Royal Blue / Navy + nhóm hoạt động & giao dịch gần đây.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/api/api_client.dart';
import '../../core/network/dio_client.dart';
import '../../core/state/app_sync.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/pdf_components.dart';
import '../../core/widgets/fintech_components.dart';
import '../../core/widgets/motion_kit.dart';
import '../../core/widgets/premium_shell.dart';
import '../expenses/pdf_expense_detail.dart';
import '../home/pdf_overview_screen.dart';
import '../notifications/notification_screen.dart';
import 'models/group_model.dart';
import 'providers/group_provider.dart';
import 'screens/group_detail_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  final VoidCallback onNavigateToCreateExpense;
  final VoidCallback onNavigateToSettlement;
  final VoidCallback? onNavigateToGroups;

  const DashboardScreen({
    super.key,
    required this.onNavigateToCreateExpense,
    required this.onNavigateToSettlement,
    this.onNavigateToGroups,
  });

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _money = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  String _fullName = '';
  List<Map<String, dynamic>> _recentExpenses = [];
  String? _loadedGroupsKey;
  bool _loadingRecent = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    appDataSyncSignal.addListener(_onSync);
  }

  @override
  void dispose() {
    appDataSyncSignal.removeListener(_onSync);
    super.dispose();
  }

  void _onSync() {
    if (!mounted) return;
    _loadedGroupsKey = null;
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final raw = await ApiClient.get('/users/me');
      if (!mounted || raw is! Map) return;
      final name = raw['fullName']?.toString().trim();
      if (name != null && name.isNotEmpty) {
        setState(() => _fullName = name);
      }
    } catch (_) {}
  }

  Future<void> _loadRecentExpenses(List<GroupModel> groups) async {
    if (_loadingRecent || groups.isEmpty) return;
    final topGroups = groups.take(3).toList();
    final key = topGroups.map((g) => g.id).join(',');
    if (key == _loadedGroupsKey) return;
    _loadedGroupsKey = key;
    _loadingRecent = true;

    try {
      final responses = await Future.wait(
        topGroups.map(
          (g) => dioClient
              .get('/v1/expenses/group/${g.id}')
              .then(
                (res) => (res.data['data'] as List? ?? [])
                    .whereType<Map>()
                    .map(
                      (e) => {
                        ...Map<String, dynamic>.from(e),
                        '_groupName': g.name,
                      },
                    )
                    .toList(),
              )
              .catchError((_) => <Map<String, dynamic>>[]),
        ),
      );
      if (!mounted) return;
      final combined = responses.expand((list) => list).toList()
        ..sort((a, b) {
          final da = (a['expenseDate'] ?? a['createdAt'] ?? '').toString();
          final db = (b['expenseDate'] ?? b['createdAt'] ?? '').toString();
          return db.compareTo(da);
        });
      setState(() => _recentExpenses = combined.take(5).toList());
    } finally {
      _loadingRecent = false;
    }
  }

  Future<void> _refresh() async {
    _loadedGroupsKey = null;
    await Future.wait([
      ref.read(userGroupsProvider.notifier).fetchGroups(),
      _loadProfile(),
    ]);
  }

  String _greetingByHour(BuildContext context) {
    final hour = DateTime.now().hour;
    if (hour < 12) return tr(context, 'Chào buổi sáng', 'Good morning');
    if (hour < 18) return tr(context, 'Chào buổi chiều', 'Good afternoon');
    return tr(context, 'Chào buổi tối', 'Good evening');
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final groupsState = ref.watch(userGroupsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: PremiumBackground(
        child: RefreshIndicator(
          color: Theme.of(context).colorScheme.primary,
          onRefresh: _refresh,
          child: groupsState.when(
            loading: () => _loadingSkeleton(),
            error: (error, _) => ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 80, 16, 96),
              children: [
                AppErrorState(
                  title: tr(
                    context,
                    'Không tải được dữ liệu',
                    'Could not load data',
                  ),
                  message: error.toString().replaceFirst('Exception: ', ''),
                  onRetry: _refresh,
                ),
              ],
            ),
            data: (groups) {
              if (groups.isNotEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) _loadRecentExpenses(groups);
                });
              }
              return _content(groups);
            },
          ),
        ),
      ),
    );
  }

  Widget _loadingSkeleton() {
    final safeTop = MediaQuery.paddingOf(context).top;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16, safeTop + 16, 16, 96),
      children: const [
        ShimmerBox(width: double.infinity, height: 180, radius: 20),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ShimmerBox(width: double.infinity, height: 48, radius: 12),
            ),
            SizedBox(width: 10),
            Expanded(
              child: ShimmerBox(width: double.infinity, height: 48, radius: 12),
            ),
          ],
        ),
        SizedBox(height: 24),
        ShimmerBox(width: double.infinity, height: 190, radius: 16),
      ],
    );
  }

  Widget _content(List<GroupModel> groups) {
    final scheme = Theme.of(context).colorScheme;
    final receivable = groups
        .where((g) => (g.userBalance ?? 0) > 0)
        .fold<double>(0, (sum, g) => sum + (g.userBalance ?? 0));
    final payable = groups
        .where((g) => (g.userBalance ?? 0) < 0)
        .fold<double>(0, (sum, g) => sum + (g.userBalance ?? 0).abs());
    final net = receivable - payable;
    final displayName = _fullName.isEmpty
        ? tr(context, 'bạn', 'there')
        : _fullName.split(RegExp(r'\s+')).last;
    final visibleGroups = groups.take(4).toList();

    final statusText = net > 0
        ? tr(context, 'Đang được nhận', 'You are owed')
        : net < 0
        ? tr(context, 'Cần thanh toán', 'You owe')
        : tr(context, 'Đã cân bằng', 'All settled');
    final statusColor = net > 0
        ? AppColors.successOnDark
        : net < 0
        ? AppColors.errorOnDark
        : Colors.white.withValues(alpha: 0.78);

    return ListView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        NavyHeroHeader(
          headerContent: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _greetingByHour(context),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          tr(
                            context,
                            'Xin chào, $displayName',
                            'Welcome, $displayName',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: tr(context, 'Thống kê', 'Analytics'),
                    onPressed: () => Navigator.of(
                      context,
                    ).push(fintechRoute(const OverviewScreen(history: false))),
                    icon: const Icon(
                      CupertinoIcons.chart_bar,
                      color: Colors.white,
                    ),
                  ),
                  IconTheme(
                    data: const IconThemeData(color: Colors.white),
                    child: const NotificationBell(),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.s16),
              AnimatedMoneyText(
                amount: net,
                showSign: true,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.9,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    tr(context, 'Tổng số dư công nợ', 'Net balance'),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.68),
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          floatingCard: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppDimensions.maxContentWidth,
              ),
              child: PremiumSurface(
                elevated: true,
                padding: const EdgeInsets.all(AppDimensions.s16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _floatingMetric(
                            label: tr(context, 'Được nhận', 'To receive'),
                            amount: receivable,
                            color: AppColors.successFor(context),
                            icon: CupertinoIcons.arrow_down_left,
                          ),
                        ),
                        Container(
                          width: 0.8,
                          height: 36,
                          color: AppColors.hairlineFor(context),
                        ),
                        const SizedBox(width: AppDimensions.s16),
                        Expanded(
                          child: _floatingMetric(
                            label: tr(context, 'Cần trả', 'To pay'),
                            amount: payable,
                            color: AppColors.errorFor(context),
                            icon: CupertinoIcons.arrow_up_right,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.s16),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: widget.onNavigateToCreateExpense,
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: Text(tr(context, 'Thêm chi', 'Add expense')),
                          ),
                        ),
                        const SizedBox(width: AppDimensions.s12),
                        Expanded(
                          child: NavyActionButton(
                            icon: CupertinoIcons.arrow_2_squarepath,
                            label: tr(context, 'Thanh toán', 'Settle up'),
                            onPressed: widget.onNavigateToSettlement,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.s20),
        Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppDimensions.maxContentWidth,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.s16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SectionLabel(
                    title: tr(context, 'Nhóm hoạt động', 'Active groups'),
                    actionLabel: groups.isNotEmpty
                        ? tr(context, 'Xem tất cả', 'See all')
                        : null,
                    onAction: widget.onNavigateToGroups,
                  ),
                  const SizedBox(height: AppDimensions.s8),
                  if (visibleGroups.isEmpty)
                    AppEmptyState(
                      icon: CupertinoIcons.person_2,
                      title: tr(
                        context,
                        'Chưa có nhóm chi tiêu',
                        'No expense groups yet',
                      ),
                      message: tr(
                        context,
                        'Tạo nhóm mới ở mục Nhóm để bắt đầu ghi nhận và chia sẻ chi phí.',
                        'Create a group in the Groups tab to start splitting expenses.',
                      ),
                      actionLabel: widget.onNavigateToGroups != null
                          ? tr(context, 'Đi tới Nhóm', 'Go to Groups')
                          : null,
                      onAction: widget.onNavigateToGroups,
                    )
                  else
                    PremiumSurface(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          for (int i = 0; i < visibleGroups.length; i++) ...[
                            _groupRow(visibleGroups[i], scheme),
                            if (i < visibleGroups.length - 1)
                              const Divider(height: 1, indent: 64),
                          ],
                        ],
                      ),
                    ),
                  if (_recentExpenses.isNotEmpty) ...[
                    const SizedBox(height: AppDimensions.s24),
                    SectionLabel(
                      title: tr(
                        context,
                        'Giao dịch gần đây',
                        'Recent activity',
                      ),
                    ),
                    const SizedBox(height: AppDimensions.s8),
                    PremiumSurface(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          for (int i = 0; i < _recentExpenses.length; i++) ...[
                            _recentExpenseRow(_recentExpenses[i], scheme),
                            if (i < _recentExpenses.length - 1)
                              const Divider(height: 1, indent: 64),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _floatingMetric({
    required String label,
    required double amount,
    required Color color,
    required IconData icon,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        AnimatedMoneyText(
          amount: amount,
          style: TextStyle(
            color: scheme.onSurface,
            fontSize: 16.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _groupRow(GroupModel group, ColorScheme scheme) {
    final balance = group.userBalance ?? 0;
    final isPositive = balance > 0;
    final isNegative = balance < 0;
    final amountColor = isPositive
        ? AppColors.successFor(context)
        : isNegative
        ? AppColors.errorFor(context)
        : scheme.onSurfaceVariant;
    final amountText = isPositive
        ? '+${_money.format(balance)}'
        : isNegative
        ? '-${_money.format(balance.abs())}'
        : tr(context, 'Cân bằng', 'Settled');

    return InkWell(
      onTap: () => Navigator.of(
        context,
      ).push(fintechRoute(GroupDetailScreen(group: group))),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            GroupAvatar(name: group.name, size: 40, radius: 11),
            const SizedBox(width: AppDimensions.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tr(
                      context,
                      '${group.memberCount} thành viên',
                      '${group.memberCount} members',
                    ),
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppDimensions.s8),
            Text(
              amountText,
              style: TextStyle(
                color: amountColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              CupertinoIcons.chevron_forward,
              size: 15,
              color: scheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _recentExpenseRow(Map<String, dynamic> expense, ColorScheme scheme) {
    final title = expense['title']?.toString() ?? '';
    final payer = expense['payerName']?.toString() ?? '';
    final groupName = expense['_groupName']?.toString() ?? '';
    final date = expense['expenseDate']?.toString() ?? '';
    final amount = (expense['totalAmount'] as num?) ?? 0;

    return InkWell(
      onTap: () => Navigator.of(
        context,
      ).push(fintechRoute(ExpenseReadScreen(expense: expense))),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            ExpenseIconBadge(
              title: title,
              categoryName: expense['categoryName']?.toString(),
              size: 38,
            ),
            const SizedBox(width: AppDimensions.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14.5,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (payer.isNotEmpty) payer,
                      if (groupName.isNotEmpty) groupName,
                      if (date.isNotEmpty) date,
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppDimensions.s8),
            Text(
              money(amount),
              style: TextStyle(
                color: scheme.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
