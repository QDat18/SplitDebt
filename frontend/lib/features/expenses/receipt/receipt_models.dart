// Trách nhiệm file: Định nghĩa các model kết quả phân tích hoá đơn thuần Dart.

enum AdjustmentType { vat, service, discount, other }

class ParsedItem {
  final String name;
  final int quantity;
  final int? unitPrice;
  final int totalPrice;

  const ParsedItem({
    required this.name,
    required this.quantity,
    this.unitPrice,
    required this.totalPrice,
  });
}

class ParsedAdjustment {
  final AdjustmentType type;
  final String label;
  final int amount;

  const ParsedAdjustment({
    required this.type,
    required this.label,
    required this.amount,
  });
}

class ParsedReceipt {
  final String? storeName;
  final DateTime? receiptDate;
  final List<ParsedItem> items;
  final List<ParsedAdjustment> adjustments;
  final int? subtotal;
  final int totalAmount;
  final List<String> warnings;

  const ParsedReceipt({
    this.storeName,
    this.receiptDate,
    required this.items,
    this.adjustments = const [],
    this.subtotal,
    required this.totalAmount,
    this.warnings = const [],
  });
}

class ReceiptUnreadable implements Exception {
  final String message;

  const ReceiptUnreadable(this.message);

  @override
  String toString() => message;
}
