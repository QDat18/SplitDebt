import 'package:flutter_test/flutter_test.dart';
import 'package:split_debt/features/expenses/receipt/receipt_applier.dart';
import 'package:split_debt/features/expenses/receipt/receipt_models.dart';

void main() {
  final now = DateTime(2026, 10, 8, 12, 0);

  test('VAT 8% over 3 items sums exactly', () {
    const parsed = ParsedReceipt(
      storeName: 'Nhà hàng ABC',
      items: [
        ParsedItem(name: 'Món 1', quantity: 1, totalPrice: 100000),
        ParsedItem(name: 'Món 2', quantity: 1, totalPrice: 150000),
        ParsedItem(name: 'Món 3', quantity: 1, totalPrice: 70000),
      ],
      adjustments: [
        ParsedAdjustment(type: AdjustmentType.vat, label: 'VAT 8%', amount: 25600),
      ],
      totalAmount: 345600,
    );

    final applied = ReceiptApplier.apply(parsed, now);
    final sumPrice =
        applied.items.fold<int>(0, (sum, e) => sum + e.price.round());
    expect(sumPrice, 345600);
    expect(applied.totalAmount, 345600);
  });

  test('negative discount is spread', () {
    const parsed = ParsedReceipt(
      storeName: 'Quán Test',
      items: [
        ParsedItem(name: 'Món A', quantity: 1, totalPrice: 100000),
        ParsedItem(name: 'Món B', quantity: 1, totalPrice: 100000),
      ],
      adjustments: [
        ParsedAdjustment(
            type: AdjustmentType.discount, label: 'Giảm giá', amount: -10000),
      ],
      totalAmount: 190000,
    );

    final applied = ReceiptApplier.apply(parsed, now);
    expect(applied.items[0].price, 95000);
    expect(applied.items[1].price, 95000);
    expect(applied.totalAmount, 190000);
  });

  test('single item takes everything', () {
    const parsed = ParsedReceipt(
      items: [
        ParsedItem(name: 'Món duy nhất', quantity: 1, totalPrice: 100000),
      ],
      adjustments: [
        ParsedAdjustment(type: AdjustmentType.vat, label: 'VAT', amount: 8000),
      ],
      totalAmount: 108000,
    );

    final applied = ReceiptApplier.apply(parsed, now);
    expect(applied.items.single.price, 108000);
    expect(applied.totalAmount, 108000);
  });

  test('rounding remainder goes to the most expensive item', () {
    const parsed = ParsedReceipt(
      items: [
        ParsedItem(name: 'Rẻ', quantity: 1, totalPrice: 10000),
        ParsedItem(name: 'Đắt', quantity: 1, totalPrice: 20000),
        ParsedItem(name: 'Trung bình', quantity: 1, totalPrice: 15000),
      ],
      adjustments: [
        ParsedAdjustment(type: AdjustmentType.vat, label: 'VAT', amount: 100),
      ],
      totalAmount: 45100,
    );

    final applied = ReceiptApplier.apply(parsed, now);
    final sumPrice =
        applied.items.fold<int>(0, (sum, e) => sum + e.price.round());
    expect(sumPrice, 45100);
    // 100 * 10000/45000 = 22.2 -> 22; 100 * 20000/45000 = 44.4 -> 44 + remainder(1) = 45; 100 * 15000/45000 = 33.3 -> 33
    expect(applied.items[1].price, 20045);
  });

  test('quantity > 1 renders as "name xN"', () {
    const parsed = ParsedReceipt(
      items: [
        ParsedItem(name: 'Thịt bò', quantity: 2, totalPrice: 240000),
      ],
      totalAmount: 240000,
    );

    final applied = ReceiptApplier.apply(parsed, now);
    expect(applied.items.single.name, 'Thịt bò x2');
  });

  test('fallback title "Hoá đơn dd/MM"', () {
    final parsed = ParsedReceipt(
      storeName: null,
      receiptDate: DateTime(2026, 10, 7),
      items: const [ParsedItem(name: 'Cơm', quantity: 1, totalPrice: 50000)],
      totalAmount: 50000,
    );

    final applied = ReceiptApplier.apply(parsed, now);
    expect(applied.title, 'Hoá đơn 07/10');
  });

  test('future receipt date is ignored', () {
    final parsed = ParsedReceipt(
      storeName: 'Quán Test',
      receiptDate: now.add(const Duration(days: 1)),
      items: const [ParsedItem(name: 'Cơm', quantity: 1, totalPrice: 50000)],
      totalAmount: 50000,
    );

    final applied = ReceiptApplier.apply(parsed, now);
    expect(applied.expenseDate, isNull);
  });

  test('when items miss money, form total equals sum of items', () {
    const parsed = ParsedReceipt(
      items: [
        ParsedItem(name: 'Món 1', quantity: 1, totalPrice: 100000),
        ParsedItem(name: 'Món 2', quantity: 1, totalPrice: 150000),
        ParsedItem(name: 'Món 3', quantity: 1, totalPrice: 70000),
      ],
      adjustments: [
        ParsedAdjustment(type: AdjustmentType.vat, label: 'VAT 8%', amount: 25600),
      ],
      totalAmount: 400000,
    );

    final applied = ReceiptApplier.apply(parsed, now);
    expect(applied.totalAmount, 345600);
  });

  test('assigned members start empty', () {
    const parsed = ParsedReceipt(
      items: [
        ParsedItem(name: 'Món 1', quantity: 1, totalPrice: 50000),
      ],
      totalAmount: 50000,
    );

    final applied = ReceiptApplier.apply(parsed, now);
    expect(applied.items.single.assignedMemberIds, isEmpty);
  });

  test('oversized discount does not zero items', () {
    const parsed = ParsedReceipt(
      items: [
        ParsedItem(name: 'Món 1', quantity: 1, totalPrice: 150000),
      ],
      adjustments: [
        ParsedAdjustment(
          type: AdjustmentType.discount,
          label: 'Voucher',
          amount: -200000,
        ),
      ],
      totalAmount: 0,
    );

    final applied = ReceiptApplier.apply(parsed, now);
    expect(applied.adjustmentSkipped, isTrue);
    expect(applied.items.single.price, 150000);
    expect(applied.totalAmount, 150000);
  });
}
