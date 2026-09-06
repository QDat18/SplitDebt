import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_typography.dart';
import 'create_expense_screen.dart';

/// MÔ HÌNH DỮ LIỆU KHOẢN CHI CHI TIẾT
class ExpenseDetailModel {
  final String id;
  final String title;
  final double totalAmount;
  final String categoryName;
  final IconData categoryIcon;
  final Color categoryColor;
  final String payerName;
  final String payerAvatar;
  final DateTime createdAt;
  final String groupName;
  final String splitModeName;
  final bool isSettled; // Quy tắc khóa BE2-EXP-02
  final String? receiptUrl;
  final List<ExpenseParticipantDetail> participants;

  ExpenseDetailModel({
    required this.id,
    required this.title,
    required this.totalAmount,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColor,
    required this.payerName,
    required this.payerAvatar,
    required this.createdAt,
    required this.groupName,
    required this.splitModeName,
    required this.isSettled,
    this.receiptUrl,
    required this.participants,
  });
}

class ExpenseParticipantDetail {
  final String name;
  final String avatarUrl;
  final double amount;
  final bool isPayer;

  ExpenseParticipantDetail({
    required this.name,
    required this.avatarUrl,
    required this.amount,
    this.isPayer = false,
  });
}

/// ----------------------------------------------------------------------------
/// MÀN HÌNH CHI TIẾT KHOẢN CHI (EXPENSE DETAIL SCREEN)
/// Tích hợp quy tắc khóa BE2-EXP-02 & Giao diện hiện đại chuẩn Design Tokens
/// ----------------------------------------------------------------------------
class ExpenseDetailScreen extends ConsumerStatefulWidget {
  final ExpenseDetailModel? expenseData;

  const ExpenseDetailScreen({super.key, this.expenseData});

  @override
  ConsumerState<ExpenseDetailScreen> createState() => _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends ConsumerState<ExpenseDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
  final dateFormatter = DateFormat('HH:mm - dd/MM/yyyy');

  late ExpenseDetailModel _expense;

  @override
  void initState() {
    super.initState();

    // Dữ liệu mẫu khoản chi nếu không truyền vào
    _expense = widget.expenseData ??
        ExpenseDetailModel(
          id: 'exp_1001',
          title: 'Ăn lẩu nướng Gogi House',
          totalAmount: 680000,
          categoryName: 'Ăn uống',
          categoryIcon: Icons.restaurant_rounded,
          categoryColor: const Color(0xFFFF7675),
          payerName: 'Đạt (Tôi)',
          payerAvatar: 'https://i.pravatar.cc/150?img=11',
          createdAt: DateTime.now().subtract(const Duration(hours: 3)),
          groupName: 'Du Lịch Hà Giang',
          splitModeName: 'Theo món ăn (ITEM)',
          isSettled: false, // Thử đổi true để test quy tắc khóa BE2-EXP-02
          receiptUrl: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?auto=format&fit=crop&w=600&q=80',
          participants: [
            ExpenseParticipantDetail(name: 'Đạt (Tôi)', avatarUrl: 'https://i.pravatar.cc/150?img=11', amount: 210000, isPayer: true),
            ExpenseParticipantDetail(name: 'Hoàng (Dev 1)', avatarUrl: 'https://i.pravatar.cc/150?img=12', amount: 190000),
            ExpenseParticipantDetail(name: 'Minh (Dev 3)', avatarUrl: 'https://i.pravatar.cc/150?img=13', amount: 140000),
            ExpenseParticipantDetail(name: 'Trang (Dev 4)', avatarUrl: 'https://i.pravatar.cc/150?img=5', amount: 140000),
          ],
        );

    // Chuyển động mượt mà
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );

    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(
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
                      // --- 1. CARD TỔNG QUAN KHOẢN CHI & TRẠNG THÁI KHÓA ---
                      _buildHeaderExpenseCard(),
                      const SizedBox(height: AppDimensions.s20),

                      // --- 2. BẢNG PHÂN RÃ CHI TIẾT TỪNG THÀNH VIÊN ---
                      _buildParticipantBreakdownCard(),
                      const SizedBox(height: AppDimensions.s20),

                      // --- 3. ẢNH HÓA ĐƠN RECEIPT (NẾU CÓ) ---
                      if (_expense.receiptUrl != null) ...[
                        _buildReceiptImageCard(context),
                        const SizedBox(height: AppDimensions.s20),
                      ],

                      // --- 4. CẢNH BÁO QUY TẮC KHÓA BE2-EXP-02 (NẾU ĐÃ QUYẾT TOÁN) ---
                      if (_expense.isSettled) _buildLockWarningBanner(),
                    ],
                  ),
                ),
              ),

              // --- 5. NÚT CHỨC NĂNG (SỬA / XÓA KHOẢN CHI) ---
              _buildActionBottomBar(context),
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
      title: Text('Chi tiết khoản chi', style: AppTypography.title.copyWith(fontSize: 17)),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.share_outlined, color: AppColors.n700),
          onPressed: () {
            HapticFeedback.lightImpact();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Đã sao chép liên kết khoản chi!'),
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

  // --- CARD HEADER TỔNG QUAN KHOẢN CHI ---
  Widget _buildHeaderExpenseCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.s20),
      decoration: BoxDecoration(
        color: AppColors.n0,
        borderRadius: AppDimensions.radius24,
        boxShadow: AppDimensions.shadowMd,
        border: Border.all(color: AppColors.p100.withOpacity(0.6)),
      ),
      child: Column(
        children: [
          // Badge Danh mục & Khóa
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _expense.categoryColor.withOpacity(0.15),
                  borderRadius: AppDimensions.radius12,
                ),
                child: Row(
                  children: [
                    Icon(_expense.categoryIcon, size: 16, color: _expense.categoryColor),
                    const SizedBox(width: 6),
                    Text(_expense.categoryName, style: AppTypography.label.copyWith(color: _expense.categoryColor, fontSize: 13)),
                  ],
                ),
              ),

              // Status Badge (Đã chốt sổ / Chưa chốt)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _expense.isSettled ? AppColors.warningTint : AppColors.successTint,
                  borderRadius: AppDimensions.radius8,
                ),
                child: Row(
                  children: [
                    Icon(
                      _expense.isSettled ? Icons.lock_rounded : Icons.schedule_rounded,
                      size: 13,
                      color: _expense.isSettled ? AppColors.warning : AppColors.success,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _expense.isSettled ? 'Đã chốt sổ (Đã khóa)' : 'Chờ quyết toán',
                      style: AppTypography.caption.copyWith(
                        color: _expense.isSettled ? AppColors.warning : AppColors.success,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.s16),

          // Tiêu đề khoản chi
          Text(_expense.title, textAlign: TextAlign.center, style: AppTypography.h2.copyWith(fontSize: 22)),
          const SizedBox(height: 6),

          // Tổng số tiền lớn
          Text(
            currencyFormatter.format(_expense.totalAmount),
            style: AppTypography.display.copyWith(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: AppColors.p500,
            ),
          ),

          const SizedBox(height: AppDimensions.s16),
          const Divider(height: 1, color: AppColors.n100),
          const SizedBox(height: AppDimensions.s12),

          // Người ứng tiền & Thời gian
          Row(
            children: [
              CircleAvatar(radius: 18, backgroundImage: NetworkImage(_expense.payerAvatar)),
              const SizedBox(width: AppDimensions.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Người ứng tiền: ', style: AppTypography.caption),
                        Text(_expense.payerName, style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w700, color: AppColors.p700)),
                      ],
                    ),
                    Text(dateFormatter.format(_expense.createdAt), style: AppTypography.caption),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.n50,
                  borderRadius: AppDimensions.radius8,
                  border: Border.all(color: AppColors.n200),
                ),
                child: Text(_expense.splitModeName, style: AppTypography.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- CARD DANH SÁCH THÀNH VIÊN & SỐ TIỀN PHẢI TRẢ ---
  Widget _buildParticipantBreakdownCard() {
    return Container(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Phân rã chi tiêu (${_expense.participants.length} người)', style: AppTypography.label.copyWith(fontSize: 15)),
              Text('Số tiền nợ', style: AppTypography.caption.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: AppDimensions.s12),
          const Divider(height: 1, color: AppColors.n100),
          const SizedBox(height: AppDimensions.s12),
          ..._expense.participants.map((p) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.s12),
              child: Row(
                children: [
                  CircleAvatar(radius: 18, backgroundImage: NetworkImage(p.avatarUrl)),
                  const SizedBox(width: AppDimensions.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(p.name, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                            if (p.isPayer) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.p50,
                                  borderRadius: AppDimensions.radius8,
                                ),
                                child: Text('Đã ứng tiền', style: AppTypography.caption.copyWith(fontSize: 10, color: AppColors.p700, fontWeight: FontWeight.w700)),
                              ),
                            ]
                          ],
                        ),
                        Text(
                          p.isPayer
                              ? 'Nhận lại: ${currencyFormatter.format(_expense.totalAmount - p.amount)}'
                              : 'Phải trả: ${currencyFormatter.format(p.amount)}',
                          style: AppTypography.caption.copyWith(
                            color: p.isPayer ? AppColors.success : AppColors.n600,
                            fontWeight: p.isPayer ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    currencyFormatter.format(p.amount),
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w700,
                      color: p.isPayer ? AppColors.success : AppColors.n800,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // --- CARD HIỂN THỊ ẢNH HÓA ĐƠN (RECEIPT) ---
  Widget _buildReceiptImageCard(BuildContext context) {
    return Container(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Ảnh hóa đơn đính kèm', style: AppTypography.label.copyWith(fontSize: 15)),
              const Icon(Icons.zoom_in_rounded, size: 18, color: AppColors.p500),
            ],
          ),
          const SizedBox(height: AppDimensions.s12),
          ClipRRect(
            borderRadius: AppDimensions.radius16,
            child: Stack(
              children: [
                Image.network(
                  _expense.receiptUrl!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: AppDimensions.radius8,
                    ),
                    child: Text('Chạm để xem ảnh gốc', style: AppTypography.caption.copyWith(color: Colors.white, fontSize: 11)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- BANNER CẢNH BÁO QUY TẮC KHÓA BE2-EXP-02 ---
  Widget _buildLockWarningBanner() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.s16),
      decoration: BoxDecoration(
        color: AppColors.warningTint,
        borderRadius: AppDimensions.radius16,
        border: Border.all(color: AppColors.warning.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_clock_rounded, color: AppColors.warning, size: 24),
          const SizedBox(width: AppDimensions.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Quy tắc khóa sổ BE2-EXP-02', style: AppTypography.label.copyWith(color: AppColors.warning, fontSize: 14)),
                const SizedBox(height: 2),
                Text('Khoản chi này đã chốt quyết toán toán nợ. Bạn không thể sửa hoặc xóa để tránh sai lệch sổ sách.',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.n800)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- BOTTOM BAR: SỬA & XÓA KHOẢN CHI ---
  Widget _buildActionBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.s20, vertical: AppDimensions.s16),
      decoration: BoxDecoration(
        color: AppColors.n0,
        boxShadow: AppDimensions.shadowLg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppDimensions.r24)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Nút Xóa khoản chi
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _expense.isSettled
                    ? null
                    : () => _confirmDeleteExpense(context),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: _expense.isSettled ? AppColors.n300 : AppColors.error),
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: AppDimensions.radius16),
                ),
                icon: Icon(Icons.delete_outline_rounded, color: _expense.isSettled ? AppColors.n400 : AppColors.error, size: 20),
                label: Text(
                  'Xóa khoản chi',
                  style: AppTypography.label.copyWith(color: _expense.isSettled ? AppColors.n400 : AppColors.error),
                ),
              ),
            ),
            const SizedBox(width: AppDimensions.s12),

            // Nút Chỉnh sửa khoản chi
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _expense.isSettled
                    ? null
                    : () {
                        HapticFeedback.lightImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CreateExpenseScreen()),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _expense.isSettled ? AppColors.n300 : AppColors.p500,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: AppDimensions.radius16),
                ),
                icon: Icon(_expense.isSettled ? Icons.lock_rounded : Icons.edit_rounded, color: Colors.white, size: 20),
                label: Text(
                  _expense.isSettled ? 'Đã khóa' : 'Chỉnh sửa',
                  style: AppTypography.title.copyWith(color: Colors.white, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Bottom sheet xác nhận xóa
  void _confirmDeleteExpense(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.r24))),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(AppDimensions.s24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: AppColors.n300, borderRadius: AppDimensions.radius8),
              ),
              const SizedBox(height: AppDimensions.s20),
              const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 48),
              const SizedBox(height: AppDimensions.s12),
              Text('Xác nhận xóa khoản chi?', style: AppTypography.h3),
              const SizedBox(height: AppDimensions.s8),
              Text(
                'Bạn có chắc chắn muốn xóa "${_expense.title}"? Thao tác này sẽ cập nhật lại toàn bộ dư nợ của nhóm.',
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
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Đã xóa khoản chi thành công!'),
                            backgroundColor: AppColors.error,
                            behavior: SnackBarBehavior.floating,
                            margin: const EdgeInsets.only(bottom: 95, left: 16, right: 16),
                            duration: const Duration(seconds: 2),
                            shape: RoundedRectangleBorder(borderRadius: AppDimensions.radius12),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(borderRadius: AppDimensions.radius16),
                      ),
                      child: const Text('Xóa ngay', style: TextStyle(color: Colors.white)),
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
