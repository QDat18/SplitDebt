// Trách nhiệm file: Bộ phân tích hoá đơn theo quy tắc thuần Dart (implements ReceiptParser).

import 'item_row_parser.dart';
import 'money_parser.dart';
import 'receipt_models.dart';
import 'row_classifier.dart';

abstract class ReceiptParser {
  ParsedReceipt parse(List<String> rows);
}

final RegExp _dateRegex = RegExp(
  r'(?<!\d)(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{2,4})(?!\d)',
);
final RegExp _phoneRegex = RegExp(r'(?:\+84|0\d{2,3})[\s.-]?\d{3}[\s.-]?\d{3,4}');
final RegExp _percentRegex = RegExp(r'(\d+(?:[.,]\d+)?)\s*%');

class _RawAdjustment {
  final AdjustmentType type;
  final String label;
  final int? amount;
  final double? percent;

  const _RawAdjustment({
    required this.type,
    required this.label,
    this.amount,
    this.percent,
  });
}

class RuleBasedReceiptParser implements ReceiptParser {
  @override
  ParsedReceipt parse(List<String> rows) {
    final cleanedRows =
        rows.map((r) => r.trim()).where((r) => r.isNotEmpty).toList();
    if (cleanedRows.isEmpty) {
      throw const ReceiptUnreadable(
        'Không nhận ra món nào trên hoá đơn. Hãy chụp rõ hơn hoặc nhập tay.',
      );
    }

    final kinds = <RowKind>[];
    final rowTokens = <List<MoneyToken>>[];
    for (final row in cleanedRows) {
      final tokens = parseMoneyTokens(row);
      rowTokens.add(tokens);
      kinds.add(classifyRow(row, hasMoney: tokens.isNotEmpty));
    }

    // Bước 6: Tìm tên quán trong 5 hàng đầu
    String? storeName;
    int? storeNameIdx;
    final headerLimit = cleanedRows.length < 5 ? cleanedRows.length : 5;
    for (var i = 0; i < headerLimit; i++) {
      if (kinds[i] != RowKind.text) continue;
      final row = cleanedRows[i];
      if (_dateRegex.hasMatch(row) || _phoneRegex.hasMatch(row)) continue;
      final norm = normalizeForMatch(row);
      final letters = RegExp(r'[a-z]').allMatches(norm).length;
      if (letters >= 4) {
        storeName = row;
        storeNameIdx = i;
        break;
      }
    }

    // Bước 7: Tìm ngày
    DateTime? receiptDate;
    for (final row in cleanedRows) {
      final match = _dateRegex.firstMatch(row);
      if (match != null) {
        final d = int.tryParse(match.group(1)!);
        final m = int.tryParse(match.group(2)!);
        var y = int.tryParse(match.group(3)!);
        if (d != null && m != null && y != null) {
          if (y < 100) y += 2000;
          if (m >= 1 && m <= 12 && d >= 1 && d <= 31 && y >= 2000 && y <= 2100) {
            final parsed = DateTime(y, m, d);
            if (parsed.month == m && parsed.day == d) {
              receiptDate = parsed;
              break;
            }
          }
        }
      }
    }

    // Bước 4 & 5: Tách món + gộp tên món xuống dòng
    final items = <ParsedItem>[];
    final rawAdjustments = <_RawAdjustment>[];
    int? subtotal;
    int? explicitTotal;

    for (var i = 0; i < cleanedRows.length; i++) {
      final kind = kinds[i];
      final row = cleanedRows[i];
      final tokens = rowTokens[i];

      switch (kind) {
        case RowKind.item:
          var parsedItem = parseItemRow(row);
          if (parsedItem != null) {
            if (i > 0 &&
                kinds[i - 1] == RowKind.text &&
                (i - 1) != storeNameIdx) {
              final prev = cleanedRows[i - 1];
              if (prev.length >= 2 &&
                  prev.length <= 40 &&
                  !_dateRegex.hasMatch(prev) &&
                  !_phoneRegex.hasMatch(prev)) {
                parsedItem = ParsedItem(
                  name: '$prev ${parsedItem.name}',
                  quantity: parsedItem.quantity,
                  unitPrice: parsedItem.unitPrice,
                  totalPrice: parsedItem.totalPrice,
                );
              }
            }
            items.add(parsedItem);
          }
          break;
        case RowKind.subtotal:
          if (tokens.isNotEmpty) {
            subtotal = tokens.last.value;
          }
          break;
        case RowKind.total:
          if (tokens.isNotEmpty) {
            explicitTotal = tokens.last.value;
          }
          break;
        case RowKind.vat:
          rawAdjustments.add(_extractAdjustment(AdjustmentType.vat, row, tokens));
          break;
        case RowKind.service:
          rawAdjustments
              .add(_extractAdjustment(AdjustmentType.service, row, tokens));
          break;
        case RowKind.discount:
          rawAdjustments
              .add(_extractAdjustment(AdjustmentType.discount, row, tokens));
          break;
        case RowKind.ignore:
        case RowKind.text:
          break;
      }
    }

    if (items.isEmpty) {
      throw const ReceiptUnreadable(
        'Không nhận ra món nào trên hoá đơn. Hãy chụp rõ hơn hoặc nhập tay.',
      );
    }

    final sumItems = items.fold<int>(0, (sum, e) => sum + e.totalPrice);
    final percentBase = subtotal ?? sumItems;

    final adjustments = <ParsedAdjustment>[];
    for (final raw in rawAdjustments) {
      int? resolved = raw.amount;
      if (resolved == null && raw.percent != null) {
        resolved = (percentBase * raw.percent! / 100.0).round();
      }
      if (resolved == null || resolved == 0) continue;

      final signed = raw.type == AdjustmentType.discount
          ? -resolved.abs()
          : resolved.abs();
      adjustments.add(
        ParsedAdjustment(
          type: raw.type,
          label: raw.label,
          amount: signed,
        ),
      );
    }

    final sumAdj = adjustments.fold<int>(0, (sum, e) => sum + e.amount);
    final warnings = <String>[];

    late final int totalAmount;
    if (explicitTotal != null) {
      totalAmount = explicitTotal;
    } else {
      totalAmount = sumItems + sumAdj;
      warnings.add('Không tìm thấy dòng tổng, đã cộng từ các món.');
    }

    final diffTotal = (sumItems + sumAdj - totalAmount).abs();
    if (diffTotal > 1000) {
      warnings.add(
        'Tổng các món lệch ${_formatVnd(diffTotal)}đ so với tổng hoá đơn. Hãy kiểm tra lại.',
      );
    }

    if (subtotal != null) {
      final diffSub = (sumItems - subtotal).abs();
      if (diffSub > 1000) {
        warnings.add(
          'Tổng các món lệch ${_formatVnd(diffSub)}đ so với tạm tính.',
        );
      }
    }

    return ParsedReceipt(
      storeName: storeName,
      receiptDate: receiptDate,
      items: items,
      adjustments: adjustments,
      subtotal: subtotal,
      totalAmount: totalAmount,
      warnings: warnings,
    );
  }

  _RawAdjustment _extractAdjustment(
    AdjustmentType type,
    String row,
    List<MoneyToken> tokens,
  ) {
    final amount = tokens.isNotEmpty ? tokens.last.value : null;
    double? percent;
    if (amount == null) {
      final pctMatch = _percentRegex.firstMatch(row);
      if (pctMatch != null) {
        percent = double.tryParse(pctMatch.group(1)!.replaceAll(',', '.'));
      }
    }

    var label = row;
    if (tokens.isNotEmpty) {
      label = row.substring(0, tokens.last.start).trim();
    }
    if (label.isEmpty) {
      label = row;
    }

    return _RawAdjustment(
      type: type,
      label: label,
      amount: amount,
      percent: percent,
    );
  }

  String _formatVnd(int value) {
    final s = value.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) {
        buf.write('.');
      }
      buf.write(s[i]);
    }
    return buf.toString();
  }
}
