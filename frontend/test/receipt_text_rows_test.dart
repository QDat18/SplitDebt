import 'package:flutter_test/flutter_test.dart';
import 'package:split_debt/features/expenses/receipt/receipt_text_rows.dart';

void main() {
  test('lines with close centers merge left to right', () {
    final lines = [
      const OcrLine(text: '240.000', top: 102, bottom: 121, left: 300),
      const OcrLine(text: 'Bò', top: 100, bottom: 120, left: 10),
    ];

    expect(buildReceiptRows(lines), ['Bò  240.000']);
  });

  test('lines on different rows stay separate', () {
    final lines = [
      const OcrLine(text: 'Nước lẩu Thái', top: 140, bottom: 160, left: 10),
      const OcrLine(text: 'Thịt bò ba chỉ', top: 100, bottom: 120, left: 10),
      const OcrLine(text: '80.000', top: 141, bottom: 161, left: 300),
      const OcrLine(text: '240.000', top: 101, bottom: 121, left: 300),
    ];

    expect(buildReceiptRows(lines), [
      'Thịt bò ba chỉ  240.000',
      'Nước lẩu Thái  80.000',
    ]);
  });

  test('empty rows are dropped and limits applied', () {
    final lines = <OcrLine>[
      const OcrLine(text: '   ', top: 10, bottom: 20, left: 0),
    ];

    final longText = 'A' * 300;
    lines.add(OcrLine(text: longText, top: 40, bottom: 50, left: 0));

    for (var i = 1; i < 200; i++) {
      lines.add(OcrLine(
        text: 'Món $i',
        top: 60.0 + i * 30,
        bottom: 70.0 + i * 30,
        left: 0,
      ));
    }

    final rows = buildReceiptRows(lines);
    expect(rows.length, 150);
    expect(rows.first.length, 200);
  });

  test('OcrLine stores optional pure-Dart corners', () {
    const line = OcrLine(
      text: 'Phở bò',
      top: 10,
      bottom: 30,
      left: 5,
      corners: [
        OcrPoint(5, 10),
        OcrPoint(100, 10),
        OcrPoint(100, 30),
        OcrPoint(5, 30),
      ],
    );

    expect(line.corners, hasLength(4));
    expect(line.corners!.first.x, 5);
    expect(line.corners!.first.y, 10);
  });
}

