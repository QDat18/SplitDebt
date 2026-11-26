import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:split_debt/features/expenses/receipt/receipt_models.dart';
import 'package:split_debt/features/expenses/receipt/receipt_preview_sheet.dart';

void main() {
  testWidgets('shows store, date, items, adjustments and total',
      (tester) async {
    final parsed = ParsedReceipt(
      storeName: 'Nhà hàng ABC',
      receiptDate: DateTime(2026, 10, 7),
      items: const [
        ParsedItem(name: 'Thịt bò ba chỉ', quantity: 2, totalPrice: 240000),
        ParsedItem(name: 'Nước lẩu Thái', quantity: 1, totalPrice: 80000),
      ],
      adjustments: const [
        ParsedAdjustment(type: AdjustmentType.vat, label: 'VAT 8%', amount: 25600),
        ParsedAdjustment(
            type: AdjustmentType.discount, label: 'Giảm giá', amount: -10000),
      ],
      totalAmount: 335600,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReceiptPreviewSheet(receipt: parsed),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Nhà hàng ABC'), findsOneWidget);
    expect(find.text('07/10/2026'), findsOneWidget);
    expect(find.text('Thịt bò ba chỉ x2'), findsOneWidget);
    expect(find.text('Nước lẩu Thái'), findsOneWidget);
    expect(find.text('VAT 8%'), findsOneWidget);
    expect(find.text('Giảm giá'), findsOneWidget);
    expect(find.text('335.600đ'), findsOneWidget);
  });

  testWidgets('shows warnings when present', (tester) async {
    const parsed = ParsedReceipt(
      items: [ParsedItem(name: 'Món A', quantity: 1, totalPrice: 100000)],
      totalAmount: 120000,
      warnings: ['Tổng các món lệch 20.000đ so với tổng hoá đơn. Hãy kiểm tra lại.'],
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ReceiptPreviewSheet(receipt: parsed),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Tổng các món lệch 20.000đ so với tổng hoá đơn. Hãy kiểm tra lại.'),
      findsOneWidget,
    );
  });

  testWidgets('shows allocation note only when adjustments exist',
      (tester) async {
    const noAdj = ParsedReceipt(
      items: [ParsedItem(name: 'Món A', quantity: 1, totalPrice: 100000)],
      totalAmount: 100000,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ReceiptPreviewSheet(receipt: noAdj),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('VAT/phí/giảm giá sẽ được chia theo tỉ lệ giá từng món.'),
      findsNothing,
    );

    const withAdj = ParsedReceipt(
      items: [ParsedItem(name: 'Món A', quantity: 1, totalPrice: 100000)],
      adjustments: [
        ParsedAdjustment(type: AdjustmentType.vat, label: 'VAT', amount: 8000),
      ],
      totalAmount: 108000,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ReceiptPreviewSheet(receipt: withAdj),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('VAT/phí/giảm giá sẽ được chia theo tỉ lệ giá từng món.'),
      findsOneWidget,
    );
  });

  testWidgets('buttons return rescan / use result', (tester) async {
    const parsed = ParsedReceipt(
      items: [ParsedItem(name: 'Món A', quantity: 1, totalPrice: 100000)],
      totalAmount: 100000,
    );

    PreviewAction? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                result = await showModalBottomSheet<PreviewAction>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => const ReceiptPreviewSheet(receipt: parsed),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Quét lại'));
    await tester.pumpAndSettle();
    expect(result, PreviewAction.rescan);

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dùng kết quả'));
    await tester.pumpAndSettle();
    expect(result, PreviewAction.use);
  });

  testWidgets('total shown equals amount applied to form', (tester) async {
    const parsed = ParsedReceipt(
      items: [
        ParsedItem(name: 'Món 1', quantity: 1, totalPrice: 100000),
        ParsedItem(name: 'Món 2', quantity: 1, totalPrice: 150000),
      ],
      adjustments: [
        ParsedAdjustment(type: AdjustmentType.vat, label: 'VAT', amount: 20000),
      ],
      totalAmount: 300000,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ReceiptPreviewSheet(receipt: parsed),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('270.000đ'), findsOneWidget);
  });

  testWidgets('printed total shown when different', (tester) async {
    const parsed = ParsedReceipt(
      items: [
        ParsedItem(name: 'Món 1', quantity: 1, totalPrice: 100000),
      ],
      totalAmount: 150000,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ReceiptPreviewSheet(receipt: parsed),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Tổng in trên hoá đơn: 150.000đ. Có thể đã sót món, hãy kiểm tra.'),
      findsOneWidget,
    );
  });

  testWidgets('shows message when oversized discount is skipped',
      (tester) async {
    const parsed = ParsedReceipt(
      items: [
        ParsedItem(name: 'Món 1', quantity: 1, totalPrice: 150000),
      ],
      adjustments: [
        ParsedAdjustment(
          type: AdjustmentType.discount,
          label: 'Voucher',
          amount: -200000,
        ),
      ],
      totalAmount: 150000,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ReceiptPreviewSheet(receipt: parsed),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Không áp được giảm giá/phụ phí, hãy kiểm tra lại.'),
      findsOneWidget,
    );
  });

  testWidgets('no printed-total warning within 1000', (tester) async {
    const parsed = ParsedReceipt(
      items: [
        ParsedItem(name: 'Món 1', quantity: 1, totalPrice: 100000),
      ],
      totalAmount: 100500,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ReceiptPreviewSheet(receipt: parsed),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Tổng in trên hoá đơn:'),
      findsNothing,
    );
  });

  testWidgets('only adjustment warning when skipped', (tester) async {
    const parsed = ParsedReceipt(
      items: [
        ParsedItem(name: 'Món 1', quantity: 1, totalPrice: 150000),
      ],
      adjustments: [
        ParsedAdjustment(
          type: AdjustmentType.discount,
          label: 'Voucher',
          amount: -200000,
        ),
      ],
      totalAmount: 50000,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ReceiptPreviewSheet(receipt: parsed),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Không áp được giảm giá/phụ phí, hãy kiểm tra lại.'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Có thể đã sót món'),
      findsNothing,
    );
  });
}
