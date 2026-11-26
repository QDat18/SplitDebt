// Trách nhiệm file: Phân loại từng dòng trên hoá đơn thành loại (tổng, tạm tính, VAT, dịch vụ, giảm giá, món, bỏ qua, chữ thường).

import 'money_parser.dart';
import 'receipt_keywords.dart';

enum RowKind { ignore, total, subtotal, vat, service, discount, item, text }

bool _hasKeyword(String normalizedRow, String kw) {
  if (kw.endsWith(':')) {
    return normalizedRow.contains(kw);
  }
  final escaped = RegExp.escape(kw);
  return RegExp('(^|[^a-z0-9])$escaped([^a-z0-9]|\$)').hasMatch(normalizedRow);
}

bool _matchesAny(String normalizedRow, List<String> keywords) {
  for (final kw in keywords) {
    if (_hasKeyword(normalizedRow, kw)) return true;
  }
  return false;
}

RowKind classifyRow(String row, {required bool hasMoney}) {
  final norm = normalizeForMatch(row);
  if (norm.isEmpty) return RowKind.ignore;

  if (_matchesAny(norm, ReceiptKeywords.ignoreAlways)) {
    return RowKind.ignore;
  }
  if (!hasMoney && _matchesAny(norm, ReceiptKeywords.ignoreWhenNoMoney)) {
    return RowKind.ignore;
  }

  if (_matchesAny(norm, ReceiptKeywords.subtotal)) {
    return hasMoney ? RowKind.subtotal : RowKind.ignore;
  }

  if (_matchesAny(norm, ReceiptKeywords.total)) {
    return hasMoney ? RowKind.total : RowKind.ignore;
  }

  if (_matchesAny(norm, ReceiptKeywords.vat)) {
    if (_matchesAny(norm, ReceiptKeywords.vatIncluded)) {
      return RowKind.ignore;
    }
    return hasMoney ? RowKind.vat : RowKind.ignore;
  }

  if (_matchesAny(norm, ReceiptKeywords.service)) {
    return hasMoney ? RowKind.service : RowKind.ignore;
  }

  if (_matchesAny(norm, ReceiptKeywords.discount)) {
    return RowKind.discount;
  }

  if (hasMoney) {
    final tokens = parseMoneyTokens(row);
    if (tokens.isNotEmpty) {
      final leftPart = row.substring(0, tokens.first.start);
      final leftNorm = normalizeForMatch(leftPart);
      final letterCount =
          RegExp(r'[a-z]').allMatches(leftNorm).length;
      if (letterCount >= 2) {
        return RowKind.item;
      }
    }
  }

  return RowKind.text;
}
