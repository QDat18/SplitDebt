import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_typography.dart';
import 'data/settlement_repository.dart';

/// ----------------------------------------------------------------------------
/// MÀN HÌNH XÁC NHẬN THANH TOÁN 2 CHIỀU (SETTLEMENT CONFIRMATION SCREEN)
/// Quy trình 2 chiều Payer -> Receiver xác nhận giao dịch BE2-SET-02
/// ----------------------------------------------------------------------------
class SettlementConfirmationScreen extends ConsumerStatefulWidget {
  final String fromName;
  final String fromAvatar;
  final String toName;
  final String toAvatar;
  final double amount;
  final bool initialPayerConfirmed;

  // ID để gọi API backend → trigger FCM
  // Nếu null thì chạy offline (mock data)
  final int? groupId;
  final int? settlementId;
  final int? currentUserId;

  const SettlementConfirmationScreen({
    super.key,
    required this.fromName,
    required this.fromAvatar,
    required this.toName,
    required this.toAvatar,
    required this.amount,
    this.initialPayerConfirmed = false,
    this.groupId,
    this.settlementId,
    this.currentUserId,
  });

  @override
  ConsumerState<SettlementConfirmationScreen> createState() =>
      _SettlementConfirmationScreenState();
}

class _SettlementConfirmationScreenState
    extends ConsumerState<SettlementConfirmationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  final currencyFormatter =
      NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);

  late bool _payerConfirmed; // Người chuyển bấm "Tôi đã chuyển khoản"
  bool _receiverConfirmed = false; // Người nhận bấm "Đã nhận tiền"
  bool _isLoading = false; // Đang gọi API

  final _repo = SettlementRepository();

  @override
  void initState() {
    super.initState();

    _payerConfirmed = widget.initialPayerConfirmed;

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
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
    final isFullyCompleted = _payerConfirmed && _receiverConfirmed;

    return Scaffold(
      backgroundColor: AppColors.n50,
      appBar: AppBar(
        backgroundColor: AppColors.n50,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.n0,
              shape: BoxShape.circle,
              boxShadow: AppDimensions.shadowSm,
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 16, color: AppColors.n800),
          ),
          onPressed: () => Navigator.pop(context, isFullyCompleted),
        ),
        title: Text('Xác nhận Thanh toán 2 Chiều',
            style: AppTypography.title.copyWith(fontSize: 16)),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.s20, vertical: AppDimensions.s12),
                child: Column(
                  children: [
                    // --- 1. CARD CHUYỂN TIỀN GIỮA 2 THÀNH VIÊN ---
                    _buildPayerToReceiverCard(),
                    const SizedBox(height: AppDimensions.s20),

                    // --- 2. MÃ QR THANH TOÁN VIETQR NGÂN HÀNG ---
                    _buildBankQrCodeCard(),
                    const SizedBox(height: AppDimensions.s20),

                    // --- 3. TIẾN TRÌNH XÁC NHẬN 2 CHIỀU (BE2-SET-02 STEPPER) ---
                    _buildTwoWayConfirmationStepperCard(),
                    const SizedBox(height: AppDimensions.s24),
                  ],
                ),
              ),
            ),

            // --- 4. BOTTOM ACTION BUTTONS ---
            _buildBottomConfirmationBar(context),
          ],
        ),
      ),
    );
  }

  // --- CARD CHUYỂN TIỀN GIỮA 2 THÀNH VIÊN ---
  Widget _buildPayerToReceiverCard() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.s20),
      decoration: BoxDecoration(
        color: AppColors.n0,
        borderRadius: AppDimensions.radius24,
        boxShadow: AppDimensions.shadowMd,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Người gửi
              Column(
                children: [
                  CircleAvatar(
                      radius: 28,
                      backgroundImage: NetworkImage(widget.fromAvatar)),
                  const SizedBox(height: 6),
                  Text(widget.fromName,
                      style: AppTypography.title.copyWith(fontSize: 14)),
                  Text('Người trả tiền', style: AppTypography.caption),
                ],
              ),

              // Icon mũi tên chuyển giao
              Column(
                children: [
                  const Icon(Icons.east_rounded,
                      color: AppColors.p500, size: 28),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.p50,
                      borderRadius: AppDimensions.radius8,
                    ),
                    child: Text('Tối ưu nợ',
                        style: AppTypography.caption.copyWith(
                            color: AppColors.p700,
                            fontSize: 10,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ),

              // Người nhận
              Column(
                children: [
                  CircleAvatar(
                      radius: 28,
                      backgroundImage: NetworkImage(widget.toAvatar)),
                  const SizedBox(height: 6),
                  Text(widget.toName,
                      style: AppTypography.title.copyWith(fontSize: 14)),
                  Text('Người nhận tiền', style: AppTypography.caption),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.s20),
          const Divider(height: 1, color: AppColors.n100),
          const SizedBox(height: AppDimensions.s16),
          Text('SỐ TIỀN THANH TOÁN',
              style: AppTypography.caption.copyWith(
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                  color: AppColors.n500)),
          const SizedBox(height: 4),
          Text(
            currencyFormatter.format(widget.amount),
            style: AppTypography.display.copyWith(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: AppColors.p500),
          ),
        ],
      ),
    );
  }

  // --- CARD VIETQR NGÂN HÀNG ---
  Widget _buildBankQrCodeCard() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.s20),
      decoration: BoxDecoration(
        color: AppColors.n0,
        borderRadius: AppDimensions.radius20,
        boxShadow: AppDimensions.shadowSm,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Quét mã VietQR chuyển khoản',
                  style: AppTypography.label.copyWith(fontSize: 14)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                    color: AppColors.infoTint,
                    borderRadius: AppDimensions.radius8),
                child: Text('MBBank',
                    style: AppTypography.caption.copyWith(
                        color: AppColors.info, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.s16),

          // Khung giả lập mã QR
          Container(
            padding: const EdgeInsets.all(AppDimensions.s16),
            decoration: BoxDecoration(
              color: AppColors.n50,
              borderRadius: AppDimensions.radius20,
              border: Border.all(color: AppColors.p200),
            ),
            child: Column(
              children: [
                const Icon(Icons.qr_code_2_rounded,
                    size: 160, color: AppColors.n900),
                const SizedBox(height: AppDimensions.s8),
                Text('STK: 190368889999 • MBBank',
                    style: AppTypography.bodySmall
                        .copyWith(fontWeight: FontWeight.w700)),
                Text('Chủ TK: ${widget.toName.toUpperCase()}',
                    style: AppTypography.caption),
                const SizedBox(height: 4),
                SelectableText(
                  'Nội dung: ${widget.fromName} chuyen tien SplitDebt',
                  style: AppTypography.caption.copyWith(
                      color: AppColors.p700, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- CARD TIẾN TRÌNH XÁC NHẬN 2 CHIỀU BE2-SET-02 ---
  Widget _buildTwoWayConfirmationStepperCard() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.s20),
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
              const Icon(Icons.fact_check_rounded,
                  color: AppColors.p500, size: 20),
              const SizedBox(width: AppDimensions.s8),
              Text('Tiến trình xác nhận 2 chiều (BE2-SET-02)',
                  style: AppTypography.label.copyWith(fontSize: 14)),
            ],
          ),
          const SizedBox(height: AppDimensions.s16),

          // Step 1: Payer
          _buildStepRow(
            stepNumber: '1',
            title: '${widget.fromName} (Người chuyển tiền)',
            subtitle: _payerConfirmed
                ? 'Đã bấm "Tôi đã chuyển khoản"'
                : 'Chưa bấm xác nhận đã chuyển',
            isDone: _payerConfirmed,
          ),

          const Padding(
            padding: EdgeInsets.only(left: 15),
            child: SizedBox(
                height: 20,
                child: VerticalDivider(thickness: 2, color: AppColors.n200)),
          ),

          // Step 2: Receiver
          _buildStepRow(
            stepNumber: '2',
            title: '${widget.toName} (Người nhận tiền)',
            subtitle: _receiverConfirmed
                ? 'Đã duyệt nhận đủ tiền -> Chốt sổ!'
                : 'Đang chờ người nhận duyệt tiền',
            isDone: _receiverConfirmed,
          ),
        ],
      ),
    );
  }

  Widget _buildStepRow({
    required String stepNumber,
    required String title,
    required String subtitle,
    required bool isDone,
  }) {
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: isDone ? AppColors.success : AppColors.n200,
          child: isDone
              ? const Icon(Icons.check, size: 16, color: Colors.white)
              : Text(stepNumber,
                  style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w700, color: AppColors.n700)),
        ),
        const SizedBox(width: AppDimensions.s12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: AppTypography.bodyMedium
                      .copyWith(fontWeight: FontWeight.w700)),
              Text(subtitle,
                  style: AppTypography.caption.copyWith(
                      color: isDone ? AppColors.success : AppColors.n500)),
            ],
          ),
        ),
      ],
    );
  }

  // --- STICKY BOTTOM ACTIONS ---
  Widget _buildBottomConfirmationBar(BuildContext context) {
    final isFullyCompleted = _payerConfirmed && _receiverConfirmed;

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.s20, vertical: AppDimensions.s16),
      decoration: BoxDecoration(
        color: AppColors.n0,
        boxShadow: AppDimensions.shadowLg,
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppDimensions.r24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isFullyCompleted) ...[
              if (!_payerConfirmed)
                ElevatedButton.icon(
                  onPressed: _isLoading
                      ? null
                      : () async {
                          HapticFeedback.mediumImpact();

                          // Gọi API nếu có đủ thông tin
                          if (widget.groupId != null &&
                              widget.settlementId != null &&
                              widget.currentUserId != null) {
                            setState(() => _isLoading = true);
                            try {
                              await _repo.markPaid(
                                groupId: widget.groupId!,
                                settlementId: widget.settlementId!,
                                debtorUserId: widget.currentUserId!,
                              );
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Lỗi: $e'),
                                    backgroundColor: AppColors.error,
                                    behavior: SnackBarBehavior.floating,
                                    margin: const EdgeInsets.only(
                                        bottom: 95, left: 16, right: 16),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: AppDimensions.radius12),
                                  ),
                                );
                              }
                              setState(() => _isLoading = false);
                              return;
                            }
                            setState(() => _isLoading = false);
                          }

                          setState(() {
                            _payerConfirmed = true;
                          });
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                    'Đã ghi nhận: Người trả bấm "Tôi đã chuyển khoản"!'),
                                backgroundColor: AppColors.warning,
                                behavior: SnackBarBehavior.floating,
                                margin: const EdgeInsets.only(
                                    bottom: 95, left: 16, right: 16),
                                duration: const Duration(seconds: 2),
                                shape: RoundedRectangleBorder(
                                    borderRadius: AppDimensions.radius12),
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.p500,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                        borderRadius: AppDimensions.radius16),
                  ),
                  icon: const Icon(Icons.send_rounded,
                      size: 20, color: Colors.white),
                  label: Text('Bước 1: Tôi đã chuyển khoản',
                      style: AppTypography.title
                          .copyWith(color: Colors.white, fontSize: 15)),
                ),
              if (_payerConfirmed && !_receiverConfirmed)
                ElevatedButton.icon(
                  onPressed: _isLoading
                      ? null
                      : () async {
                          HapticFeedback.mediumImpact();

                          // Gọi API confirm → backend gửi FCM cho người trả
                          if (widget.groupId != null &&
                              widget.settlementId != null &&
                              widget.currentUserId != null) {
                            setState(() => _isLoading = true);
                            try {
                              await _repo.confirmPaid(
                                groupId: widget.groupId!,
                                settlementId: widget.settlementId!,
                                creditorUserId: widget.currentUserId!,
                              );
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Lỗi: $e'),
                                    backgroundColor: AppColors.error,
                                    behavior: SnackBarBehavior.floating,
                                    margin: const EdgeInsets.only(
                                        bottom: 95, left: 16, right: 16),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: AppDimensions.radius12),
                                  ),
                                );
                              }
                              setState(() => _isLoading = false);
                              return;
                            }
                            setState(() => _isLoading = false);
                          }

                          setState(() {
                            _receiverConfirmed = true;
                          });
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Row(
                                  children: [
                                    Icon(Icons.check_circle_rounded,
                                        color: Colors.white),
                                    SizedBox(width: 8),
                                    Text(
                                        'Xác nhận 2 chiều thành công! Đã chốt sổ giao dịch.'),
                                  ],
                                ),
                                backgroundColor: AppColors.success,
                                behavior: SnackBarBehavior.floating,
                                margin: const EdgeInsets.only(
                                    bottom: 95, left: 16, right: 16),
                                duration: const Duration(seconds: 2),
                                shape: RoundedRectangleBorder(
                                    borderRadius: AppDimensions.radius12),
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                        borderRadius: AppDimensions.radius16),
                  ),
                  icon: const Icon(Icons.verified_rounded,
                      size: 20, color: Colors.white),
                  label: Text('Bước 2: Người nhận bấm "Đã nhận tiền"',
                      style: AppTypography.title
                          .copyWith(color: Colors.white, fontSize: 15)),
                ),
            ] else ...[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.successTint,
                  borderRadius: AppDimensions.radius16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.task_alt_rounded,
                        color: AppColors.success, size: 24),
                    const SizedBox(width: AppDimensions.s8),
                    Text('GIAO DỊCH ĐÃ THANH TOÁN THÀNH CÔNG!',
                        style: AppTypography.title
                            .copyWith(color: AppColors.success, fontSize: 14)),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                      borderRadius: AppDimensions.radius16),
                ),
                icon: const Icon(Icons.check_circle_outline_rounded,
                    color: Colors.white),
                label: Text('Hoàn tất & Quay lại',
                    style: AppTypography.title
                        .copyWith(color: Colors.white, fontSize: 15)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
