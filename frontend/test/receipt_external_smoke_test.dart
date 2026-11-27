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
    final reportLines = <String>[
      'status\tfile\trows\titems\ttotal',
    ];
    var brokenRowsCount = 0;
    var unreadableCount = 0;
    var foundTotalCount = 0;
    var noTotalCount = 0;

    for (final file in rowFiles) {
      final fileName = file.uri.pathSegments.last;
      final rows = file.readAsLinesSync();
      final nonEmptyCount = rows.where((r) => r.trim().isNotEmpty).length;

      if (nonEmptyCount <= 6) {
        brokenRowsCount++;
        reportLines.add('BROKEN_ROWS\t$fileName\t$nonEmptyCount\t0\t0');
        continue;
      }

      late final ParsedReceipt parsed;
      try {
        parsed = parser.parse(rows);
      } on ReceiptUnreadable {
        unreadableCount++;
        reportLines.add('UNREAD\t$fileName\t$nonEmptyCount\t0\t0');
        continue;
      }

      final hasNoTotalWarning = parsed.warnings
          .any((w) => w.contains('Không tìm thấy dòng tổng'));
      if (hasNoTotalWarning) {
        noTotalCount++;
        reportLines.add(
          'NOTOTAL\t$fileName\t$nonEmptyCount\t${parsed.items.length}\t${parsed.totalAmount}',
        );
      } else {
        foundTotalCount++;
        reportLines.add(
          'OK\t$fileName\t$nonEmptyCount\t${parsed.items.length}\t${parsed.totalAmount}',
        );
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

    final reportFile = File('test/fixtures/external/smoke_report.tsv');
    reportFile.parent.createSync(recursive: true);
    reportFile.writeAsStringSync('${reportLines.join('\n')}\n');

    final totalFiles = rowFiles.length;
    final eligibleCount = totalFiles - brokenRowsCount;
    final foundTotalRate =
        eligibleCount == 0 ? 0.0 : foundTotalCount / eligibleCount;
    final unreadableRate =
        eligibleCount == 0 ? 0.0 : unreadableCount / eligibleCount;

    // ignore: avoid_print
    print(
      'External Smoke Report ($totalFiles files, eligible=$eligibleCount, BROKEN_ROWS=$brokenRowsCount): '
      'foundTotal=$foundTotalCount/$eligibleCount (${(foundTotalRate * 100).toStringAsFixed(1)}%), '
      'unreadable=$unreadableCount/$eligibleCount (${(unreadableRate * 100).toStringAsFixed(1)}%), '
      'noTotal=$noTotalCount',
    );
  });
}
