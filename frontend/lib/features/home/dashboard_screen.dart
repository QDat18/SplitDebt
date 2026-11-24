// Trách nhiệm file: Xây dựng màn hình dashboard screen và điều phối tương tác người dùng với trạng thái nghiệp vụ.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_typography.dart';
import '../../core/network/dio_client.dart';
import '../../data/repositories/auth_repository.dart';
import '../groups/models/group_model.dart';
import '../groups/providers/group_provider.dart';
import '../groups/screens/group_detail_screen.dart';

/// ----------------------------------------------------------------------------
/// MÀN HÌNH DASHBOARD TRANG CHỦ (MAIN DASHBOARD SCREEN)
/// Hiển thị tổng quan nợ ròng, nhóm chi tiêu & dữ liệu thực từ CSDL
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

  String _userName = 'Bạn';
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
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final res = await dioClient.get('/users/me');
      if (res.data is Map) {
        final Map data = (res.data['data'] is Map)
            ? res.data['data'] as Map
            : res.data as Map;
        final name = data['fullName']?.toString() ??
            data['name']?.toString();
        if (name != null && name.isNotEmpty && mounted) {
          setState(() {
            _userName = name;
          });
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final groupsAsync = ref.watch(userGroupsProvider);
    final groupsList = groupsAsync.value ?? [];

    double totalNetBalance = 0;
    for (final g in groupsList) {
      totalNetBalance += (g.userBalance ?? 0.0);
    }

    return Scaffold(
      backgroundColor: AppColors.n50,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: RefreshIndicator(
            onRefresh: () async {
              await Future.wait([
                ref.read(userGroupsProvider.notifier).fetchGroups(),
                _loadUserProfile(),
              ]);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.s20, vertical: AppDimensions.s16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- 1. USER HEADER ---
                  _buildUserHeader(),
                  const SizedBox(height: AppDimensions.s20),

                  // --- 2. SUMMARY BALANCE CARD (TÍNH TỪ CSDL) ---
                  _buildNetBalanceOverviewCard(totalNetBalance),
                  const SizedBox(height: AppDimensions.s20),

                  // --- 3. QUICK ACTION BUTTONS ---
                  _buildQuickActionsRow(),
                  const SizedBox(height: AppDimensions.s24),

                  // --- 4. CURRENT ACTIVE GROUPS (ĐỌC TỪ CSDL) ---
                  _buildActiveGroupsSection(groupsAsync, groupsList),
                  const SizedBox(height: AppDimensions.s32),
                ],
              ),
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
                Text('Xin chào, $_userName!',
                    style: AppTypography.title.copyWith(fontSize: 18)),
                Text('SplitDebt Ledger', style: AppTypography.caption),
              ],
            ),
          ],
        ),

        // Notification Bell Icon
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

  // --- SUMMARY BALANCE CARD TỪ CSDL ---
  Widget _buildNetBalanceOverviewCard(double totalNetBalance) {
    final bool isPositive = totalNetBalance > 0.01;
    final bool isNegative = totalNetBalance < -0.01;

    final String statusLabel = isPositive
        ? 'CẦN NHẬN LẠI TIỀN'
        : (isNegative ? 'BẠN ĐANG CẦN TRẢ' : 'ĐÃ CÂN BẰNG NỢ');

    final Color statusColor = isPositive
        ? AppColors.success
        : (isNegative ? AppColors.error : AppColors.info);

    final String displayAmount = isPositive
        ? '+${currencyFormatter.format(totalNetBalance)}'
        : (isNegative
            ? '-${currencyFormatter.format(totalNetBalance.abs())}'
            : '0 ₫');

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
              Text('TỔNG SỐ DƯ RÒNG CÔNG NỢ',
                  style: AppTypography.caption.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                      letterSpacing: 1.0,
                      fontWeight: FontWeight.w700)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: AppDimensions.radius8,
                ),
                child: Text(statusLabel,
                    style: AppTypography.caption.copyWith(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            displayAmount,
            style: AppTypography.display.copyWith(
                color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: AppDimensions.s16),
          const Divider(height: 1, color: Colors.white24),
          const SizedBox(height: AppDimensions.s12),
          Text(
            isPositive
                ? 'Các thành viên trong nhóm đang nợ bạn.'
                : (isNegative
                    ? 'Bạn có khoản chi cần thanh toán cho nhóm.'
                    : 'Bạn không có khoản nợ tồn đọng nào.'),
            style: AppTypography.caption
                .copyWith(color: Colors.white.withValues(alpha: 0.9)),
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

  // --- ACTIVE GROUPS SECTION (ĐỌC TỪ CSDL QUA RIVERPOD) ---
  Widget _buildActiveGroupsSection(
      AsyncValue<List<GroupModel>> groupsAsync, List<GroupModel> groupsList) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Nhóm chi tiêu (${groupsList.length})',
                style: AppTypography.label.copyWith(fontSize: 15)),
          ],
        ),
        const SizedBox(height: AppDimensions.s12),
        if (groupsAsync.isLoading && groupsList.isEmpty)
          const Center(
              child: Padding(
            padding: EdgeInsets.all(24.0),
            child: CircularProgressIndicator(),
          ))
        else if (groupsList.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppDimensions.s20),
            decoration: BoxDecoration(
              color: AppColors.n0,
              borderRadius: AppDimensions.radius20,
              boxShadow: AppDimensions.shadowSm,
              border: Border.all(color: AppColors.p100),
            ),
            child: Column(
              children: [
                const Icon(Icons.group_off_outlined,
                    size: 40, color: AppColors.n400),
                const SizedBox(height: AppDimensions.s8),
                Text('Bạn chưa có nhóm chi tiêu nào',
                    style: AppTypography.title.copyWith(fontSize: 15)),
                const SizedBox(height: 4),
                Text('Chuyển sang tab "Nhóm" để tạo hoặc tham gia nhóm mới.',
                    textAlign: TextAlign.center,
                    style: AppTypography.caption),
              ],
            ),
          )
        else
          ...groupsList.map((group) {
            final double balance = group.userBalance ?? 0.0;
            final bool isPositive = balance > 0.01;
            final bool isNegative = balance < -0.01;

            return Container(
              margin: const EdgeInsets.only(bottom: AppDimensions.s12),
              padding: const EdgeInsets.all(AppDimensions.s16),
              decoration: BoxDecoration(
                color: AppColors.n0,
                borderRadius: AppDimensions.radius20,
                boxShadow: AppDimensions.shadowSm,
                border: Border.all(color: AppColors.p100),
              ),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GroupDetailScreen(group: group),
                    ),
                  );
                },
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
                              Text(group.name,
                                  style: AppTypography.title
                                      .copyWith(fontSize: 16)),
                              Text(
                                '${group.memberCount} thành viên • ${group.currentUserRole}',
                                style: AppTypography.caption,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
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
                    const SizedBox(height: AppDimensions.s12),
                    const Divider(height: 1, color: AppColors.n100),
                    const SizedBox(height: AppDimensions.s8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Số dư của bạn:', style: AppTypography.caption),
                        Text(
                          isPositive
                              ? '+${currencyFormatter.format(balance)}'
                              : (isNegative
                                  ? '-${currencyFormatter.format(balance.abs())}'
                                  : '0 ₫'),
                          style: AppTypography.bodyLarge.copyWith(
                            fontWeight: FontWeight.w800,
                            color: isPositive
                                ? AppColors.success
                                : (isNegative
                                    ? AppColors.error
                                    : AppColors.n700),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  // --- MODAL THÔNG BÁO PUSH REAL-TIME FCM ---
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
