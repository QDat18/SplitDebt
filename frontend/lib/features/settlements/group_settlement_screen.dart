import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_typography.dart';
import 'settlement_confirmation_screen.dart';

/// MODEL THÔNG TIN DƯ NỢ RÒNG TỪNG THÀNH VIÊN
class MemberNetBalanceModel {
  final String id;
  final String name;
  final String avatarUrl;
  final double netBalance; // Dương: Cần nhận lại tiền, Âm: Cần trả tiền

  MemberNetBalanceModel({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.netBalance,
  });
}

/// MODEL GIAO DỊCH NỢ ĐÃ TỐI ƯU (MIN-CASH-FLOW ALGORITHM BE2-SET-01)
class OptimizedDebtTransactionModel {
  final String id;
  final String fromMemberId;
  final String fromMemberName;
  final String fromMemberAvatar;
  final String toMemberId;
  final String toMemberName;
  final String toMemberAvatar;
  final double amount;
  final String status; // PENDING, CONFIRMED_BY_PAYER, COMPLETED

  OptimizedDebtTransactionModel({
    required this.id,
    required this.fromMemberId,
    required this.fromMemberName,
    required this.fromMemberAvatar,
    required this.toMemberId,
    required this.toMemberName,
    required this.toMemberAvatar,
    required this.amount,
    this.status = 'PENDING',
  });
}

/// ----------------------------------------------------------------------------
/// MÀN HÌNH QUYẾT TOÁN NỢ NHÓM & TỐI ƯU DÒNG TIỀN (GROUP SETTLEMENT SCREEN)
/// Thuật toán Min-Cash-Flow BE2-SET-01 & Chuẩn Design Tokens
/// ----------------------------------------------------------------------------
class GroupSettlementScreen extends ConsumerStatefulWidget {
  const GroupSettlementScreen({super.key});

  @override
  ConsumerState<GroupSettlementScreen> createState() => _GroupSettlementScreenState();
}

class _GroupSettlementScreenState extends ConsumerState<GroupSettlementScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);

  int _selectedTabIndex = 0; // 0: Dư nợ ròng, 1: Giao dịch tối ưu

  // Dữ liệu dư nợ ròng mẫu
  late List<MemberNetBalanceModel> _netBalances;

  // Dữ liệu giao dịch nợ đã tối ưu qua thuật toán Min-Cash-Flow (BE2-SET-01)
  late List<OptimizedDebtTransactionModel> _optimizedDebts;

  @override
  void initState() {
    super.initState();

    _netBalances = [
      MemberNetBalanceModel(id: 'u1', name: 'Đạt (Tôi)', avatarUrl: 'https://i.pravatar.cc/150?img=11', netBalance: 340000), // Cần nhận +340k
      MemberNetBalanceModel(id: 'u2', name: 'Hoàng (Dev 1)', avatarUrl: 'https://i.pravatar.cc/150?img=12', netBalance: 120000), // Cần nhận +120k
      MemberNetBalanceModel(id: 'u3', name: 'Minh (Dev 3)', avatarUrl: 'https://i.pravatar.cc/150?img=13', netBalance: -280000), // Âm 280k
      MemberNetBalanceModel(id: 'u4', name: 'Trang (Dev 4)', avatarUrl: 'https://i.pravatar.cc/150?img=5', netBalance: -180000), // Âm 180k
    ];

    // Giao dịch nợ sau khi thuật toán Min-Cash-Flow rút gọn từ 6 giao dịch xuống còn 2 giao dịch!
    _optimizedDebts = [
      OptimizedDebtTransactionModel(
        id: 'tx_201',
        fromMemberId: 'u3',
        fromMemberName: 'Minh (Dev 3)',
        fromMemberAvatar: 'https://i.pravatar.cc/150?img=13',
        toMemberId: 'u1',
        toMemberName: 'Đạt (Tôi)',
        toMemberAvatar: 'https://i.pravatar.cc/150?img=11',
        amount: 280000,
        status: 'PENDING',
      ),
      OptimizedDebtTransactionModel(
        id: 'tx_202',
        fromMemberId: 'u4',
        fromMemberName: 'Trang (Dev 4)',
        fromMemberAvatar: 'https://i.pravatar.cc/150?img=5',
        toMemberId: 'u1',
        toMemberName: 'Đạt (Tôi)',
        toMemberAvatar: 'https://i.pravatar.cc/150?img=11',
        amount: 60000,
        status: 'CONFIRMED_BY_PAYER',
      ),
      OptimizedDebtTransactionModel(
        id: 'tx_203',
        fromMemberId: 'u4',
        fromMemberName: 'Trang (Dev 4)',
        fromMemberAvatar: 'https://i.pravatar.cc/150?img=5',
        toMemberId: 'u2',
        toMemberName: 'Hoàng (Dev 1)',
        toMemberAvatar: 'https://i.pravatar.cc/150?img=12',
        amount: 120000,
        status: 'COMPLETED',
      ),
    ];

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );

    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.07), end: Offset.zero).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.n50,
      appBar: _buildAppBar(context),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: AppDimensions.s20, vertical: AppDimensions.s12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- 1. CARD TỔNG QUAN THUẬT TOÁN TỐI ƯU DÒNG TIỀN ---
                      _buildSummaryOverviewCard(),
                      const SizedBox(height: AppDimensions.s20),

                      // --- 2. THANH SEGMENT TAB CHUYỂN ĐỔI ---
                      _buildSegmentTabs(),
                      const SizedBox(height: AppDimensions.s16),

                      // --- 3. NỘI DUNG TAB ĐANG CHỌN ---
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        switchInCurve: Curves.easeOutCubic,
                        child: _selectedTabIndex == 0 ? _buildNetBalanceTab() : _buildOptimizedDebtsTab(),
                      ),
                      const SizedBox(height: AppDimensions.s24),
                    ],
                  ),
                ),
              ),

              // --- 4. STICKY ACTION BAR CHỐT SỔ QUYẾT TOÁN NHÓM ---
              _buildStickyCloseLedgerBar(context),
            ],
          ),
        ),
      ),
    );
  }

  // --- APP BAR ---
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.n50,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.n0,
            shape: BoxShape.circle,
            boxShadow: AppDimensions.shadowSm,
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppColors.n800),
        ),
        onPressed: () => Navigator.maybePop(context),
      ),
      title: Text('Quyết toán Nợ nhóm', style: AppTypography.title.copyWith(fontSize: 17)),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.auto_awesome_rounded, color: AppColors.p500),
          onPressed: () {
            HapticFeedback.mediumImpact();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: Colors.amber),
                    SizedBox(width: 8),
                    Text('Thuật toán Min-Cash-Flow đã rút gọn 6 giao dịch -> 2 giao dịch!'),
                  ],
                ),
                backgroundColor: AppColors.p700,
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.only(bottom: 95, left: 16, right: 16),
                duration: const Duration(seconds: 2),
                shape: RoundedRectangleBorder(borderRadius: AppDimensions.radius12),
              ),
            );
          },
        ),
      ],
    );
  }

  // --- CARD TỔNG QUAN SỐ TIỀN & BADGE MIN-CASH-FLOW ---
  Widget _buildSummaryOverviewCard() {
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: AppDimensions.radius12,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.groups_rounded, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text('Du Lịch Hà Giang', style: AppTypography.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),

              // Smart Algorithm Badge BE2-SET-01
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warning,
                  borderRadius: AppDimensions.radius12,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.bolt_rounded, color: Colors.white, size: 14),
                    const SizedBox(width: 2),
                    Text('Tối ưu nợ BE2-SET-01', style: AppTypography.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.s16),
          Text('TỔNG CHI TIÊU NHÓM', style: AppTypography.caption.copyWith(color: Colors.white.withOpacity(0.8), letterSpacing: 1.2, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('2.450.000 ₫', style: AppTypography.display.copyWith(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
          const SizedBox(height: AppDimensions.s16),

          // Vùng hiển thị vị thế ròng cá nhân
          Container(
            padding: const EdgeInsets.all(AppDimensions.s12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.25),
              borderRadius: AppDimensions.radius16,
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 16,
                  backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11'),
                ),
                const SizedBox(width: AppDimensions.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Vị thế của bạn (Đạt):', style: AppTypography.caption.copyWith(color: Colors.white.withOpacity(0.9))),
                      Text('Bạn cần nhận lại +340.000 ₫', style: AppTypography.bodyMedium.copyWith(color: AppColors.successTint, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.white),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- SEGMENT TAB BANNER (2 TABS) ---
  Widget _buildSegmentTabs() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.n200.withOpacity(0.6),
        borderRadius: AppDimensions.radius16,
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _buildSegmentItem('Dư nợ ròng (Net)', 0, Icons.account_balance_wallet_rounded),
          _buildSegmentItem('Giao dịch tối ưu (Min-Flow)', 1, Icons.auto_awesome_rounded),
        ],
      ),
    );
  }

  Widget _buildSegmentItem(String title, int index, IconData icon) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            _selectedTabIndex = index;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.n0 : Colors.transparent,
            borderRadius: AppDimensions.radius12,
            boxShadow: isSelected ? AppDimensions.shadowSm : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isSelected ? AppColors.p500 : AppColors.n600),
              const SizedBox(width: 6),
              Text(
                title,
                style: AppTypography.caption.copyWith(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.p600 : AppColors.n600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- TAB 1: DƯ NỢ RÒNG TỪNG THÀNH VIÊN ---
  Widget _buildNetBalanceTab() {
    return Column(
      key: const ValueKey('net_tab'),
      children: _netBalances.map((m) {
        final isPositive = m.netBalance >= 0;
        return Container(
          margin: const EdgeInsets.only(bottom: AppDimensions.s12),
          padding: const EdgeInsets.all(AppDimensions.s16),
          decoration: BoxDecoration(
            color: AppColors.n0,
            borderRadius: AppDimensions.radius20,
            boxShadow: AppDimensions.shadowSm,
          ),
          child: Row(
            children: [
              CircleAvatar(radius: 20, backgroundImage: NetworkImage(m.avatarUrl)),
              const SizedBox(width: AppDimensions.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m.name, style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w700)),
                    Text(
                      isPositive ? 'Cần nhận lại từ nhóm' : 'Còn thiếu tiền nhóm',
                      style: AppTypography.caption.copyWith(color: AppColors.n500),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isPositive ? AppColors.successTint : AppColors.errorTint,
                  borderRadius: AppDimensions.radius12,
                ),
                child: Text(
                  '${isPositive ? '+' : ''}${currencyFormatter.format(m.netBalance)}',
                  style: AppTypography.title.copyWith(
                    fontSize: 15,
                    color: isPositive ? AppColors.success : AppColors.error,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // --- TAB 2: QUYẾT TOÁN DÒNG TIỀN TỐI ƯU (MIN-CASH-FLOW BE2-SET-01) ---
  Widget _buildOptimizedDebtsTab() {
    return Column(
      key: const ValueKey('opt_tab'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('DANH SÁCH GIAO DỊCH ĐÃ RÚT GỌN', style: AppTypography.label.copyWith(fontSize: 13, letterSpacing: 0.8, color: AppColors.n600)),
        const SizedBox(height: AppDimensions.s12),
        ..._optimizedDebts.map((tx) {
          final isCompleted = tx.status == 'COMPLETED';
          final isWaitingApprove = tx.status == 'CONFIRMED_BY_PAYER';

          return Container(
            margin: const EdgeInsets.only(bottom: AppDimensions.s12),
            padding: const EdgeInsets.all(AppDimensions.s16),
            decoration: BoxDecoration(
              color: AppColors.n0,
              borderRadius: AppDimensions.radius20,
              boxShadow: AppDimensions.shadowSm,
              border: isWaitingApprove ? Border.all(color: AppColors.warning) : null,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Người trả
                    Row(
                      children: [
                        CircleAvatar(radius: 16, backgroundImage: NetworkImage(tx.fromMemberAvatar)),
                        const SizedBox(width: 6),
                        Text(tx.fromMemberName, style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w700)),
                      ],
                    ),

                    // Mũi tên chuyển tiền
                    Row(
                      children: [
                        const Icon(Icons.arrow_forward_rounded, color: AppColors.p500, size: 18),
                        Text(' ${currencyFormatter.format(tx.amount)} ', style: AppTypography.title.copyWith(fontSize: 14, color: AppColors.p600)),
                        const Icon(Icons.arrow_forward_rounded, color: AppColors.p500, size: 18),
                      ],
                    ),

                    // Người nhận
                    Row(
                      children: [
                        Text(tx.toMemberName, style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(width: 6),
                        CircleAvatar(radius: 16, backgroundImage: NetworkImage(tx.toMemberAvatar)),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: AppDimensions.s12),
                const Divider(height: 1, color: AppColors.n100),
                const SizedBox(height: AppDimensions.s12),

                // Trạng thái và nút bấm thanh toán 2 chiều (BE2-SET-02)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isCompleted
                              ? Icons.check_circle_rounded
                              : isWaitingApprove
                                  ? Icons.pending_rounded
                                  : Icons.circle_outlined,
                          size: 16,
                          color: isCompleted
                              ? AppColors.success
                              : isWaitingApprove
                                  ? AppColors.warning
                                  : AppColors.n500,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isCompleted
                              ? 'Hoàn tất thanh toán'
                              : isWaitingApprove
                                  ? 'Chờ người nhận xác nhận'
                                  : 'Chưa thanh toán',
                          style: AppTypography.caption.copyWith(
                            color: isCompleted
                                ? AppColors.success
                                : isWaitingApprove
                                    ? AppColors.warning
                                    : AppColors.n600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                    if (!isCompleted)
                      ElevatedButton.icon(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SettlementConfirmationScreen(
                                fromName: tx.fromMemberName,
                                fromAvatar: tx.fromMemberAvatar,
                                toName: tx.toMemberName,
                                toAvatar: tx.toMemberAvatar,
                                amount: tx.amount,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.p500,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: AppDimensions.radius12),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
                        icon: const Icon(Icons.qr_code_scanner_rounded, size: 16, color: Colors.white),
                        label: Text(
                          isWaitingApprove ? 'Duyệt 2 chiều' : 'Thanh toán',
                          style: AppTypography.label.copyWith(color: Colors.white, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  // --- NÚT STICKY: CHỐT SỔ QUYẾT TOÁN NHÓM ---
  Widget _buildStickyCloseLedgerBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.s20, vertical: AppDimensions.s16),
      decoration: BoxDecoration(
        color: AppColors.n0,
        boxShadow: AppDimensions.shadowLg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppDimensions.r24)),
      ),
      child: SafeArea(
        child: InkWell(
          onTap: () => _confirmCloseGroupLedger(context),
          borderRadius: AppDimensions.radius20,
          child: Container(
            height: 54,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: AppDimensions.radius20,
              boxShadow: [
                BoxShadow(
                  color: AppColors.p500.withOpacity(0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_reset_rounded, color: Colors.white, size: 22),
                const SizedBox(width: AppDimensions.s8),
                Text('CHỐT SỔ QUYẾT TOÁN NHÓM', style: AppTypography.title.copyWith(color: Colors.white, fontSize: 15, letterSpacing: 0.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Confirm close group ledger dialog
  void _confirmCloseGroupLedger(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.r24))),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(AppDimensions.s24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.n300, borderRadius: AppDimensions.radius8)),
              const SizedBox(height: AppDimensions.s20),
              const Icon(Icons.published_with_changes_rounded, color: AppColors.p500, size: 48),
              const SizedBox(height: AppDimensions.s12),
              Text('Chốt sổ & Đóng băng sổ sách?', style: AppTypography.h3),
              const SizedBox(height: AppDimensions.s8),
              Text(
                'Toàn bộ các khoản chi trong nhóm "Du Lịch Hà Giang" sẽ được chuyển sang trạng thái ĐÃ CHỐT SỔ (Khóa chỉnh sửa per BE2-EXP-02) và đặt lại vị thế nợ ròng về 0 ₫.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium,
              ),
              const SizedBox(height: AppDimensions.s24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(borderRadius: AppDimensions.radius16),
                      ),
                      child: const Text('Hủy bỏ'),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.s12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Row(
                              children: [
                                Icon(Icons.check_circle_rounded, color: Colors.white),
                                SizedBox(width: 8),
                                Text('Đã chốt sổ quyết toán nhóm thành công!'),
                              ],
                            ),
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                            margin: const EdgeInsets.only(bottom: 95, left: 16, right: 16),
                            duration: const Duration(seconds: 2),
                            shape: RoundedRectangleBorder(borderRadius: AppDimensions.radius12),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.p500,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(borderRadius: AppDimensions.radius16),
                      ),
                      child: const Text('Chốt sổ ngay', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
