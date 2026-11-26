import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:split_debt/features/expenses/receipt/rule_based_receipt_parser.dart';

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
    var totalMatchedCount = 0;
    var expectedItemsTotal = 0;
    var matchedItemsTotal = 0;
    var exactItemCountReceipts = 0;

    for (final rowFile in rowFiles) {
      final base = rowFile.path.replaceAll('.rows.txt', '');
      final expectedFile = File('$base.expected.json');
      expect(expectedFile.existsSync(), isTrue,
          reason: 'Thiếu file expected cho ${rowFile.path}');

      final rows = rowFile.readAsLinesSync();
      final expected =
          jsonDecode(expectedFile.readAsStringSync()) as Map<String, dynamic>;

      final parsed = parser.parse(rows);
      final expectedTotal = (expected['totalAmount'] as num).toInt();
      final expectedItems = (expected['items'] as List<dynamic>)
          .cast<Map<String, dynamic>>();

      final isTotalMatch = parsed.totalAmount == expectedTotal;
      if (isTotalMatch) totalMatchedCount++;

      if (parsed.items.length == expectedItems.length) {
        exactItemCountReceipts++;
      }

      expectedItemsTotal += expectedItems.length;
      final minLen = parsed.items.length < expectedItems.length
          ? parsed.items.length
          : expectedItems.length;
      for (var i = 0; i < minLen; i++) {
        final expPrice = (expectedItems[i]['totalPrice'] as num).toInt();
        if (parsed.items[i].totalPrice == expPrice) {
          matchedItemsTotal++;
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

    final totalRate = totalMatchedCount / rowFiles.length;
    final itemPriceRate =
        expectedItemsTotal == 0 ? 1.0 : matchedItemsTotal / expectedItemsTotal;

    // ignore: avoid_print
    print(
      'OCR Fixture Report (${rowFiles.length} receipts): '
      'totalMatch=$totalMatchedCount/${rowFiles.length} (${(totalRate * 100).toStringAsFixed(1)}%), '
      'itemPriceMatch=$matchedItemsTotal/$expectedItemsTotal (${(itemPriceRate * 100).toStringAsFixed(1)}%), '
      'exactItemCount=$exactItemCountReceipts/${rowFiles.length}',
    );

    expect(totalRate, greaterThanOrEqualTo(0.80));
    expect(itemPriceRate, greaterThanOrEqualTo(0.85));
  });
}
