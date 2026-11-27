// Trách nhiệm file: Màn hình Trang chủ chuẩn iOS Apple Wallet (thẻ Số dư ròng matte charcoal, nhóm hoạt động Inset Grouped, đồng bộ realtime).

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/api/api_client.dart';
import '../../core/state/app_sync.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/motion_kit.dart';
import '../../core/widgets/premium_shell.dart';
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

  String _fullName = 'Bạn';

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
    if (mounted) _loadProfile();
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

  Future<void> _refresh() async {
    await Future.wait([
      ref.read(userGroupsProvider.notifier).fetchGroups(),
      _loadProfile(),
    ]);
  }

  String _greetingByHour() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Chào buổi sáng';
    if (hour < 18) return 'Chào buổi chiều';
    return 'Chào buổi tối';
  }

  String _groupEmoji(GroupModel group) {
    final existing = group.categoryIcon?.trim() ?? '';
    if (existing.isNotEmpty && existing != '👥') return existing;
    final nameLower = group.name.toLowerCase();
    if (nameLower.contains('trip') ||
        nameLower.contains('du lịch') ||
        nameLower.contains('đà lạt') ||
        nameLower.contains('hải phòng')) {
      return '🌴';
    }
    if (nameLower.contains('project') ||
        nameLower.contains('team') ||
        nameLower.contains('lập trình')) {
      return '💻';
    }
    if (nameLower.contains('trọ') ||
        nameLower.contains('phòng') ||
        nameLower.contains('nhà')) {
      return '🏠';
    }
    if (nameLower.contains('ăn') ||
        nameLower.contains('uống') ||
        nameLower.contains('cơm') ||
        nameLower.contains('nhậu')) {
      return '🍜';
    }
    return '👥';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final groupsState = ref.watch(userGroupsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: PremiumBackground(
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            color: AppColors.p500,
            onRefresh: _refresh,
            child: groupsState.when(
              loading: () => _loadingSkeleton(),
              error: (error, _) => ListView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(16, 100, 16, 100),
                children: [
                  PremiumSurface(
                    child: Column(
                      children: [
                        const Icon(
                          CupertinoIcons.wifi_slash,
                          color: AppColors.error,
                          size: 36,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Không tải được dữ liệu',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          error.toString().replaceFirst('Exception: ', ''),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.n500,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _refresh,
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              data: (groups) => _content(groups),
            ),
          ),
        ),
      ),
    );
  }

  Widget _loadingSkeleton() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
      children: const [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(width: 90, height: 13, radius: 5),
                SizedBox(height: 6),
                ShimmerBox(width: 170, height: 28, radius: 7),
              ],
            ),
            ShimmerBox(width: 38, height: 38, radius: 19),
          ],
        ),
        SizedBox(height: 18),
        ShimmerBox(width: double.infinity, height: 176, radius: 18),
        SizedBox(height: 14),
        Row(
          children: [
            Expanded(
                child:
                    ShimmerBox(width: double.infinity, height: 74, radius: 14)),
            SizedBox(width: 10),
            Expanded(
                child:
                    ShimmerBox(width: double.infinity, height: 74, radius: 14)),
            SizedBox(width: 10),
            Expanded(
                child:
                    ShimmerBox(width: double.infinity, height: 74, radius: 14)),
          ],
        ),
        SizedBox(height: 24),
        ShimmerBox(width: double.infinity, height: 190, radius: 14),
      ],
    );
  }

  Widget _content(List<GroupModel> groups) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final receivable = groups
        .where((g) => (g.userBalance ?? 0) > 0)
        .fold<double>(0, (sum, g) => sum + (g.userBalance ?? 0));
    final payable = groups
        .where((g) => (g.userBalance ?? 0) < 0)
        .fold<double>(0, (sum, g) => sum + (g.userBalance ?? 0).abs());
    final net = receivable - payable;
    final firstName = _fullName.split(RegExp(r'\s+')).last;
    final visibleGroups = groups.take(5).toList();

    return ListView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      children: [
        StaggeredEntrance(
          index: 0,
          child: PremiumHeader(
            eyebrow: _greetingByHour(),
            title: firstName,
            trailing: const NotificationBell(),
          ),
        ),
        const SizedBox(height: 16),
        StaggeredEntrance(
          index: 1,
          child: _appleWalletBalanceCard(
            net: net,
            receivable: receivable,
            payable: payable,
          ),
        ),
        const SizedBox(height: 14),
        StaggeredEntrance(
          index: 2,
          child: Row(
            children: [
              Expanded(
                child: _iosActionButton(
                  icon: CupertinoIcons.plus_circle_fill,
                  iconColor: AppColors.p500,
                  label: 'Thêm chi',
                  onTap: widget.onNavigateToCreateExpense,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _iosActionButton(
                  icon: CupertinoIcons.arrow_2_squarepath,
                  iconColor: AppColors.success,
                  label: 'Xén nợ',
                  onTap: widget.onNavigateToSettlement,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _iosActionButton(
                  icon: CupertinoIcons.chart_bar_fill,
                  iconColor: AppColors.warning,
                  label: 'Thống kê',
                  onTap: () => Navigator.of(context).push(
                    fintechRoute(const OverviewScreen(history: false)),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        StaggeredEntrance(
          index: 3,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Text(
                  'NHÓM HOẠT ĐỘNG',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                    color: isDark
                        ? const Color(0xFF8E8E93)
                        : const Color(0xFF636366),
                  ),
                ),
                const Spacer(),
                if (groups.isNotEmpty)
                  GestureDetector(
                    onTap: widget.onNavigateToGroups,
                    child: const Text(
                      'Xem tất cả',
                      style: TextStyle(
                        color: AppColors.p500,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (visibleGroups.isEmpty)
          StaggeredEntrance(
            index: 4,
            child: PremiumSurface(
              child: Column(
                children: [
                  const Icon(
                    CupertinoIcons.person_2,
                    size: 34,
                    color: AppColors.n500,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Chưa có nhóm chi tiêu',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Tạo nhóm mới hoặc nhập mã mời ở tab Nhóm để bắt đầu.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: AppColors.n500),
                  ),
                  if (widget.onNavigateToGroups != null) ...[
                    const SizedBox(height: 14),
                    FilledButton(
                      onPressed: widget.onNavigateToGroups,
                      child: const Text('Đi tới Nhóm'),
                    ),
                  ],
                ],
              ),
            ),
          )
        else
          StaggeredEntrance(
            index: 4,
            child: PremiumSurface(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (int i = 0; i < visibleGroups.length; i++) ...[
                    _iosGroupRow(visibleGroups[i]),
                    if (i < visibleGroups.length - 1)
                      const Divider(height: 1, indent: 64),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }

  /// Thẻ số dư ròng phong cách Apple Card (Matte Charcoal #1C1C1E, sắc nét, tối giản).
  Widget _appleWalletBalanceCard({
    required double net,
    required double receivable,
    required double payable,
  }) {
    final statusText = net > 0
        ? 'Đang được nhận lại'
        : net < 0
            ? 'Cần thanh toán'
            : 'Đã cân bằng';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: .08),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Số dư ròng',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .66),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                statusText,
                style: TextStyle(
                  color: net > 0
                      ? AppColors.success
                      : net < 0
                          ? AppColors.error
                          : Colors.white.withValues(alpha: .6),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          AnimatedMoneyText(
            amount: net,
            showSign: true,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            height: 0.6,
            color: Colors.white.withValues(alpha: .12),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Được nhận',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: .62),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    AnimatedMoneyText(
                      amount: receivable,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 0.6,
                height: 32,
                color: Colors.white.withValues(alpha: .12),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Phải trả',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: .62),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    AnimatedMoneyText(
                      amount: payable,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _iosActionButton({
    required IconData icon,
    required Color iconColor,
    required String label,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ScaleTap(
      onTap: onTap,
      child: PremiumSurface(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        radius: 14,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF000000),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iosGroupRow(GroupModel group) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final balance = group.userBalance ?? 0;
    final isPositive = balance > 0;
    final isNegative = balance < 0;
    final amountColor = isPositive
        ? AppColors.success
        : isNegative
            ? AppColors.error
            : AppColors.n500;
    final amountText = isPositive
        ? '+${_money.format(balance)}'
        : isNegative
            ? '-${_money.format(balance.abs())}'
            : 'Cân bằng';

    return ScaleTap(
      onTap: () => Navigator.of(context).push(
        fintechRoute(GroupDetailScreen(group: group)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  _groupEmoji(group),
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            const SizedBox(width: 12),
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
                      color: isDark ? Colors.white : const Color(0xFF000000),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${group.memberCount} thành viên',
                    style: const TextStyle(
                      color: AppColors.n500,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
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
            const Icon(
              CupertinoIcons.chevron_forward,
              size: 16,
              color: AppColors.n400,
            ),
          ],
        ),
      ),
    );
  }
}
