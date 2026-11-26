import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:split_debt/features/expenses/receipt/receipt_models.dart';
import 'package:split_debt/features/expenses/receipt/rule_based_receipt_parser.dart';

void main() {
  test('external VietReceipt smoke test', () {
    final dir = Directory('test/fixtures/external/smoke');
    final rowFiles = dir.existsSync()
        ? (dir
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.rows.txt'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path)))
        : <File>[];

    if (rowFiles.isEmpty) {
      markTestSkipped('Chưa có dữ liệu VietReceipt (bị gitignore)');
      return;
    }

    final parser = RuleBasedReceiptParser();
    var unreadableCount = 0;
    var foundTotalCount = 0;

    for (final file in rowFiles) {
      final rows = file.readAsLinesSync();
      late final ParsedReceipt parsed;
      try {
        parsed = parser.parse(rows);
      } on ReceiptUnreadable {
        unreadableCount++;
        continue;
      }

      final hasNoTotalWarning = parsed.warnings
          .any((w) => w.contains('Không tìm thấy dòng tổng'));
      if (!hasNoTotalWarning) {
        foundTotalCount++;
      }

      final sumParsed =
          parsed.items.fold<int>(0, (s, item) => s + item.totalPrice) +
              parsed.adjustments.fold<int>(0, (s, adj) => s + adj.amount);
      if ((sumParsed - parsed.totalAmount).abs() > 1000) {
        expect(
          parsed.warnings,
          isNotEmpty,
          reason: 'Hoá đơn lệch tổng nhưng thiếu cảnh báo: ${file.path}',
        );
      }
    }

    final totalFiles = rowFiles.length;
    final readableCount = totalFiles - unreadableCount;
    final totalRate = readableCount == 0 ? 0.0 : foundTotalCount / readableCount;
    final unreadableRate = unreadableCount / totalFiles;

    // ignore: avoid_print
    print(
      'External Smoke Report ($totalFiles files): '
      'foundTotal=$foundTotalCount/$readableCount (${(totalRate * 100).toStringAsFixed(1)}%), '
      'unreadable=$unreadableCount/$totalFiles (${(unreadableRate * 100).toStringAsFixed(1)}%)',
    );
  });
}
