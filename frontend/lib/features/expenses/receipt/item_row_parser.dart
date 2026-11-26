// Trách nhiệm file: Bóc tách tên món, số lượng, đơn giá và thành tiền từ một hàng món ăn đã phân loại.

import 'money_parser.dart';
import 'receipt_models.dart';

final RegExp _xQtySuffix = RegExp(r'(?:^|\s)[xX](\d{1,2})\s*$');
final RegExp _qtyXSuffix = RegExp(r'(?:^|\s)(\d{1,2})[xX]\s*$');
final RegExp _plainQtySuffix = RegExp(r'(?:^|\s)(\d{1,2})\s*$');

ParsedItem? parseItemRow(String row) {
  final tokens = parseMoneyTokens(row);
  if (tokens.isEmpty) return null;

  final totalPrice = tokens.last.value;
  final firstToken = tokens.first;
  var leftText = row.substring(0, firstToken.start);

  var quantity = 1;
  var extractedQtyFromLeft = false;

  final xMatch = _xQtySuffix.firstMatch(leftText);
  final qtyXMatch = _qtyXSuffix.firstMatch(leftText);
  if (xMatch != null) {
    final q = int.tryParse(xMatch.group(1)!);
    if (q != null && q >= 1 && q <= 99) {
      quantity = q;
      leftText = leftText.substring(0, xMatch.start);
      extractedQtyFromLeft = true;
    }
  } else if (qtyXMatch != null) {
    final q = int.tryParse(qtyXMatch.group(1)!);
    if (q != null && q >= 1 && q <= 99) {
      quantity = q;
      leftText = leftText.substring(0, qtyXMatch.start);
      extractedQtyFromLeft = true;
    }
  } else {
    final plainMatch = _plainQtySuffix.firstMatch(leftText);
    if (plainMatch != null) {
      final q = int.tryParse(plainMatch.group(1)!);
      if (q != null && q >= 1 && q <= 99) {
        quantity = q;
        leftText = leftText.substring(0, plainMatch.start);
        extractedQtyFromLeft = true;
      }
    }
  }

  int? unitPrice;
  if (tokens.length >= 2) {
    final candidateUnit = tokens[tokens.length - 2].value;
    if ((quantity * candidateUnit - totalPrice).abs() <= 1000) {
      unitPrice = candidateUnit;
    } else if (!extractedQtyFromLeft && candidateUnit > 0) {
      // Thử kiểm tra trường hợp số lượng không nằm trước đơn giá nhưng unitPrice == totalPrice khi qty == 1
      if ((candidateUnit - totalPrice).abs() <= 1000) {
        unitPrice = candidateUnit;
      }
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
