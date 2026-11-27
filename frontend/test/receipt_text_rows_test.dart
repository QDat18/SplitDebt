import 'dart:math' as math;
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

  test('deskewLines restores 90, 180, 270 and 12 degree rotated receipts', () {
    OcrLine makeBox(String text, double x, double y, double w, double h) {
      return OcrLine(
        text: text,
        top: y,
        bottom: y + h,
        left: x,
        corners: [
          OcrPoint(x, y),
          OcrPoint(x + w, y),
          OcrPoint(x + w, y + h),
          OcrPoint(x, y + h),
        ],
      );
    }

    OcrLine rotateLine(OcrLine line, double deg) {
      final rad = deg * math.pi / 180.0;
      final c = math.cos(rad);
      final s = math.sin(rad);
      final rotatedCorners = line.corners!.map((p) {
        return OcrPoint(p.x * c - p.y * s, p.x * s + p.y * c);
      }).toList();
      final ys = rotatedCorners.map((p) => p.y);
      final xs = rotatedCorners.map((p) => p.x);
      return OcrLine(
        text: line.text,
        top: ys.reduce(math.min),
        bottom: ys.reduce(math.max),
        left: xs.reduce(math.min),
        corners: rotatedCorners,
      );
    }

    final upright = [
      makeBox('QUÁN BÚN BÒ', 20, 20, 180, 20),
      makeBox('12/10/2026', 250, 20, 100, 20),
      makeBox('Bún bò đặc biệt', 20, 60, 180, 20),
      makeBox('65.000', 260, 60, 80, 20),
      makeBox('Trà đá chanh', 20, 100, 160, 20),
      makeBox('10.000', 260, 100, 80, 20),
      makeBox('Bánh quẩy', 20, 140, 140, 20),
      makeBox('15.000', 260, 140, 80, 20),
      makeBox('Tổng cộng', 20, 180, 140, 20),
      makeBox('90.000', 260, 180, 80, 20),
    ];

    final expected = buildReceiptRows(upright);
    expect(expected, [
      'QUÁN BÚN BÒ  12/10/2026',
      'Bún bò đặc biệt  65.000',
      'Trà đá chanh  10.000',
      'Bánh quẩy  15.000',
      'Tổng cộng  90.000',
    ]);

    for (final deg in [90.0, 180.0, 270.0, 12.0]) {
      final rotated = upright.map((l) => rotateLine(l, deg)).toList();
      expect(
        buildReceiptRows(rotated),
        expected,
        reason: 'Failed at rotation $deg degrees',
      );
    }
  });

  test('deskewLines skips rotation when fewer than 3 lines have corners', () {
    final lines = [
      const OcrLine(
        text: 'Hàng 1',
        top: 10,
        bottom: 100,
        left: 50,
        corners: [
          OcrPoint(50, 10),
          OcrPoint(50, 100),
          OcrPoint(30, 100),
          OcrPoint(30, 10),
        ],
      ),
      const OcrLine(
        text: 'Hàng 2',
        top: 10,
        bottom: 100,
        left: 90,
        corners: [
          OcrPoint(90, 10),
          OcrPoint(90, 100),
          OcrPoint(70, 100),
          OcrPoint(70, 10),
        ],
      ),
    ];

    final result = deskewLines(lines);
    expect(result[0].top, 10);
    expect(result[0].left, 50);
  });
}

