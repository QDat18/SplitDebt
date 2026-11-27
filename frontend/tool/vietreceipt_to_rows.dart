// Chuyển đổi file annotations.jsonl của bộ VietReceipt OCR sang các file .rows.txt.
// Chạy: dart run tool/vietreceipt_to_rows.dart <annotations.jsonl> <out_dir> [--limit N]

import 'dart:convert';
import 'dart:io';

import 'package:split_debt/features/expenses/receipt/receipt_text_rows.dart';

OcrLine? polygonToOcrLine(String text, List<dynamic> polygon) {
  final trimmed = text.trim();
  if (trimmed.isEmpty || polygon.isEmpty) return null;

  double? minX;
  double? minY;
  double? maxY;

  void addPoint(num x, num y) {
    final xd = x.toDouble();
    final yd = y.toDouble();
    minX = minX == null || xd < minX! ? xd : minX;
    minY = minY == null || yd < minY! ? yd : minY;
    maxY = maxY == null || yd > maxY! ? yd : maxY;
  }

  if (polygon.first is List) {
    for (final pt in polygon) {
      if (pt is List && pt.length >= 2 && pt[0] is num && pt[1] is num) {
        addPoint(pt[0] as num, pt[1] as num);
      }
    }
  } else {
    for (var i = 0; i + 1 < polygon.length; i += 2) {
      if (polygon[i] is num && polygon[i + 1] is num) {
        addPoint(polygon[i] as num, polygon[i + 1] as num);
      }
    }
  }

  if (minX == null || minY == null || maxY == null) return null;
  return OcrLine(text: trimmed, top: minY!, bottom: maxY!, left: minX!);
}

List<String> convertVietReceiptRecord(Map<String, dynamic> record) {
  final ocrList = record['ocr'] as List<dynamic>? ?? const [];
  final lines = <OcrLine>[];
  for (final item in ocrList) {
    if (item is! Map<String, dynamic>) continue;
    if (item['legibility'] == 'unreadable') continue;
    final text = item['text'] as String? ?? '';
    final polygon = item['polygon'] as List<dynamic>? ?? const [];
    final line = polygonToOcrLine(text, polygon);
    if (line != null) lines.add(line);
  }
  return buildReceiptRows(lines);
}

void main(List<String> args) {
  if (args.length < 2) {
    stderr.writeln(
      'Usage: dart run tool/vietreceipt_to_rows.dart <annotations.jsonl> <out_dir> [--limit N]',
    );
    exitCode = 64;
    return;
  }

  final inputPath = args[0];
  final outDir = Directory(args[1]);
  int? limit;
  for (var i = 2; i + 1 < args.length; i++) {
    if (args[i] == '--limit') {
      limit = int.tryParse(args[i + 1]);
    }
  }

  final inputFile = File(inputPath);
  if (!inputFile.existsSync()) {
    stderr.writeln('File not found: $inputPath');
    exitCode = 66;
    return;
  }

  outDir.createSync(recursive: true);

  var count = 0;
  for (final rawLine in inputFile.readAsLinesSync()) {
    if (limit != null && count >= limit) break;
    final trimmed = rawLine.trim();
    if (trimmed.isEmpty) continue;
    final record = jsonDecode(trimmed) as Map<String, dynamic>;
    final id = (record['id'] ?? 'record_$count').toString();
    final safeId = id.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final rows = convertVietReceiptRecord(record);
    File('${outDir.path}${Platform.pathSeparator}$safeId.rows.txt')
        .writeAsStringSync('${rows.join('\n')}\n');
    count++;
  }

  stdout.writeln('Converted $count records to ${outDir.path}');
}
