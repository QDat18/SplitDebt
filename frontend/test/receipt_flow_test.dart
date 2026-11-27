import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:split_debt/features/expenses/receipt/receipt_applier.dart';
import 'package:split_debt/features/expenses/receipt/receipt_flow.dart';
import 'package:split_debt/features/expenses/receipt/receipt_scanner.dart';

class _FakeScanner implements ReceiptScanner {
  final List<String>? result;
  _FakeScanner(this.result);

  @override
  Future<List<String>?> scan(ImageSource source) async => result;
}

void main() {
  testWidgets('cancelling image pick exits silently without SnackBar',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () {
                ReceiptFlow.run(
                  context,
                  hasExistingItems: false,
                  onScanningChanged: (_) {},
                  scanner: _FakeScanner(null),
                );
              },
              child: const Text('Scan'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Scan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chọn từ thư viện'));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('empty OCR rows still shows error SnackBar', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () {
                ReceiptFlow.run(
                  context,
                  hasExistingItems: false,
                  onScanningChanged: (_) {},
                  scanner: _FakeScanner(const []),
                );
              },
              child: const Text('Scan'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Scan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chọn từ thư viện'));
    await tester.pumpAndSettle();

    expect(
      find.text('Không đọc được chữ trên ảnh. Hãy chụp rõ hơn.'),
      findsOneWidget,
    );
  });

  testWidgets('total-only action returns totalOnly AppliedReceipt without items',
      (tester) async {
    AppliedReceipt? applied;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                applied = await ReceiptFlow.run(
                  context,
                  hasExistingItems: false,
                  onScanningChanged: (_) {},
                  scanner: _FakeScanner(const [
                    'SIÊU THỊ A',
                    'Sữa tươi  32.000',
                    'Tổng cộng  32.000',
                  ]),
                );
              },
              child: const Text('Scan'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Scan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chọn từ thư viện'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chỉ dùng tổng tiền'));
    await tester.pumpAndSettle();

    expect(applied, isNotNull);
    expect(applied!.totalOnly, isTrue);
    expect(applied!.items, isEmpty);
    expect(applied!.totalAmount, 32000);
    expect(applied!.title, 'SIÊU THỊ A');
  });
}
