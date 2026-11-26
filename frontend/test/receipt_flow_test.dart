import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
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
}
