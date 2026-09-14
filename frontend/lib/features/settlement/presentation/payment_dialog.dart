import 'package:flutter/material.dart';
import '../../../core/theme/pdf_components.dart';
import '../data/settlement_api_service.dart';
import '../models/settlement_models.dart';

class PaymentDialog extends StatefulWidget {
  final int groupId, currentUserId;
  final SettlementRecord settlement;
  final VoidCallback onUpdated;
  const PaymentDialog(
      {super.key,
      required this.groupId,
      required this.currentUserId,
      required this.settlement,
      required this.onUpdated});
  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  String _method = 'BANK_TRANSFER';
  bool _busy = false, _done = false;
  Future<void> _submit(bool confirm) async {
    setState(() => _busy = true);
    try {
      final api = SettlementApiService();
      if (confirm) {
        await api.confirm(
            groupId: widget.groupId,
            settlementId: widget.settlement.id,
            creditorUserId: widget.currentUserId);
      } else {
        await api.markPaid(
            groupId: widget.groupId,
            settlementId: widget.settlement.id,
            debtorUserId: widget.currentUserId,
            paymentMethod: _method);
      }
      widget.onUpdated();
      if (mounted) setState(() => _done = true);
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Không thể cập nhật thanh toán: $error')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.settlement;
    final confirm = s.status == 'PAID' && s.creditorId == widget.currentUserId;
    final canPay = s.status == 'PENDING' && s.debtorId == widget.currentUserId;
    return PopScope(
        canPop: !_busy,
        child: Scaffold(
          appBar: AppBar(
              title: Text(_done
                  ? ''
                  : confirm
                      ? 'Xác nhận nhận tiền'
                      : 'Thanh toán')),
          body: ListView(
              padding: const EdgeInsets.all(20),
              children: _done
                  ? [
                      const SizedBox(height: 48),
                      const Center(
                          child: CircleAvatar(
                              radius: 46,
                              backgroundColor: Color(0xFFE7FBF1),
                              child: CircleAvatar(
                                  radius: 31,
                                  backgroundColor: Color(0xFF1CC66A),
                                  child: Icon(Icons.check,
                                      color: Colors.white, size: 36)))),
                      const SizedBox(height: 30),
                      Text(
                          confirm
                              ? 'Thanh toán hoàn tất!'
                              : 'Đã ghi nhận thanh toán!',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 25, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 12),
                      Text(
                          confirm
                              ? 'Bạn đã xác nhận nhận ${money(s.amount)} từ ${s.debtorName}.'
                              : 'Đã báo thanh toán ${money(s.amount)} cho ${s.creditorName}. Đang chờ người nhận xác nhận.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: pdfMuted)),
                      const SizedBox(height: 30),
                      Card(
                          child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Row(children: [
                                const Expanded(
                                    child: Text('Mã giao dịch',
                                        style: TextStyle(color: pdfMuted))),
                                Text('XN${s.id}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold))
                              ]))),
                    ]
                  : [
                      const SizedBox(height: 22),
                      Text(confirm ? 'Nhận tiền từ' : 'Thanh toán cho',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: pdfMuted)),
                      const SizedBox(height: 14),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            PersonBadge(confirm ? s.debtorName : s.creditorName,
                                color: pdfGreen),
                            const SizedBox(width: 12),
                            Flexible(
                                child: Text(
                                    confirm ? s.debtorName : s.creditorName,
                                    style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800)))
                          ]),
                      const SizedBox(height: 22),
                      Text(money(s.amount),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              color: pdfPurple)),
                      const SizedBox(height: 42),
                      if (canPay) ...[
                        const Text('PHƯƠNG THỨC THANH TOÁN',
                            style: TextStyle(
                                color: pdfMuted,
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                        const SizedBox(height: 12),
                        for (final e in const {
                          'CASH': 'Tiền mặt',
                          'BANK_TRANSFER': 'Chuyển khoản ngân hàng',
                          'MOMO': 'Ví MoMo',
                          'ZALOPAY': 'Ví ZaloPay',
                          'OTHER': 'Khác'
                        }.entries)
                          Card(
                              color: _method == e.key
                                  ? const Color(0xFFF0EDFF)
                                  : Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                      color: _method == e.key
                                          ? pdfPurple
                                          : const Color(0xFFE8E9EF))),
                              child: RadioListTile<String>(
                                  secondary: const CircleAvatar(
                                      radius: 16,
                                      backgroundColor: Color(0xFFF0EDFF)),
                                  value: e.key,
                                  groupValue: _method,
                                  controlAffinity:
                                      ListTileControlAffinity.trailing,
                                  activeColor: pdfPurple,
                                  onChanged: _busy
                                      ? null
                                      : (v) => setState(() => _method = v!),
                                  title: Text(e.value,
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600)))),
                        const SizedBox(height: 12),
                        const Text(
                            'Chọn “Đã thanh toán” sau khi bạn đã trả tiền mặt hoặc chuyển tiền bằng ứng dụng ngân hàng/ví.',
                            style: TextStyle(fontSize: 12, color: pdfMuted)),
                      ] else
                        Text(
                            confirm
                                ? 'Chỉ xác nhận khi bạn thực sự đã nhận tiền.'
                                : 'Giao dịch đang chờ tài khoản còn lại thực hiện bước tiếp theo.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: pdfMuted)),
                    ]),
          bottomNavigationBar: SafeArea(
              child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: FilledButton(
                      onPressed: _busy
                          ? null
                          : _done
                              ? () => Navigator.pop(context)
                              : canPay || confirm
                                  ? () => _submit(confirm)
                                  : () => Navigator.pop(context),
                      child: Text(_busy
                          ? 'Đang xử lý...'
                          : _done
                              ? 'Về quyết toán'
                              : confirm
                                  ? 'Xác nhận đã nhận tiền'
                                  : canPay
                                      ? 'Đã thanh toán'
                                      : 'Đóng')))),
        ));
  }
}
