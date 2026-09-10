import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/settlement_api_service.dart';
import '../models/settlement_models.dart';

class PaymentDialog
    extends StatefulWidget {
  final int groupId;

  final int currentUserId;

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
  State<PaymentDialog> createState() =>
      _PaymentDialogState();
}

class _PaymentDialogState
    extends State<PaymentDialog> {
  final _api =
  SettlementApiService();

  String _method =
      'BANK_TRANSFER';

  bool _loading = false;

  String _money(double value) {
    return NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    ).format(value);
  }

  Future<void> _pay() async {
    setState(
          () => _loading = true,
    );

    try {
      await _api.markPaid(
        groupId:
        widget.groupId,

        settlementId:
        widget.settlement.id,

        debtorUserId:
        widget.currentUserId,

        paymentMethod:
        _method,
      );

      if (!mounted) {
        return;
      }

      Navigator.pop(context);

      widget.onUpdated();

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Đã ghi nhận thanh toán, '
                'đang chờ người nhận xác nhận.',
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              'Không thể ghi nhận thanh toán: $e',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(
              () => _loading = false,
        );
      }
    }
  }

  Future<void> _confirm() async {
    setState(
          () => _loading = true,
    );

    try {
      await _api.confirm(
        groupId:
        widget.groupId,

        settlementId:
        widget.settlement.id,

        creditorUserId:
        widget.currentUserId,
      );

      if (!mounted) {
        return;
      }

      Navigator.pop(context);

      widget.onUpdated();

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Đã xác nhận nhận tiền. '
                'Giao dịch hoàn tất.',
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              'Không thể xác nhận: $e',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(
              () => _loading = false,
        );
      }
    }
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    final settlement =
        widget.settlement;

    final isDebtor =
        settlement.debtorId ==
            widget.currentUserId;

    final isCreditor =
        settlement.creditorId ==
            widget.currentUserId;

    return AlertDialog(
      title: Text(
        settlement.status == 'PAID'
            ? 'Xác nhận đã nhận tiền'
            : 'Ghi nhận thanh toán',
      ),

      content: SingleChildScrollView(
        child: Column(
          mainAxisSize:
          MainAxisSize.min,

          crossAxisAlignment:
          CrossAxisAlignment.start,

          children: [
            Text(
              '${settlement.debtorName} '
                  '→ '
                  '${settlement.creditorName}',

              style: const TextStyle(
                fontWeight:
                FontWeight.w700,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            Text(
              _money(
                settlement.amount,
              ),

              style:
              Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(
                fontWeight:
                FontWeight.bold,
              ),
            ),

            if (
            isDebtor &&
                settlement.status ==
                    'PENDING'
            ) ...[
              const SizedBox(
                height: 16,
              ),

              const Text(
                'Phương thức thanh toán',
              ),

              ...const {
                'CASH':
                'Tiền mặt',

                'BANK_TRANSFER':
                'Chuyển khoản ngân hàng',

                'MOMO':
                'MoMo',

                'ZALOPAY':
                'ZaloPay',

                'OTHER':
                'Khác',
              }.entries.map(
                    (entry) =>
                    RadioListTile<String>(
                      contentPadding:
                      EdgeInsets.zero,

                      dense: true,

                      value:
                      entry.key,

                      groupValue:
                      _method,

                      title:
                      Text(
                        entry.value,
                      ),

                      onChanged:
                          (value) {
                        setState(
                              () =>
                          _method =
                          value!,
                        );
                      },
                    ),
              ),

              const Text(
                'Ứng dụng chỉ ghi nhận giao dịch '
                    'đã thực hiện bên ngoài hệ thống.',
                style: TextStyle(
                  fontSize: 12,
                ),
              ),
            ],

            if (
            isCreditor &&
                settlement.status ==
                    'PAID'
            ) ...[
              const SizedBox(
                height: 16,
              ),

              const Text(
                'Người trả đã đánh dấu thanh toán. '
                    'Chỉ xác nhận khi bạn thực sự đã nhận tiền.',
              ),
            ],
          ],
        ),
      ),

      actions: [
        TextButton(
          onPressed:
          _loading
              ? null
              : () =>
              Navigator.pop(
                context,
              ),

          child:
          const Text(
            'Đóng',
          ),
        ),

        if (
        isDebtor &&
            settlement.status ==
                'PENDING'
        )
          FilledButton(
            onPressed:
            _loading
                ? null
                : _pay,

            child: Text(
              _loading
                  ? 'Đang xử lý...'
                  : 'Đã thanh toán',
            ),
          ),

        if (
        isCreditor &&
            settlement.status ==
                'PAID'
        )
          FilledButton(
            onPressed:
            _loading
                ? null
                : _confirm,

            child: Text(
              _loading
                  ? 'Đang xử lý...'
                  : 'Xác nhận đã nhận tiền',
            ),
          ),
      ],
    );
  }
}