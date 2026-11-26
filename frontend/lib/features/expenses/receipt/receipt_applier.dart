// Trách nhiệm file: Phân bổ VAT/phí/giảm giá theo tỉ lệ giá món và chuyển ParsedReceipt thành AppliedReceipt cho form Tạo khoản chi.

import '../models/expense_item_detail.dart';
import 'receipt_models.dart';

class AppliedReceipt {
  final List<ExpenseItemDetail> items;
  final int totalAmount;
  final String title;
  final DateTime? expenseDate;

  const AppliedReceipt({
    required this.items,
    required this.totalAmount,
    required this.title,
    required this.expenseDate,
  });
}

class ReceiptApplier {
  static AppliedReceipt apply(ParsedReceipt parsed, DateTime now) {
    final sumRawItems =
        parsed.items.fold<int>(0, (sum, item) => sum + item.totalPrice);
    final totalAdjustment =
        parsed.adjustments.fold<int>(0, (sum, adj) => sum + adj.amount);

    final allocations = List<int>.filled(parsed.items.length, 0);
    if (sumRawItems > 0 && parsed.items.isNotEmpty) {
      var allocatedSum = 0;
      var maxIdx = 0;
      for (var i = 0; i < parsed.items.length; i++) {
        if (parsed.items[i].totalPrice > parsed.items[maxIdx].totalPrice) {
          maxIdx = i;
        }
        final share =
            (totalAdjustment * parsed.items[i].totalPrice / sumRawItems)
                .round();
        allocations[i] = share;
        allocatedSum += share;
      }
      final remainder = totalAdjustment - allocatedSum;
      allocations[maxIdx] += remainder;
    }

    final appliedItems = <ExpenseItemDetail>[];
    var sumAppliedPrice = 0;
    for (var i = 0; i < parsed.items.length; i++) {
      final src = parsed.items[i];
      final rawPrice = src.totalPrice + allocations[i];
      final safePrice = rawPrice > 0 ? rawPrice : 0;
      sumAppliedPrice += safePrice;

      final displayName =
          src.quantity > 1 ? '${src.name} x${src.quantity}' : src.name;
      appliedItems.add(
        ExpenseItemDetail(
          id: 'ocr_$i',
          name: displayName,
          price: safePrice.toDouble(),
          assignedMemberIds: [],
        ),
      );
    }

    DateTime? safeDate;
    if (parsed.receiptDate != null) {
      final d = parsed.receiptDate!;
      final receiptDay = DateTime(d.year, d.month, d.day);
      final today = DateTime(now.year, now.month, now.day);
      if (!receiptDay.isAfter(today)) {
        safeDate = receiptDay;
      }
    }

    final fallbackDate = safeDate ?? now;
    final dd = fallbackDate.day.toString().padLeft(2, '0');
    final mm = fallbackDate.month.toString().padLeft(2, '0');
    final trimmedStore = parsed.storeName?.trim() ?? '';
    final title = trimmedStore.isNotEmpty ? trimmedStore : 'Hoá đơn $dd/$mm';

    return AppliedReceipt(
      items: appliedItems,
      totalAmount: sumAppliedPrice,
      title: title,
      expenseDate: safeDate,
    );
  }
}
