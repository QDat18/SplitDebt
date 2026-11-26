import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:split_debt/features/expenses/receipt/receipt_models.dart';
import 'package:split_debt/features/expenses/receipt/rule_based_receipt_parser.dart';

class _HoldoutStats {
  int receipts = 0;
  int unreadable = 0;
  int totalMatched = 0;
  int expectedItems = 0;
  int matchedItems = 0;
  int exactItemCount = 0;

  double get totalRate => receipts == 0 ? 0.0 : totalMatched / receipts;
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
  const runHoldout = bool.fromEnvironment('RUN_HOLDOUT');

  test('receipt holdout accuracy report', () {
    if (!runHoldout) {
      markTestSkipped('Holdout test chỉ chạy khi --dart-define=RUN_HOLDOUT=true');
      return;
    }

    final dir = Directory('test/fixtures/external/holdout');
    final rowFiles = dir.existsSync()
        ? (dir
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.rows.txt'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path)))
        : <File>[];

    if (rowFiles.isEmpty) {
      markTestSkipped('Chưa có fixture holdout');
      return;
    }

    final parser = RuleBasedReceiptParser();
    final overall = _HoldoutStats();
    final byType = <String, _HoldoutStats>{};

    for (final rowFile in rowFiles) {
      final base = rowFile.path.replaceAll('.rows.txt', '');
      final expectedFile = File('$base.expected.json');
      if (!expectedFile.existsSync()) continue;

      final rows = rowFile.readAsLinesSync();
      final expected =
          jsonDecode(expectedFile.readAsStringSync()) as Map<String, dynamic>;
      final receiptType = expected['type'] as String? ?? 'restaurant';
      final bucket = byType.putIfAbsent(receiptType, _HoldoutStats.new);
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
      }

      for (final stats in [overall, bucket]) {
        stats.receipts++;
        if (parsed == null) stats.unreadable++;
        if (isTotalMatch) stats.totalMatched++;
        if (isExactItemCount) stats.exactItemCount++;
        stats.expectedItems += expectedItems.length;
        stats.matchedItems += matchedInReceipt;
      }
    }

    // ignore: avoid_print
    print(overall.formatReport('Holdout Report [overall]'));
    for (final entry in byType.entries) {
      // ignore: avoid_print
      print(entry.value.formatReport('Holdout Report [${entry.key}]'));
    }
  });
}
