import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'receipt_data.dart';

Future<void> printReceipt(ReceiptDraft receipt) async {
  final font = await PdfGoogleFonts.notoSansRegular();
  final bold = await PdfGoogleFonts.notoSansBold();
  final money = NumberFormat.decimalPattern('vi_VN');
  String fmt(int value) => '${money.format(value)} VND';
  final doc = pw.Document();
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      theme: pw.ThemeData.withFont(base: font, bold: bold),
      build: (_) => [
        pw.Text(
          'SPLITDEBT | PHIẾU ĐỐI CHIẾU HÓA ĐƠN',
          style: pw.TextStyle(font: bold, fontSize: 17),
        ),
        pw.SizedBox(height: 12),
        pw.Text(
          'Cửa hàng: ${receipt.merchant.isEmpty ? "Chưa xác định" : receipt.merchant}',
        ),
        pw.Text('Ngày chi: ${DateFormat('dd/MM/yyyy').format(receipt.date)}'),
        pw.Text('Nguồn: ${receipt.source}'),
        pw.SizedBox(height: 16),
        if (receipt.items.isNotEmpty)
          pw.TableHelper.fromTextArray(
            headers: ['Tên hàng', 'SL', 'Đơn giá', 'Thành tiền'],
            data: receipt.items
                .map(
                  (i) => [
                    i.name,
                    '${i.quantity}',
                    fmt(i.unitPrice),
                    fmt(i.amount),
                  ],
                )
                .toList(),
            headerStyle: pw.TextStyle(font: bold),
            cellAlignments: {
              1: pw.Alignment.centerRight,
              2: pw.Alignment.centerRight,
              3: pw.Alignment.centerRight,
            },
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(1),
              2: const pw.FlexColumnWidth(2),
              3: const pw.FlexColumnWidth(2),
            },
          )
        else
          pw.Text('Không có chi tiết hàng hóa.'),
        pw.SizedBox(height: 16),
        if (receipt.items.isNotEmpty) ...[
          pw.Text('Tổng tiền hàng: ${fmt(receipt.subtotal)}'),
          if (receipt.subtotal != receipt.total)
            pw.Text(
              'Chênh lệch (thuế/giảm giá hoặc dữ liệu chưa khớp): ${fmt(receipt.total - receipt.subtotal)}',
            ),
        ],
        pw.Text(
          'Tổng thanh toán: ${fmt(receipt.total)}',
          style: pw.TextStyle(font: bold, fontSize: 15),
        ),
        pw.SizedBox(height: 18),
        pw.Text(
          'Bản trích xuất do người dùng đối chiếu. Không thay thế hóa đơn gốc hoặc chứng từ thanh toán.',
          style: const pw.TextStyle(fontSize: 10),
        ),
      ],
    ),
  );
  await Printing.layoutPdf(
    name: 'SplitDebt-receipt.pdf',
    onLayout: (_) => doc.save(),
  );
}
