// Trách nhiệm file: Màn hình xem trước kết quả quét hoá đơn (ReceiptPreviewSheet) theo chuẩn Apple HIG.

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import 'receipt_applier.dart';
import 'receipt_models.dart';

enum PreviewAction { rescan, use }

class ReceiptPreviewSheet extends StatelessWidget {
  final ParsedReceipt receipt;

  const ReceiptPreviewSheet({super.key, required this.receipt});

  String _formatVnd(int value) {
    final absVal = value.abs().toString();
    final buf = StringBuffer();
    for (var i = 0; i < absVal.length; i++) {
      if (i > 0 && (absVal.length - i) % 3 == 0) {
        buf.write('.');
      }
      buf.write(absVal[i]);
    }
    return '${buf.toString()}đ';
  }

  String _formatAdjustment(int amount) {
    final formatted = _formatVnd(amount);
    return amount >= 0 ? '+$formatted' : '-$formatted';
  }

  String _formatDate(DateTime date) {
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    return '$dd/$mm/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final applied = ReceiptApplier.apply(receipt, DateTime.now());
    final formTotal = applied.totalAmount;
    final storeSuffix =
        (receipt.storeName != null && receipt.storeName!.trim().isNotEmpty)
            ? ' · ${receipt.storeName!.trim()}'
            : '';

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.n100,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.s16,
            AppDimensions.s12,
            AppDimensions.s16,
            AppDimensions.s16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppDimensions.s12),
                  decoration: BoxDecoration(
                    color: AppColors.n300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Kết quả quét$storeSuffix',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.n900,
                ),
              ),
              if (receipt.receiptDate != null) ...[
                const SizedBox(height: AppDimensions.s4),
                Text(
                  _formatDate(receipt.receiptDate!),
                  style: textTheme.bodySmall?.copyWith(color: AppColors.n500),
                ),
              ],
              const SizedBox(height: AppDimensions.s12),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppDimensions.s14),
                        decoration: BoxDecoration(
                          color: AppColors.n0,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: AppDimensions.shadowSm,
                        ),
                        child: Column(
                          children: [
                            ...receipt.items.map((item) {
                              final label = item.quantity > 1
                                  ? '${item.name} x${item.quantity}'
                                  : item.name;
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppDimensions.s4,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        label,
                                        style: textTheme.bodyMedium?.copyWith(
                                          color: AppColors.n800,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: AppDimensions.s12),
                                    Text(
                                      _formatVnd(item.totalPrice),
                                      style: textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.n900,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            if (receipt.adjustments.isNotEmpty) ...[
                              const Divider(height: 16, color: AppColors.n200),
                              ...receipt.adjustments.map((adj) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: AppDimensions.s4,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          adj.label,
                                          style: textTheme.bodySmall?.copyWith(
                                            color: AppColors.n600,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: AppDimensions.s12),
                                      Text(
                                        _formatAdjustment(adj.amount),
                                        style: textTheme.bodySmall?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: adj.amount < 0
                                              ? AppColors.success
                                              : AppColors.n700,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                            const Divider(height: 16, color: AppColors.n200),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'TỔNG',
                                    style: textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.n900,
                                    ),
                                  ),
                                ),
                                Text(
                                  _formatVnd(formTotal),
                                  style: textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.p600,
                                  ),
                                ),
                              ],
                            ),
                            if (formTotal != receipt.totalAmount) ...[
                              const SizedBox(height: AppDimensions.s8),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Tổng in trên hoá đơn: ${_formatVnd(receipt.totalAmount)}. Có thể đã sót món, hãy kiểm tra.',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: AppColors.warning,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (receipt.warnings.isNotEmpty) ...[
                        const SizedBox(height: AppDimensions.s12),
                        Container(
                          padding: const EdgeInsets.all(AppDimensions.s12),
                          decoration: BoxDecoration(
                            color: AppColors.warningTint,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: receipt.warnings
                                .map(
                                  (w) => Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.warning_amber_rounded,
                                        size: 18,
                                        color: AppColors.warning,
                                      ),
                                      const SizedBox(width: AppDimensions.s8),
                                      Expanded(
                                        child: Text(
                                          w,
                                          style: textTheme.bodySmall?.copyWith(
                                            color: AppColors.n900,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ],
                      if (receipt.adjustments.isNotEmpty) ...[
                        const SizedBox(height: AppDimensions.s10),
                        Text(
                          'VAT/phí/giảm giá sẽ được chia theo tỉ lệ giá từng món.',
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.n600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.s14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          Navigator.of(context).pop(PreviewAction.rescan),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.n800,
                        side: const BorderSide(color: AppColors.n300),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Quét lại'),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.s12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () =>
                          Navigator.of(context).pop(PreviewAction.use),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.p500,
                        foregroundColor: AppColors.n0,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Dùng kết quả'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
