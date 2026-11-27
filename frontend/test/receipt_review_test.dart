import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:split_debt/features/expenses/ocr/receipt_scan.dart';

void main() {
  for (final width in [320.0, 600.0, 1200.0]) {
    testWidgets('receipt review fits ${width.toInt()}px and large text', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.4)),
            child: child!,
          ),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => reviewReceipt(
                  context,
                  ReceiptDraft(
                    90000,
                    [
                      const ReceiptLine(
                        'Cơm gà với tên món dài để kiểm tra xuống dòng',
                        2,
                        45000,
                      ),
                    ],
                    DateTime(2026, 11, 26),
                    'Cửa hàng mẫu',
                    'QR',
                  ),
                ),
                child: const Text('Open review'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open review'));
      await tester.pumpAndSettle();
      expect(find.text('Kiểm tra hóa đơn'), findsOneWidget);
      expect(find.text('Sử dụng hóa đơn'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('review requires explicit confirmation before returning data', (
    tester,
  ) async {
    ReceiptDraft? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await reviewReceipt(
                  context,
                  ReceiptDraft(
                    90000,
                    [],
                    DateTime(2026, 11, 26),
                    'Quán cơm',
                    'QR',
                  ),
                );
              },
              child: const Text('Open review'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open review'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sử dụng hóa đơn'));
    await tester.pumpAndSettle();
    expect(result, isNull);
    expect(find.text('Kiểm tra hóa đơn'), findsOneWidget);
    final checkbox = find.byType(CheckboxListTile);
    await tester.ensureVisible(checkbox);
    await tester.tap(checkbox);
    await tester.pump();
    await tester.tap(find.text('Sử dụng hóa đơn'));
    await tester.pumpAndSettle();
    expect(result?.total, 90000);
    expect(result?.items, isEmpty);
  });
}
