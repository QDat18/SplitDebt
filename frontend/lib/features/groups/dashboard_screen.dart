import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_typography.dart';
import '../expenses/expense_detail_screen.dart';
import '../../core/network/dio_client.dart';
import '../auth/data/auth_repository.dart';

/// ----------------------------------------------------------------------------
/// MÀN HÌNH DASHBOARD TRANG CHỦ (MAIN DASHBOARD SCREEN)
/// Hiển thị tổng quan nợ ròng, nhóm chi tiêu & khoản chi gần đây
/// ----------------------------------------------------------------------------
class DashboardScreen extends ConsumerStatefulWidget {
  final VoidCallback onNavigateToCreateExpense;
  final VoidCallback onNavigateToSettlement;

  const DashboardScreen({
    super.key,
    required this.onNavigateToCreateExpense,
    required this.onNavigateToSettlement,
  });

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  int _unreadNotificationCount = 0;
  final currencyFormatter =
      NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );

    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: AppColors.n50,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.s20, vertical: AppDimensions.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- 1. USER HEADER ---
                _buildUserHeader(),
                const SizedBox(height: AppDimensions.s20),

                // --- 2. SUMMARY BALANCE CARD ---
                _buildNetBalanceOverviewCard(),
                const SizedBox(height: AppDimensions.s20),

                // --- 3. QUICK ACTION BUTTONS ---
                _buildQuickActionsRow(),
                const SizedBox(height: AppDimensions.s24),

                // --- 4. CURRENT ACTIVE GROUPS ---
                _buildActiveGroupsSection(),
                const SizedBox(height: AppDimensions.s24),

                // --- 5. RECENT EXPENSES LIST ---
                _buildRecentExpensesSection(context),
                const SizedBox(height: AppDimensions.s32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- USER HEADER ---
  Widget _buildUserHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.cardGradient,
              ),
              child: const CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.p600,
                child: Icon(Icons.person, color: Colors.white, size: 24),
              ),
            ),
            const SizedBox(width: AppDimensions.s12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Xin chào, Đạt!',
                    style: AppTypography.title.copyWith(fontSize: 18)),
                Text('Team IUMAITRUONG', style: AppTypography.caption),
              ],
            ),
          ],
        ),

        // Notification Bell Icon (Interactive FCM Notification Center)
        InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            _showNotificationSheet(context);
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.n0,
              shape: BoxShape.circle,
              boxShadow: AppDimensions.shadowSm,
            ),
            child: Stack(
              children: [
                const Icon(Icons.notifications_outlined,
                    color: AppColors.n800, size: 22),
                if (_unreadNotificationCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- SUMMARY BALANCE CARD ---
  Widget _buildNetBalanceOverviewCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.s20),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: AppDimensions.radius24,
        boxShadow: AppDimensions.shadowMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('TỔNG SỐ DƯ RÒNG KHOẢN CHI',
                  style: AppTypography.caption.copyWith(
                      color: Colors.white.withOpacity(0.8),
                      letterSpacing: 1.0,
                      fontWeight: FontWeight.w700)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.success,
                  borderRadius: AppDimensions.radius8,
                ),
                child: Text('CẦN NHẬN LẠI TIỀN',
                    style: AppTypography.caption.copyWith(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '+340.000 ₫',
            style: AppTypography.display.copyWith(
                color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: AppDimensions.s16),
          const Divider(height: 1, color: Colors.white24),
          const SizedBox(height: AppDimensions.s12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.arrow_upward_rounded,
                      color: AppColors.successTint, size: 16),
                  const SizedBox(width: 4),
                  Text('Bạn đã ứng: 680.000 ₫',
                      style: AppTypography.caption
                          .copyWith(color: Colors.white.withOpacity(0.9))),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.arrow_downward_rounded,
                      color: AppColors.errorTint, size: 16),
                  const SizedBox(width: 4),
                  Text('Nợ phải gánh: 340.000 ₫',
                      style: AppTypography.caption
                          .copyWith(color: Colors.white.withOpacity(0.9))),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- QUICK ACTION BUTTONS ROW ---
  Widget _buildQuickActionsRow() {
    return Row(
      children: [
        // Action 1: Tạo khoản chi mới
        Expanded(
          child: InkWell(
            onTap: widget.onNavigateToCreateExpense,
            borderRadius: AppDimensions.radius20,
            child: Container(
              padding: const EdgeInsets.all(AppDimensions.s16),
              decoration: BoxDecoration(
                color: AppColors.n0,
                borderRadius: AppDimensions.radius20,
                boxShadow: AppDimensions.shadowSm,
                border: Border.all(color: AppColors.p100),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.p50,
                      borderRadius: AppDimensions.radius12,
                    ),
                    child: const Icon(Icons.add_circle_outline_rounded,
                        color: AppColors.p500, size: 22),
                  ),
                  const SizedBox(width: AppDimensions.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tạo khoản chi',
                            style: AppTypography.title.copyWith(fontSize: 14)),
                        Text('Chia tiền tự động',
                            style:
                                AppTypography.caption.copyWith(fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(width: AppDimensions.s12),

        // Action 2: Quyết toán nợ
        Expanded(
          child: InkWell(
            onTap: widget.onNavigateToSettlement,
            borderRadius: AppDimensions.radius20,
            child: Container(
              padding: const EdgeInsets.all(AppDimensions.s16),
              decoration: BoxDecoration(
                color: AppColors.n0,
                borderRadius: AppDimensions.radius20,
                boxShadow: AppDimensions.shadowSm,
                border: Border.all(color: AppColors.p100),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.warningTint,
                      borderRadius: AppDimensions.radius12,
                    ),
                    child: const Icon(Icons.auto_awesome_rounded,
                        color: AppColors.warning, size: 22),
                  ),
                  const SizedBox(width: AppDimensions.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Quyết toán',
                            style: AppTypography.title.copyWith(fontSize: 14)),
                        Text('Min-Cash-Flow',
                            style:
                                AppTypography.caption.copyWith(fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- ACTIVE GROUPS SECTION ---
  Widget _buildActiveGroupsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Nhóm chi tiêu (1)',
                style: AppTypography.label.copyWith(fontSize: 15)),
            TextButton(
              onPressed: () {},
              child: Text('Tất cả',
                  style: AppTypography.label
                      .copyWith(color: AppColors.p600, fontSize: 13)),
            ),
          ],
        ),

        // Group Card
        Container(
          padding: const EdgeInsets.all(AppDimensions.s16),
          decoration: BoxDecoration(
            color: AppColors.n0,
            borderRadius: AppDimensions.radius20,
            boxShadow: AppDimensions.shadowSm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.p50,
                      borderRadius: AppDimensions.radius16,
                    ),
                    child: const Icon(Icons.groups_rounded,
                        color: AppColors.p500, size: 24),
                  ),
                  const SizedBox(width: AppDimensions.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Du Lịch Hà Giang',
                            style: AppTypography.title.copyWith(fontSize: 16)),
                        Text('4 thành viên • Tiền tệ VND',
                            style: AppTypography.caption),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: AppColors.successTint,
                        borderRadius: AppDimensions.radius8),
                    child: Text('Đang hoạt động',
                        style: AppTypography.caption.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.s16),
              const Divider(height: 1, color: AppColors.n100),
              const SizedBox(height: AppDimensions.s12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Tổng chi tiêu nhóm:', style: AppTypography.caption),
                  Text('2.450.000 ₫',
                      style: AppTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.w800, color: AppColors.p600)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- RECENT EXPENSES SECTION ---
  Widget _buildRecentExpensesSection(BuildContext context) {
    final recentExpenses = [
      {
        'title': 'Ăn lẩu nướng Gogi House',
        'category': 'Ăn uống',
        'icon': Icons.restaurant_rounded,
        'color': const Color(0xFFFF7675),
        'amount': 680000.0,
        'payer': 'Đạt (Tôi)',
        'time': '3 giờ trước',
      },
      {
        'title': 'Vé xe giường nằm Hà Giang',
        'category': 'Di chuyển',
        'icon': Icons.directions_bus_rounded,
        'color': const Color(0xFF74B9FF),
        'amount': 1200000.0,
        'payer': 'Hoàng (Dev 1)',
        'time': 'Hôm qua',
      },
      {
        'title': 'Cà phê Highland view núi',
        'category': 'Giải trí',
        'icon': Icons.local_cafe_rounded,
        'color': const Color(0xFFFD79A8),
        'amount': 240000.0,
        'payer': 'Minh (Dev 3)',
        'time': '2 ngày trước',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Khoản chi gần đây',
                style: AppTypography.label.copyWith(fontSize: 15)),
            TextButton(
              onPressed: () {},
              child: Text('Xem lịch sử',
                  style: AppTypography.label
                      .copyWith(color: AppColors.p600, fontSize: 13)),
            ),
          ],
        ),
        ...recentExpenses.map((exp) {
          final color = exp['color'] as Color;
          final icon = exp['icon'] as IconData;

          return Container(
            margin: const EdgeInsets.only(bottom: AppDimensions.s12),
            decoration: BoxDecoration(
              color: AppColors.n0,
              borderRadius: AppDimensions.radius20,
              boxShadow: AppDimensions.shadowSm,
            ),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              leading: CircleAvatar(
                backgroundColor: color.withOpacity(0.15),
                child: Icon(icon, color: color, size: 20),
              ),
              title: Text(exp['title'] as String,
                  style: AppTypography.bodyMedium
                      .copyWith(fontWeight: FontWeight.w700)),
              subtitle: Text('${exp['payer']} • ${exp['time']}',
                  style: AppTypography.caption),
              trailing: Text(
                currencyFormatter.format(exp['amount']),
                style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w800, color: AppColors.n900),
              ),
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ExpenseDetailScreen()),
                );
              },
            ),
          );
        }),
      ],
    );
  }

  // --- MODAL THÔNG BÁO PUSH REAL-TIME FCM (BE4-SET-02 & FE4-PAY-01) ---
  Future<void> _showNotificationSheet(BuildContext context) async {
    final future = _loadNotifications();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.65,
          child: FutureBuilder<List<Map<String, dynamic>>>(
              future: future,
              builder: (context, snapshot) {
                if (snapshot.hasError)
                  return Center(
                      child:
                          Text('Không tải được thông báo: ${snapshot.error}'));
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                final notifications = snapshot.data!;
                if (notifications.isEmpty)
                  return const Center(child: Text('Chưa có thông báo.'));
                return ListView(children: [
                  const ListTile(title: Text('Thông báo')),
                  for (final item in notifications)
                    ListTile(
                      leading: const Icon(Icons.notifications_outlined),
                      title: Text(item['title']?.toString() ?? ''),
                      subtitle: Text(item['content']?.toString() ?? ''),
                      onTap: () {
                        Navigator.pop(context);
                        widget.onNavigateToSettlement();
                      },
                    ),
                ]);
              })),
    );
  }

  Future<List<Map<String, dynamic>>> _loadNotifications() async {
    final userId = await AuthRepository().getCurrentUserId();
    final response = await dioClient
        .get('/notifications', queryParameters: {'userId': userId});
    return (response.data['data'] as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }
}
