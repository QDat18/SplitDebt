import 'package:flutter_test/flutter_test.dart';
import 'package:split_debt/features/expenses/receipt/receipt_models.dart';
import 'package:split_debt/features/expenses/receipt/rule_based_receipt_parser.dart';

void main() {
  final parser = RuleBasedReceiptParser();

  test('full receipt with vat, discount and change', () {
    final parsed = parser.parse([
      'NHÀ HÀNG ABC',
      'ĐT: 0901 234 567',
      'Ngày: 07/10/2026',
      'Thịt bò ba chỉ  2  120.000  240.000',
      'Nước lẩu Thái  80.000',
      'Tổng tiền hàng  320.000',
      'VAT 8%  25.600',
      'Giảm giá  10.000',
      'Tổng thanh toán  335.600',
      'Tiền khách đưa  500.000',
      'Tiền thừa  164.400',
    ]);

    expect(parsed.storeName, 'NHÀ HÀNG ABC');
    expect(parsed.receiptDate, DateTime(2026, 10, 7));
    expect(parsed.items.length, 2);
    expect(parsed.subtotal, 320000);
    expect(parsed.totalAmount, 335600);
    expect(parsed.adjustments.length, 2);
    expect(parsed.adjustments[0].type, AdjustmentType.vat);
    expect(parsed.adjustments[0].amount, 25600);
    expect(parsed.adjustments[1].type, AdjustmentType.discount);
    expect(parsed.adjustments[1].amount, -10000);
    expect(parsed.warnings, isEmpty);
  });

  test('wrapped item name is merged', () {
    final parsed = parser.parse([
      'QUÁN LẨU NGON',
      'Lẩu hải sản chua cay',
      'đặc biệt  350.000',
      'Tổng cộng  350.000',
    ]);

    expect(parsed.items.length, 1);
    expect(parsed.items.first.name, 'Lẩu hải sản chua cay đặc biệt');
    expect(parsed.items.first.totalPrice, 350000);
  });

  test('percent discount uses subtotal', () {
    final parsed = parser.parse([
      'QUÁN ĂN',
      'Gà nướng  300.000',
      'Tổng tiền hàng  300.000',
      'Giảm giá 10%',
      'Tổng thanh toán  270.000',
    ]);

    expect(parsed.adjustments.length, 1);
    expect(parsed.adjustments.first.type, AdjustmentType.discount);
    expect(parsed.adjustments.first.amount, -30000);
  });

  test('store name skips phone and address lines', () {
    final parsed = parser.parse([
      'ĐT: 0901 234 567',
      'Địa chỉ: 12 Lê Lợi',
      'BÚN BÒ HUẾ O XUÂN',
      'Bún bò  55.000',
      'Tổng cộng  55.000',
    ]);

    expect(parsed.storeName, 'BÚN BÒ HUẾ O XUÂN');
  });

  test('date formats', () {
    for (final dateStr in ['07/10/2026', '07-10-2026', '07.10.26']) {
      final parsed = parser.parse([
        'QUÁN TEST',
        'Ngày $dateStr',
        'Cơm tấm  45.000',
        'Tổng  45.000',
      ]);
      expect(parsed.receiptDate, DateTime(2026, 10, 7));
    }
  });

  test('mismatch adds warning', () {
    final parsed = parser.parse([
      'QUÁN TEST',
      'Cơm tấm  300.000',
      'Tổng cộng  320.000',
    ]);

    expect(parsed.totalAmount, 320000);
    expect(parsed.warnings, isNotEmpty);
  });

  test('no total line sums items and warns', () {
    final parsed = parser.parse([
      'QUÁN TEST',
      'Cơm tấm  50.000',
      'Trà đá  10.000',
    ]);

    expect(parsed.totalAmount, 60000);
    expect(parsed.warnings, isNotEmpty);
  });

  test('no items throws ReceiptUnreadable', () {
    expect(
      () => parser.parse(['NHÀ HÀNG ABC', 'Cảm ơn quý khách']),
      throwsA(isA<ReceiptUnreadable>()),
    );
  });

  test('name row followed by numbers-only row forms one item', () {
    final parsed = parser.parse([
      'QUAN AN NGON',
      'Bun bo hue',
      '2  50.000  100.000',
      'Com tam  45.000',
      'Tong cong  145.000',
    ]);

    expect(parsed.items.length, 2);
    expect(parsed.items[0].name, 'Bun bo hue');
    expect(parsed.items[0].quantity, 2);
    expect(parsed.items[0].totalPrice, 100000);
    expect(parsed.items[1].name, 'Com tam');
    expect(parsed.items[1].totalPrice, 45000);
  });

  test('mostly-digit rows are never merged into a name', () {
    final parsed = parser.parse([
      'QUAN AN NGON',
      '123456 789',
      'Com tam  45.000',
      'Tong cong  45.000',
    ]);

    expect(parsed.items.length, 1);
    expect(parsed.items.first.name, 'Com tam');
  });

  test('amount paid by customer does not override total', () {
    final parsed = parser.parse([
      'QUAN TEST',
      'Mon A  550.000',
      'Tổng cộng  550.000',
      'Khách thanh toán  600.000',
    ]);

    expect(parsed.totalAmount, 550000);
    expect(parsed.warnings, isEmpty);
  });
}
