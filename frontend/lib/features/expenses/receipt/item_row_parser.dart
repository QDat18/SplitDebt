// Trách nhiệm file: Bóc tách tên món, số lượng, đơn giá và thành tiền từ một hàng món ăn đã phân loại.

import 'money_parser.dart';
import 'receipt_models.dart';

final RegExp _xQtySuffix = RegExp(r'(?:^|\s)[xX](\d{1,2})\s*$');
final RegExp _qtyXSuffix = RegExp(r'(?:^|\s)(\d{1,2})[xX]\s*$');
final RegExp _plainQtySuffix = RegExp(r'(?:^|\s)(\d{1,2})\s*$');
final RegExp _betweenIntRegex = RegExp(r'^\s*(\d{1,2})\s*$');

ParsedItem? parseItemRow(String row) {
  final tokens = parseMoneyTokens(row);
  if (tokens.isEmpty) return null;

  final totalPrice = tokens.last.value;
  final firstToken = tokens.first;
  var leftText = row.substring(0, firstToken.start);

  var quantity = 1;
  var hasExplicitXQty = false;

  final xMatch = _xQtySuffix.firstMatch(leftText);
  final qtyXMatch = _qtyXSuffix.firstMatch(leftText);
  if (xMatch != null) {
    final q = int.tryParse(xMatch.group(1)!);
    if (q != null && q >= 1 && q <= 99) {
      quantity = q;
      leftText = leftText.substring(0, xMatch.start);
      hasExplicitXQty = true;
    }
  } else if (qtyXMatch != null) {
    final q = int.tryParse(qtyXMatch.group(1)!);
    if (q != null && q >= 1 && q <= 99) {
      quantity = q;
      leftText = leftText.substring(0, qtyXMatch.start);
      hasExplicitXQty = true;
    }
  }

  int? unitPrice;
  if (tokens.length >= 2) {
    final unitToken = tokens[tokens.length - 2];
    final candidateUnit = unitToken.value;
    final betweenText = row.substring(unitToken.end, tokens.last.start);
    final betweenMatch = _betweenIntRegex.firstMatch(betweenText);

    if (!hasExplicitXQty && betweenMatch != null) {
      final q = int.tryParse(betweenMatch.group(1)!);
      if (q != null &&
          q >= 1 &&
          q <= 99 &&
          (q * candidateUnit - totalPrice).abs() <= 1000) {
        quantity = q;
        unitPrice = candidateUnit;
      }
    }

    if (unitPrice == null && !hasExplicitXQty) {
      final plainMatch = _plainQtySuffix.firstMatch(leftText);
      if (plainMatch != null) {
        final q = int.tryParse(plainMatch.group(1)!);
        if (q != null &&
            q >= 1 &&
            q <= 99 &&
            (q * candidateUnit - totalPrice).abs() <= 1000) {
          quantity = q;
          unitPrice = candidateUnit;
          leftText = leftText.substring(0, plainMatch.start);
        }
      }
    }

    if (unitPrice == null &&
        hasExplicitXQty &&
        (quantity * candidateUnit - totalPrice).abs() <= 1000) {
      unitPrice = candidateUnit;
    }
  }

  final name = leftText.trim().replaceAll(RegExp(r'[-:]+$'), '').trim();
  if (name.isEmpty) return null;

  return ParsedItem(
    name: name,
    quantity: quantity,
    unitPrice: unitPrice,
    totalPrice: totalPrice,
  );
}
