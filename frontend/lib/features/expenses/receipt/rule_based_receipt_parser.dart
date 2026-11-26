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
final RegExp _vatItemPrefixRegex = RegExp(
  r'^vat\s?\d{1,2}%\s*',
  caseSensitive: false,
);
final RegExp _barcodeRegex = RegExp(r'\b\d{8,14}\b');
final RegExp _standaloneWeightRegex = RegExp(
  r'^\s*(\d+[.,]\d+)\s*(kg|gr|g|lit|l|ml)\s*$',
  caseSensitive: false,
);
final RegExp _tongSoTotalRegex = RegExp(r'\btong so:\s*\d{1,3}\s+');

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
    for (var i = 0; i < cleanedRows.length; i++) {
      final row = cleanedRows[i];
      final tokens = parseMoneyTokens(row);
      rowTokens.add(tokens);
      var kind = classifyRow(row, hasMoney: tokens.isNotEmpty);
      if (tokens.isNotEmpty && _vatItemPrefixRegex.hasMatch(row)) {
        final prevHasBarcode = i > 0 && _barcodeRegex.hasMatch(cleanedRows[i - 1]);
        if (tokens.length >= 2 || prevHasBarcode) {
          kind = RowKind.text;
        }
      }
      kinds.add(kind);
    }

    // Bước 6: Tìm tên quán trong 5 hàng đầu (trước hàng món đầu tiên, không chọn hàng ngay trước hàng số liệu món)
    var firstItemIdx = cleanedRows.length;
    for (var i = 0; i < cleanedRows.length; i++) {
      if (kinds[i] == RowKind.item) {
        firstItemIdx = i;
        break;
      }
    }

    String? storeName;
    int? storeNameIdx;
    final headerLimit = cleanedRows.length < 5 ? cleanedRows.length : 5;
    for (var i = 0; i < headerLimit && i < firstItemIdx; i++) {
      if (kinds[i] != RowKind.text) continue;
      final row = cleanedRows[i];
      if (RegExp(r'^\d{8,14}\s+').hasMatch(row)) continue;
      if (i + 1 < cleanedRows.length &&
          kinds[i + 1] == RowKind.text &&
          rowTokens[i + 1].isNotEmpty &&
          (rowTokens[i + 1].length >= 2 ||
              RegExp(r'[.,kK]').hasMatch(cleanedRows[i + 1]))) {
        continue;
      }
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

    // Bước 4 & 5: Tách món + gộp tên món xuống dòng / hàng số ngay sau hàng chữ
    final items = <ParsedItem>[];
    final rawAdjustments = <_RawAdjustment>[];
    int? subtotal;
    final totalCandidates = <int>[];
    final lowPriorityTotalCandidates = <int>[];
    final consumedItemRows = <int>{};
    var lastConsumedTextIdx = -1;
    var lastItemRowIdx = -1;
    var seenSummaryOrAdj = false;

    bool isMergeableTextRow(int idx) {
      if (idx < 0 || idx == storeNameIdx || idx == lastConsumedTextIdx) {
        return false;
      }
      if (kinds[idx] != RowKind.text) return false;
      final prev = cleanedRows[idx];
      if (_standaloneWeightRegex.hasMatch(prev)) return false;
      final withoutBarcode =
          prev.replaceFirst(RegExp(r'^\d{8,14}\s+'), '').trim();
      if (withoutBarcode.length < 2 || withoutBarcode.length > 40) {
        return false;
      }
      if (_dateRegex.hasMatch(withoutBarcode) ||
          _phoneRegex.hasMatch(withoutBarcode)) {
        return false;
      }
      if (_isMostlyDigits(withoutBarcode)) return false;
      return true;
    }

    for (var i = 0; i < cleanedRows.length; i++) {
      final kind = kinds[i];
      final row = cleanedRows[i];
      final tokens = rowTokens[i];

      switch (kind) {
        case RowKind.item:
          if (tokens.isNotEmpty &&
              _tongSoTotalRegex.hasMatch(normalizeForMatch(row))) {
            seenSummaryOrAdj = true;
            lowPriorityTotalCandidates.add(tokens.last.value);
            break;
          }
          var parsedItem = parseItemRow(row);
          if (parsedItem != null) {
            if (isMergeableTextRow(i - 1)) {
              final prev = cleanedRows[i - 1];
              lastConsumedTextIdx = i - 1;
              parsedItem = ParsedItem(
                name: '$prev ${parsedItem.name}',
                quantity: parsedItem.quantity,
                unitPrice: parsedItem.unitPrice,
                totalPrice: parsedItem.totalPrice,
              );
            }
            items.add(parsedItem);
            consumedItemRows.add(i);
            lastItemRowIdx = i;
          }
          break;
        case RowKind.subtotal:
          seenSummaryOrAdj = true;
          if (tokens.isNotEmpty) {
            subtotal = tokens.last.value;
          }
          break;
        case RowKind.total:
          seenSummaryOrAdj = true;
          if (tokens.isNotEmpty) {
            totalCandidates.add(tokens.last.value);
          }
          break;
        case RowKind.vat:
          seenSummaryOrAdj = true;
          rawAdjustments.add(_extractAdjustment(AdjustmentType.vat, row, tokens));
          break;
        case RowKind.service:
          seenSummaryOrAdj = true;
          rawAdjustments
              .add(_extractAdjustment(AdjustmentType.service, row, tokens));
          break;
        case RowKind.discount:
          seenSummaryOrAdj = true;
          rawAdjustments
              .add(_extractAdjustment(AdjustmentType.discount, row, tokens));
          break;
        case RowKind.text:
          final weightMatch = _standaloneWeightRegex.firstMatch(row);
          if (weightMatch != null) {
            if (lastItemRowIdx == i - 1 && items.isNotEmpty) {
              final prevItem = items.last;
              final weightVal = weightMatch.group(1)!.replaceAll('.', ',');
              final unit = weightMatch.group(2)!.toLowerCase();
              items[items.length - 1] = ParsedItem(
                name: '${prevItem.name} ($weightVal $unit)',
                quantity: 1,
                unitPrice: prevItem.unitPrice,
                totalPrice: prevItem.totalPrice,
              );
            }
            break;
          }
          if (!seenSummaryOrAdj &&
              tokens.isNotEmpty &&
              isMergeableTextRow(i - 1)) {
            final prev = cleanedRows[i - 1];
            final cleanNumRow = row.replaceFirst(_vatItemPrefixRegex, '');
            final mergedItem = parseItemRow('$prev  $cleanNumRow');
            if (mergedItem != null) {
              lastConsumedTextIdx = i - 1;
              items.add(mergedItem);
              consumedItemRows.add(i);
              lastItemRowIdx = i;
            }
          }
          break;
        case RowKind.ignore:
          if (tokens.isEmpty && isTotalKeywordRow(row)) {
            seenSummaryOrAdj = true;
            if (i > 0 &&
                kinds[i - 1] == RowKind.text &&
                rowTokens[i - 1].isNotEmpty &&
                !consumedItemRows.contains(i - 1)) {
              totalCandidates.add(rowTokens[i - 1].last.value);
            } else if (i + 1 < cleanedRows.length &&
                kinds[i + 1] == RowKind.text &&
                rowTokens[i + 1].isNotEmpty &&
                !consumedItemRows.contains(i + 1)) {
              totalCandidates.add(rowTokens[i + 1].last.value);
            }
          }
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
    final effectiveTotals = totalCandidates.isNotEmpty
        ? totalCandidates
        : lowPriorityTotalCandidates;
    if (effectiveTotals.isNotEmpty) {
      final expectedTotal = sumItems + sumAdj;
      var chosen = effectiveTotals.last;
      if (chosen < expectedTotal - 1000) {
        for (var i = effectiveTotals.length - 2; i >= 0; i--) {
          if ((effectiveTotals[i] - expectedTotal).abs() <= 1000) {
            chosen = effectiveTotals[i];
            break;
          }
        }
      }
      totalAmount = chosen;
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

  bool _isMostlyDigits(String s) {
    final compact = s.replaceAll(RegExp(r'\s+'), '');
    if (compact.isEmpty) return false;
    final digits = RegExp(r'\d').allMatches(compact).length;
    return digits * 2 >= compact.length;
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
