// Trách nhiệm file: Màn hình xác nhận thanh toán hai bước chuẩn Fintech, có xác nhận trước khi gửi, hỗ trợ Light & Dark mode.

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../core/network/network_error.dart';
import '../../../core/state/app_sync.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/pdf_components.dart';
import '../../../core/widgets/fintech_components.dart';
import '../../../core/widgets/premium_shell.dart';
import '../data/settlement_api_service.dart';
import '../models/settlement_models.dart';

class PaymentDialog extends StatefulWidget {
  final int groupId, currentUserId;
  final SettlementRecord settlement;
  final VoidCallback onUpdated;

  const PaymentDialog({
    super.key,
    required this.groupId,
    required this.currentUserId,
    required this.settlement,
    required this.onUpdated,
  });

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  String _method = 'BANK_TRANSFER';
  bool _busy = false;
  bool _done = false;

  Future<void> _confirmAndSubmit(bool confirm) async {
    if (_busy) return;
    final s = widget.settlement;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          confirm
              ? tr(ctx, 'Xác nhận đã nhận tiền?', 'Confirm money received?')
              : tr(ctx, 'Xác nhận đã thanh toán?', 'Confirm payment sent?'),
        ),
        content: Text(
          confirm
              ? tr(
                  ctx,
                  'Bạn xác nhận đã thực sự nhận đủ ${money(s.amount)} từ ${s.debtorName}? Công nợ nhóm sẽ được cập nhật.',
                  'Confirm you have received ${money(s.amount)} from ${s.debtorName}? Group balances will be updated.',
                )
              : tr(
                  ctx,
                  'Báo đã chuyển ${money(s.amount)} cho ${s.creditorName}. Công nợ chỉ trừ khi người nhận xác nhận.',
                  'Report ${money(s.amount)} sent to ${s.creditorName}. Balances update only after recipient confirms.',
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr(ctx, 'Hủy', 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr(ctx, 'Xác nhận', 'Confirm')),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await _submit(confirm);
  }

  Future<void> _submit(bool confirm) async {
    setState(() => _busy = true);
    try {
      final api = SettlementApiService();
      if (confirm) {
        await api.confirm(
          groupId: widget.groupId,
          settlementId: widget.settlement.id,
        );
      } else {
        await api.markPaid(
          groupId: widget.groupId,
          settlementId: widget.settlement.id,
          paymentMethod: _method,
        );
      }
      notifyDataChanged();
      widget.onUpdated();
      if (mounted) setState(() => _done = true);
    } catch (error) {
      if (mounted) {
        final msg = error is DioException
            ? networkErrorMessage(error)
            : tr(
                context,
                'Không thể cập nhật thanh toán. Vui lòng thử lại.',
                'Could not update settlement. Please try again.',
              );
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  IconData _methodIcon(String key) => switch (key) {
    'CASH' => Icons.payments_outlined,
    'BANK_TRANSFER' => Icons.account_balance_outlined,
    'MOMO' => Icons.account_balance_wallet_outlined,
    'ZALOPAY' => Icons.qr_code_2_rounded,
    _ => Icons.more_horiz_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final successColor = AppColors.successFor(context);
    final s = widget.settlement;
    final confirm = s.status == 'PAID' && s.creditorId == widget.currentUserId;
    final canPay = s.status == 'PENDING' && s.debtorId == widget.currentUserId;

    final methods = <String, String>{
      'BANK_TRANSFER': tr(context, 'Chuyển khoản ngân hàng', 'Bank transfer'),
      'CASH': tr(context, 'Tiền mặt', 'Cash'),
      'MOMO': tr(context, 'Ví MoMo', 'MoMo Wallet'),
      'ZALOPAY': tr(context, 'Ví ZaloPay', 'ZaloPay Wallet'),
      'OTHER': tr(context, 'Khác', 'Other'),
    };

    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _done
                ? ''
                : confirm
                ? tr(context, 'Xác nhận nhận tiền', 'Confirm receipt')
                : tr(context, 'Thanh toán', 'Payment'),
          ),
        ),
        body: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.all(AppDimensions.s20),
              children: _done
                  ? [
                      const SizedBox(height: 36),
                      Center(
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: successColor.withValues(alpha: 0.14),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check_rounded,
                            color: successColor,
                            size: 38,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppDimensions.s24),
                      Text(
                        confirm
                            ? tr(
                                context,
                                'Thanh toán hoàn tất',
                                'Payment confirmed',
                              )
                            : tr(
                                context,
                                'Đã ghi nhận thanh toán',
                                'Payment reported',
                              ),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: AppDimensions.s8),
                      Text(
                        confirm
                            ? tr(
                                context,
                                'Bạn đã xác nhận nhận ${money(s.amount)} từ ${s.debtorName}.',
                                'You confirmed receiving ${money(s.amount)} from ${s.debtorName}.',
                              )
                            : tr(
                                context,
                                'Đã báo thanh toán ${money(s.amount)} cho ${s.creditorName}. Đang chờ người nhận xác nhận.',
                                'Reported ${money(s.amount)} paid to ${s.creditorName}. Waiting for recipient confirmation.',
                              ),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.s24),
                      PremiumSurface(
                        radius: AppDimensions.r12,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                tr(context, 'Mã giao dịch', 'Reference ID'),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                            Text(
                              'XN${s.id}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ]
                  : [
                      PremiumSurface(
                        padding: const EdgeInsets.all(AppDimensions.s20),
                        child: Column(
                          children: [
                            Text(
                              confirm
                                  ? tr(
                                      context,
                                      'Nhận tiền từ',
                                      'Receiving from',
                                    )
                                  : tr(context, 'Thanh toán cho', 'Paying to'),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: AppDimensions.s12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                PersonBadge(
                                  confirm ? s.debtorName : s.creditorName,
                                  color: confirm
                                      ? successColor
                                      : scheme.primary,
                                ),
                                const SizedBox(width: 10),
                                Flexible(
                                  child: Text(
                                    confirm ? s.debtorName : s.creditorName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppDimensions.s16),
                            Text(
                              money(s.amount),
                              style: TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w700,
                                color: scheme.primary,
                                letterSpacing: -0.8,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppDimensions.s24),
                      if (canPay) ...[
                        SectionLabel(
                          title: tr(
                            context,
                            'Phương thức thanh toán',
                            'Payment method',
                          ),
                        ),
                        const SizedBox(height: AppDimensions.s8),
                        PremiumSurface(
                          padding: EdgeInsets.zero,
                          radius: AppDimensions.r12,
                          child: Column(
                            children: [
                              for (int i = 0; i < methods.length; i++) ...[
                                _methodRow(
                                  methods.entries.elementAt(i).key,
                                  methods.entries.elementAt(i).value,
                                  scheme,
                                ),
                                if (i < methods.length - 1)
                                  const Divider(height: 1, indent: 56),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: AppDimensions.s12),
                        Text(
                          tr(
                            context,
                            'Chỉ chọn "Đã thanh toán" sau khi bạn đã trả tiền mặt hoặc chuyển khoản thành công.',
                            'Select "Mark as paid" only after you have completed the transfer or cash payment.',
                          ),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ] else
                        PremiumSurface(
                          radius: AppDimensions.r12,
                          child: Text(
                            confirm
                                ? tr(
                                    context,
                                    'Chỉ xác nhận khi bạn đã thực sự nhận đủ số tiền trên.',
                                    'Confirm only after you have actually received the full amount.',
                                  )
                                : tr(
                                    context,
                                    'Giao dịch đang chờ tài khoản còn lại thực hiện bước tiếp theo.',
                                    'Waiting for the other party to complete the next step.',
                                  ),
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ),
                    ],
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.s16),
            child: FilledButton(
              onPressed: _busy
                  ? null
                  : _done
                  ? () => Navigator.pop(context)
                  : (canPay || confirm)
                  ? () => _confirmAndSubmit(confirm)
                  : () => Navigator.pop(context),
              child: Text(
                _busy
                    ? tr(context, 'Đang xử lý...', 'Processing...')
                    : _done
                    ? tr(context, 'Xong', 'Done')
                    : confirm
                    ? tr(context, 'Xác nhận đã nhận tiền', 'Confirm receipt')
                    : canPay
                    ? tr(context, 'Đã thanh toán', 'Mark as paid')
                    : tr(context, 'Đóng', 'Close'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _methodRow(String key, String label, ColorScheme scheme) {
    final selected = _method == key;
    return ListTile(
      enabled: !_busy,
      onTap: () => setState(() => _method = key),
      leading: Icon(
        _methodIcon(key),
        color: selected ? scheme.primary : scheme.onSurfaceVariant,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 15,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          color: scheme.onSurface,
        ),
      ),
      trailing: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: selected ? scheme.primary : scheme.onSurfaceVariant,
      ),
    );
  }
}
