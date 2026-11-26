import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:split_debt/features/expenses/receipt/receipt_models.dart';
import 'package:split_debt/features/expenses/receipt/rule_based_receipt_parser.dart';

class _BucketStats {
  int receipts = 0;
  int unreadable = 0;
  int totalMatched = 0;
  int expectedItems = 0;
  int matchedItems = 0;
  int exactItemCount = 0;

  double get totalRate => receipts == 0 ? 1.0 : totalMatched / receipts;
  double get itemPriceRate =>
      expectedItems == 0 ? 1.0 : matchedItems / expectedItems;

  String formatReport(String label) {
    return '$label ($receipts receipts, unreadable=$unreadable): '
        'totalMatch=$totalMatched/$receipts (${(totalRate * 100).toStringAsFixed(1)}%), '
        'itemPriceMatch=$matchedItems/$expectedItems (${(itemPriceRate * 100).toStringAsFixed(1)}%), '
        'exactItemCount=$exactItemCount/$receipts';
  }
}

void main() {
  test('receipt fixtures accuracy gate', () {
    final sources = <String, Directory>{
      'receipts': Directory('test/fixtures/receipts'),
      'external/labeled': Directory('test/fixtures/external/labeled'),
    };

    final entries = <(String source, File file)>[];
    for (final entry in sources.entries) {
      if (!entry.value.existsSync()) continue;
      final files = entry.value
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.rows.txt'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
      for (final f in files) {
        entries.add((entry.key, f));
      }
    }

    if (entries.isEmpty) {
      markTestSkipped('Chưa có fixture hoá đơn thật');
      return;
    }

    final parser = RuleBasedReceiptParser();
    final overall = _BucketStats();
    final byType = <String, _BucketStats>{};
    final bySource = <String, _BucketStats>{};
    final failures = <String>[];

    for (final (source, rowFile) in entries) {
      final base = rowFile.path.replaceAll('.rows.txt', '');
      final expectedFile = File('$base.expected.json');
      expect(expectedFile.existsSync(), isTrue,
          reason: 'Thiếu file expected cho ${rowFile.path}');

      final rows = rowFile.readAsLinesSync();
      final expected =
          jsonDecode(expectedFile.readAsStringSync()) as Map<String, dynamic>;

      final receiptType = expected['type'] as String? ?? 'restaurant';
      expect(
        receiptType == 'restaurant' || receiptType == 'supermarket',
        isTrue,
        reason: 'Invalid type "$receiptType" in ${expectedFile.path}',
      );
      final typeBucket = byType.putIfAbsent(receiptType, _BucketStats.new);
      final sourceBucket = bySource.putIfAbsent(source, _BucketStats.new);

      final expectedTotal = (expected['totalAmount'] as num).toInt();
      final expectedItems = (expected['items'] as List<dynamic>)
          .cast<Map<String, dynamic>>();

      ParsedReceipt? parsed;
      try {
        parsed = parser.parse(rows);
      } on ReceiptUnreadable {
        parsed = null;
      }

      final isTotalMatch =
          parsed != null && parsed.totalAmount == expectedTotal;
      final isExactItemCount =
          parsed != null && parsed.items.length == expectedItems.length;

      var matchedInReceipt = 0;
      if (parsed != null) {
        final minLen = parsed.items.length < expectedItems.length
            ? parsed.items.length
            : expectedItems.length;
        for (var i = 0; i < minLen; i++) {
          final expPrice = (expectedItems[i]['totalPrice'] as num).toInt();
          if (parsed.items[i].totalPrice == expPrice) {
            matchedInReceipt++;
          }
        }

        final sumParsed =
            parsed.items.fold<int>(0, (s, item) => s + item.totalPrice) +
                parsed.adjustments.fold<int>(0, (s, adj) => s + adj.amount);
        if ((sumParsed - parsed.totalAmount).abs() > 1000) {
          expect(
            parsed.warnings,
            isNotEmpty,
            reason: 'Hoá đơn lệch tổng nhưng thiếu cảnh báo: ${rowFile.path}',
          );
        }
      }

      if (parsed == null || !isTotalMatch || matchedInReceipt < expectedItems.length) {
        final fileName = rowFile.uri.pathSegments.last;
        if (parsed == null) {
          failures.add('$fileName: ReceiptUnreadable (expected ${expectedItems.length} items, total=$expectedTotal)');
        } else {
          failures.add(
            '$fileName: total=${parsed.totalAmount} (exp $expectedTotal), '
            'items=${parsed.items.length} (exp ${expectedItems.length}), '
            'matchedPrices=$matchedInReceipt/${expectedItems.length}',
          );
        }
      }

      for (final stats in [overall, typeBucket, sourceBucket]) {
        stats.receipts++;
        if (parsed == null) stats.unreadable++;
        if (isTotalMatch) stats.totalMatched++;
        if (isExactItemCount) stats.exactItemCount++;
        stats.expectedItems += expectedItems.length;
        stats.matchedItems += matchedInReceipt;
      }
    }

    // ignore: avoid_print
    print(overall.formatReport('OCR Fixture Report [overall]'));
    for (final entry in bySource.entries) {
      // ignore: avoid_print
      print(entry.value.formatReport('OCR Fixture Report [source:${entry.key}]'));
    }
    for (final entry in byType.entries) {
      // ignore: avoid_print
      print(entry.value.formatReport('OCR Fixture Report [type:${entry.key}]'));
      if (entry.value.receipts >= 5) {
        expect(entry.value.totalRate, greaterThanOrEqualTo(0.80),
            reason: '${entry.key} totalMatch < 80%');
        expect(entry.value.itemPriceRate, greaterThanOrEqualTo(0.85),
            reason: '${entry.key} itemPriceMatch < 85%');
      }
    }
    if (failures.isNotEmpty) {
      // ignore: avoid_print
      print('Fixture mismatches:\n  ${failures.join('\n  ')}');
    }

    expect(overall.totalRate, greaterThanOrEqualTo(0.80));
    expect(overall.itemPriceRate, greaterThanOrEqualTo(0.85));
  });
}
