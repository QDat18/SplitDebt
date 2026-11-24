// Trách nhiệm file: Xây dựng màn hình dashboard screen và điều phối tương tác người dùng theo chuẩn Apple HIG.

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
import '../groups/widgets/error_state.dart';

/// ----------------------------------------------------------------------------
/// MÀN HÌNH DASHBOARD TRANG CHỦ (MAIN DASHBOARD SCREEN - APPLE HIG)
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
  final int _unreadNotificationCount = 0;
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
      backgroundColor: AppColors.n100,
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
                  horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- 1. USER HEADER ---
                  _buildUserHeader(),
                  const SizedBox(height: 16),

                  // --- 2. SUMMARY BALANCE CARD (APPLE HIG STYLE) ---
                  _buildNetBalanceOverviewCard(totalNetBalance,
                      hasError: groupsAsync.hasError),
                  const SizedBox(height: 16),

                  // --- 3. QUICK ACTION BUTTONS ---
                  _buildQuickActionsRow(),
                  const SizedBox(height: 22),

                  // --- 4. CURRENT ACTIVE GROUPS (APPLE HIG INSET GROUPED) ---
                  _buildActiveGroupsSection(groupsAsync, groupsList),
                  const SizedBox(height: 24),
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
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.p500, width: 2),
              ),
              child: const CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.p50,
                child: Icon(Icons.person, color: AppColors.p500, size: 22),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Xin chào, $_userName!',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.n900,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'SplitDebt Ledger',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.n500,
                  ),
                ),
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
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: AppColors.n0,
              shape: BoxShape.circle,
              boxShadow: AppDimensions.shadowSm,
            ),
            child: Stack(
              children: [
                const Icon(
                  Icons.notifications_none_rounded,
                  color: AppColors.n800,
                  size: 22,
                ),
                if (_unreadNotificationCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
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

  // --- SUMMARY BALANCE CARD TỪ CSDL (APPLE CARD STYLE) ---
  Widget _buildNetBalanceOverviewCard(double totalNetBalance,
      {bool hasError = false}) {
    if (hasError) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2C2C2E), Color(0xFF1C1C1E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TỔNG SỐ DƯ RÒNG CÔNG NỢ',
                  style: TextStyle(
                    color: AppColors.n400,
                    fontSize: 11,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.n600,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'LỖI TẢI DỮ LIỆU',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              '—',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: Colors.white12),
            const SizedBox(height: 10),
            const Text(
              'Không thể tính toán số dư do tải danh sách nhóm thất bại.',
              style: TextStyle(color: AppColors.n400, fontSize: 12),
            ),
          ],
        ),
      );
    }

    final bool isPositive = totalNetBalance > 0.01;
    final bool isNegative = totalNetBalance < -0.01;

    final String statusLabel = isPositive
        ? 'CẦN NHẬN LẠI TIỀN'
        : (isNegative ? 'BẠN ĐANG CẦN TRẢ' : 'ĐÃ CÂN BẰNG NỢ');

    final Color statusTextColor = isPositive
        ? const Color(0xFF34C759) // iOS green
        : (isNegative ? const Color(0xFFFF453A) : const Color(0xFF0A84FF));

    final Color statusBgColor = isPositive
        ? const Color(0xFF34C759).withValues(alpha: 0.18)
        : (isNegative
            ? const Color(0xFFFF453A).withValues(alpha: 0.18)
            : const Color(0xFF0A84FF).withValues(alpha: 0.18));

    final String displayAmount = isPositive
        ? '+${currencyFormatter.format(totalNetBalance)}'
        : (isNegative
            ? '-${currencyFormatter.format(totalNetBalance.abs())}'
            : '0 ₫');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2C2C2E), Color(0xFF1C1C1E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TỔNG SỐ DƯ RÒNG',
                style: TextStyle(
                  color: AppColors.n400,
                  fontSize: 11,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusTextColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            displayAmount,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Colors.white12),
          const SizedBox(height: 10),
          Text(
            isPositive
                ? 'Các thành viên trong nhóm đang nợ bạn.'
                : (isNegative
                    ? 'Bạn có khoản chi cần thanh toán cho nhóm.'
                    : 'Bạn không có khoản nợ tồn đọng nào.'),
            style: const TextStyle(
              color: AppColors.n400,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // --- QUICK ACTION BUTTONS ROW (APPLE HIG) ---
  Widget _buildQuickActionsRow() {
    return Row(
      children: [
        // Action 1: Tạo khoản chi mới
        Expanded(
          child: InkWell(
            onTap: widget.onNavigateToCreateExpense,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.all(14),
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
                      color: AppColors.p50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.add_circle_outline_rounded,
                      color: AppColors.p500,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tạo chi tiêu',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.n800,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Chia tiền tự động',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.n500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Action 2: Quyết toán nợ
        Expanded(
          child: InkWell(
            onTap: widget.onNavigateToSettlement,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.all(14),
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
                      color: AppColors.warningTint,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: AppColors.warning,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quyết toán',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.n800,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Tối ưu hóa nợ',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.n500,
                          ),
                        ),
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

  // --- ACTIVE GROUPS SECTION (APPLE HIG INSET GROUPED) ---
  Widget _buildActiveGroupsSection(
      AsyncValue<List<GroupModel>> groupsAsync, List<GroupModel> groupsList) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'NHÓM CHI TIÊU (${groupsList.length})',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.n500,
              letterSpacing: 0.5,
            ),
          ),
        ),
        if (groupsAsync.isLoading && groupsList.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(),
            ),
          )
        else if (groupsAsync.hasError)
          ErrorStateWidget(
            errorMessage: 'Không thể tải danh sách nhóm.',
            onRetry: () => ref.read(userGroupsProvider.notifier).fetchGroups(),
          )
        else if (groupsList.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.n0,
              borderRadius: BorderRadius.circular(14),
              boxShadow: AppDimensions.shadowSm,
            ),
            child: const Column(
              children: [
                Icon(Icons.group_off_rounded, size: 44, color: AppColors.n400),
                SizedBox(height: 10),
                Text(
                  'Bạn chưa có nhóm chi tiêu nào',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.n800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Chuyển sang tab "Nhóm" để tạo hoặc tham gia nhóm mới.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.n500),
                ),
              ],
            ),
          )
        else
          ...groupsList.map((group) {
            final double balance = group.userBalance ?? 0.0;
            final bool isPositive = balance > 0.01;
            final bool isNegative = balance < -0.01;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: AppColors.n0,
                borderRadius: BorderRadius.circular(14),
                boxShadow: AppDimensions.shadowSm,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GroupDetailScreen(group: group),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: AppColors.p50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.groups_rounded,
                                color: AppColors.p500,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    group.name,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.n800,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${group.memberCount} thành viên • ${group.currentUserRole}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.n500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.n400,
                              size: 20,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Divider(height: 1, color: AppColors.n100),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Số dư của bạn:',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.n500,
                              ),
                            ),
                            Text(
                              isPositive
                                  ? '+${currencyFormatter.format(balance)}'
                                  : (isNegative
                                      ? '-${currencyFormatter.format(balance.abs())}'
                                      : '0 ₫'),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
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
                ),
              ),
            );
          }),
      ],
    );
  }

  // --- MODAL THÔNG BÁO PUSH REAL-TIME FCM (APPLE HIG) ---
  Future<void> _showNotificationSheet(BuildContext context) async {
    final future = _loadNotifications();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.n100,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.65,
        child: Column(
          children: [
            // iOS drag indicator
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              decoration: BoxDecoration(
                color: AppColors.n300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Text(
                    'Thông báo',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.n900,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.n200),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: future,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Không tải được thông báo: ${snapshot.error}'),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final notifications = snapshot.data!;
                  if (notifications.isEmpty) {
                    return const Center(
                      child: Text(
                        'Chưa có thông báo nào.',
                        style: TextStyle(color: AppColors.n500),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: notifications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = notifications[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: AppColors.n0,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: AppDimensions.shadowSm,
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 4),
                          leading: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.p50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.notifications_none_rounded,
                              color: AppColors.p500,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            item['title']?.toString() ?? '',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.n800,
                            ),
                          ),
                          subtitle: Text(
                            item['content']?.toString() ?? '',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.n500,
                            ),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            widget.onNavigateToSettlement();
                          },
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
