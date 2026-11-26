import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:split_debt/features/expenses/receipt/rule_based_receipt_parser.dart';

class _BucketStats {
  int receipts = 0;
  int totalMatched = 0;
  int expectedItems = 0;
  int matchedItems = 0;
  int exactItemCount = 0;

  double get totalRate => receipts == 0 ? 1.0 : totalMatched / receipts;
  double get itemPriceRate =>
      expectedItems == 0 ? 1.0 : matchedItems / expectedItems;

  String formatReport(String label) {
    return '$label ($receipts receipts): '
        'totalMatch=$totalMatched/$receipts (${(totalRate * 100).toStringAsFixed(1)}%), '
        'itemPriceMatch=$matchedItems/$expectedItems (${(itemPriceRate * 100).toStringAsFixed(1)}%), '
        'exactItemCount=$exactItemCount/$receipts';
  }
}

void main() {
  test('receipt fixtures accuracy gate', () {
    final dir = Directory('test/fixtures/receipts');
    final rowFiles = dir.existsSync()
        ? (dir
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.rows.txt'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path)))
        : <File>[];

    if (rowFiles.isEmpty) {
      markTestSkipped('Chưa có fixture hoá đơn thật');
      return;
    }

    final parser = RuleBasedReceiptParser();
    final overall = _BucketStats();
    final byType = <String, _BucketStats>{};

    for (final rowFile in rowFiles) {
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
      final bucket = byType.putIfAbsent(receiptType, _BucketStats.new);

      final parsed = parser.parse(rows);
      final expectedTotal = (expected['totalAmount'] as num).toInt();
      final expectedItems = (expected['items'] as List<dynamic>)
          .cast<Map<String, dynamic>>();

      final isTotalMatch = parsed.totalAmount == expectedTotal;
      final isExactItemCount = parsed.items.length == expectedItems.length;

      var matchedInReceipt = 0;
      final minLen = parsed.items.length < expectedItems.length
          ? parsed.items.length
          : expectedItems.length;
      for (var i = 0; i < minLen; i++) {
        final expPrice = (expectedItems[i]['totalPrice'] as num).toInt();
        if (parsed.items[i].totalPrice == expPrice) {
          matchedInReceipt++;
        }
      }

      for (final stats in [overall, bucket]) {
        stats.receipts++;
        if (isTotalMatch) stats.totalMatched++;
        if (isExactItemCount) stats.exactItemCount++;
        stats.expectedItems += expectedItems.length;
        stats.matchedItems += matchedInReceipt;
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

    // ignore: avoid_print
    print(overall.formatReport('OCR Fixture Report [overall]'));
    for (final entry in byType.entries) {
      // ignore: avoid_print
      print(entry.value.formatReport('OCR Fixture Report [${entry.key}]'));
      if (entry.value.receipts >= 5) {
        expect(entry.value.totalRate, greaterThanOrEqualTo(0.80),
            reason: '${entry.key} totalMatch < 80%');
        expect(entry.value.itemPriceRate, greaterThanOrEqualTo(0.85),
            reason: '${entry.key} itemPriceMatch < 85%');
      }
    }

    expect(overall.totalRate, greaterThanOrEqualTo(0.80));
    expect(overall.itemPriceRate, greaterThanOrEqualTo(0.85));
  });
}
