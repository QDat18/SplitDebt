import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import '../tool/vietreceipt_to_rows.dart';

void main() {
  test('polygonToOcrLine computes minX, minY, maxY from nested polygon', () {
    final line = polygonToOcrLine('Phở bò', [
      [120, 40],
      [280, 42],
      [280, 68],
      [118, 66],
    ]);

    expect(line, isNotNull);
    expect(line!.text, 'Phở bò');
    expect(line.left, 118);
    expect(line.top, 40);
    expect(line.bottom, 68);
  });

  test('polygonToOcrLine computes bounds from flat polygon list', () {
    final line = polygonToOcrLine('50.000', [300, 41, 380, 41, 380, 65, 300, 65]);
    expect(line, isNotNull);
    expect(line!.left, 300);
    expect(line.top, 41);
    expect(line.bottom, 65);
  });

  test('convertVietReceiptRecord skips unreadable regions and builds rows', () {
    const jsonl = '{"id":"sample_01","width":800,"height":1200,"split":"train","ocr":['
        '{"id":1,"polygon":[[50,10],[300,10],[300,40],[50,40]],"text":"QUÁN TEST","legibility":"readable"},'
        '{"id":2,"polygon":[[400,10],[500,10],[500,40],[400,40]],"text":"???","legibility":"unreadable"},'
        '{"id":3,"polygon":[[50,60],[200,60],[200,90],[50,90]],"text":"Cơm tấm","legibility":"readable"},'
        '{"id":4,"polygon":[[350,62],[450,62],[450,92],[350,92]],"text":"45.000","legibility":"readable"}'
        ']}';

    final record = jsonDecode(jsonl) as Map<String, dynamic>;
    final rows = convertVietReceiptRecord(record);

    expect(rows, ['QUÁN TEST', 'Cơm tấm  45.000']);
  });
}
