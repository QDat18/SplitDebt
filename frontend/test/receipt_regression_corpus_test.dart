import 'package:flutter_test/flutter_test.dart';
import 'package:split_debt/features/expenses/receipt/item_row_parser.dart';
import 'package:split_debt/features/expenses/receipt/money_parser.dart';
import 'package:split_debt/features/expenses/receipt/row_classifier.dart';
import 'package:split_debt/features/expenses/receipt/rule_based_receipt_parser.dart';

class _MoneyCase {
  const _MoneyCase(this.description, this.row, this.expected, {this.skip});
  final String description;
  final String row;
  final List<int> expected;
  final String? skip;
}

class _ClassifyCase {
  const _ClassifyCase(
    this.description,
    this.row, {
    required this.hasMoney,
    this.expected,
    this.notExpected,
    this.skip,
  });
  final String description;
  final String row;
  final bool hasMoney;
  final RowKind? expected;
  final RowKind? notExpected;
  final String? skip;
}

class _ItemCase {
  const _ItemCase(
    this.description,
    this.row, {
    required this.name,
    required this.qty,
    required this.total,
    this.unit,
    this.skip,
  });
  final String description;
  final String row;
  final String name;
  final int qty;
  final int total;
  final int? unit;
  final String? skip;
}

class _ReceiptCase {
  const _ReceiptCase(
    this.description,
    this.rows, {
    this.itemCount,
    this.firstItemName,
    this.firstItemTotal,
    this.firstItemQty,
    this.secondItemName,
    this.secondItemTotal,
    this.totalAmount,
    this.firstAdjustmentAmount,
    this.expectNullStoreName = false,
    this.skip,
  });
  final String description;
  final List<String> rows;
  final int? itemCount;
  final String? firstItemName;
  final int? firstItemTotal;
  final int? firstItemQty;
  final String? secondItemName;
  final int? secondItemTotal;
  final int? totalAmount;
  final int? firstAdjustmentAmount;
  final bool expectNullStoreName;
  final String? skip;
}

void main() {
  final parser = RuleBasedReceiptParser();

  const moneyCases = <_MoneyCase>[
    // O1
    _MoneyCase('O1: space-separated qty/unit/total (Bia Tiger)', 'Bia Tiger 10 15.000 150.000', [15000, 150000]),
    _MoneyCase('O1: space-separated qty/unit/total (Lau thai)', 'Lau thai 1 350.000 350.000', [350000, 350000]),
    _MoneyCase('O1: space-separated qty/unit/total (Cafe)', 'Cafe 2 125.000 250.000', [125000, 250000]),
    _MoneyCase('O1: space-thousands 120 000', '120 000', [120000]),
    _MoneyCase('O1: space-thousands 1 250 000', '1 250 000', [1250000]),
    // O3
    _MoneyCase('O3: DT phone', 'DT 0901 234 567', []),
    _MoneyCase('O3: Tel phone', 'Tel: 0901 234 567', []),
    _MoneyCase('O3: Hotline phone', 'Hotline 1900 1234', []),
    // R1
    _MoneyCase('R1: leader dots before price', 'Phở bò.........50.000', [50000]),
    _MoneyCase('R1: trailing period after price', 'Tổng cộng: 145.000.', [145000]),
    _MoneyCase('R1: trailing comma-dash after price', '50.000,-', [50000]),
    _MoneyCase('R1: reject decimal 12.5', '12.5', []),
    // R2
    _MoneyCase('R2: item with 02 qty and unformatted prices', 'Trà đá 02 5000 10000', [5000, 10000]),
    _MoneyCase('R2: item with 02 qty and space-thousands prices', 'Phở 02 25 000 50 000', [25000, 50000]),
    _MoneyCase('R2: 8-digit total starting with 1900', 'Tổng cộng 19000000', [19000000]),
    _MoneyCase('R2: Tel landline', 'Tel: 028 3822 1234', []),
    // R3
    _MoneyCase('R3: two space-thousands prices', 'Bia 120 000 240 000', [120000, 240000]),
    _MoneyCase('R3: qty plus two space-thousands prices', 'Bia 2 125 000 250 000', [125000, 250000]),
    _MoneyCase('R3: single 7-digit space-thousands', '1 250 000', [1250000]),
    // 5.4b.1 Barcode
    _MoneyCase('5.4b.1: 13-digit barcode is not money', '8934563123456', []),
    // S1 Decimal .00 / ,00
    _MoneyCase('S1: VAT10% row with .00 decimals', 'VAT10%  3  6,000.00  18,000.00', [6000, 18000]),
    _MoneyCase('S1: comma-thousands with .00', '72,350.00', [72350]),
    _MoneyCase('S1: dot-thousands with ,00', '5.000,00', [5000]),
    _MoneyCase('S1: negative with .00', '-8,250.00', [8250]),
    _MoneyCase('S1: still reject 0.670', '0.670', []),
  ];

  const classifyCases = <_ClassifyCase>[
    // O3
    _ClassifyCase('O3: ĐT phone row', 'ĐT 0901 234 567', hasMoney: false, expected: RowKind.ignore),
    _ClassifyCase('O3: Tel landline row', 'Tel: 028 3822 1234', hasMoney: false, expected: RowKind.ignore),
    // O6
    _ClassifyCase('O6: Sub Total with space', 'Sub Total 300.000', hasMoney: true, expected: RowKind.subtotal),
    // O7
    _ClassifyCase('O7: The Coffee House not ignored', 'The Coffee House', hasMoney: false, notExpected: RowKind.ignore),
    _ClassifyCase('O7: Banh mi the is item', 'Banh mi the 20.000', hasMoney: true, expected: RowKind.item),
    _ClassifyCase('O7: Thanh toán thẻ ignored', 'Thanh toán thẻ 500.000', hasMoney: true, expected: RowKind.ignore),
    _ClassifyCase('O7: Số bàn ignored', 'Số bàn: 12', hasMoney: false, expected: RowKind.ignore),
    _ClassifyCase('O7: Bàn 5 ignored', 'Bàn 5', hasMoney: false, expected: RowKind.ignore),
    // R4
    _ClassifyCase('R4: Thẻ: ignored', 'Thẻ: 300.000', hasMoney: true, expected: RowKind.ignore),
    _ClassifyCase('R4: VISA ignored', 'VISA 300.000', hasMoney: true, expected: RowKind.ignore),
    _ClassifyCase('R4: ATM ignored', 'ATM 300.000', hasMoney: true, expected: RowKind.ignore),
    // R5
    _ClassifyCase('R5: column header ignored', 'Món SL Giá T.Tiền', hasMoney: false, expected: RowKind.ignore),
    _ClassifyCase('R5: table A1 ignored', 'Bàn A1', hasMoney: false, expected: RowKind.ignore),
    // 5.4b.1 Barcode
    _ClassifyCase('5.4b.1: barcode-only row ignored', '8934563123456', hasMoney: false, expected: RowKind.ignore),
    // 5.4b.4 Supermarket ignore keywords
    _ClassifyCase('5.4b.4: Tổng số lượng ignored', 'Tổng số lượng: 12', hasMoney: false, expected: RowKind.ignore),
    _ClassifyCase('5.4b.4: Điểm tích luỹ ignored', 'Điểm tích luỹ 320', hasMoney: false, expected: RowKind.ignore),
    _ClassifyCase('5.4b.4: Quầy 03 ignored', 'Quầy 03', hasMoney: false, expected: RowKind.ignore),
    _ClassifyCase('5.4b.4: Mã KH ignored', 'Mã KH: 001234', hasMoney: true, expected: RowKind.ignore),
    // 5.4b.5 VAT-included total & tax summary table
    _ClassifyCase('5.4b.5: total with đã gồm VAT is total', 'Tổng tiền (đã gồm VAT) 512.000', hasMoney: true, expected: RowKind.total),
    _ClassifyCase('5.4b.5: tax summary table row ignored', 'Thuế suất 8%  Tiền thuế 12.345', hasMoney: true, expected: RowKind.ignore),
  ];

  const itemCases = <_ItemCase>[
    // O1
    _ItemCase('O1: Bia Tiger 10 15.000 150.000', 'Bia Tiger 10 15.000 150.000', name: 'Bia Tiger', qty: 10, unit: 15000, total: 150000),
    // O10
    _ItemCase('O10: qty between unit and total', 'Cafe 25.000 2 50.000', name: 'Cafe', qty: 2, unit: 25000, total: 50000),
    _ItemCase('O10: Combo 2 keeps 2 in name', 'Combo 2  99.000', name: 'Combo 2', qty: 1, total: 99000),
    // R3
    _ItemCase('R3: Bia 2 125 000 250 000', 'Bia 2 125 000 250 000', name: 'Bia', qty: 2, unit: 125000, total: 250000),
    // R9
    _ItemCase('R9: Bia Tiger  3  45.000', 'Bia Tiger  3  45.000', name: 'Bia Tiger', qty: 3, total: 45000),
    _ItemCase('R9: Cơm chiên  2  90.000', 'Cơm chiên  2  90.000', name: 'Cơm chiên', qty: 2, total: 90000),
    _ItemCase('R9: Bia 333  3  15.000  45.000', 'Bia 333  3  15.000  45.000', name: 'Bia 333', qty: 3, unit: 15000, total: 45000),
    // 5.4b.1 Barcode
    _ItemCase('5.4b.1: leading barcode stripped from item name', '8934563123456 Sữa tươi Vinamilk 1L  32.000', name: 'Sữa tươi Vinamilk 1L', qty: 1, total: 32000),
  ];

  const receiptCases = <_ReceiptCase>[
    // O2
    _ReceiptCase(
      'O2: name row followed by numbers-only row',
      ['QUAN AN NGON', 'Bun bo hue', '2  50.000  100.000', 'Com tam  45.000', 'Tong cong  145.000'],
      itemCount: 2,
      firstItemName: 'Bun bo hue',
      firstItemQty: 2,
      firstItemTotal: 100000,
      secondItemName: 'Com tam',
      secondItemTotal: 45000,
      totalAmount: 145000,
    ),
    // O6
    _ReceiptCase(
      'O6: customer paid does not override total',
      ['Mon A 550.000', 'Tổng cộng 550.000', 'Khách thanh toán 600.000'],
      itemCount: 1,
      totalAmount: 550000,
    ),
    // R4
    _ReceiptCase(
      'R4: card payment row not counted as item',
      ['Mon A 300.000', 'Tổng cộng 300.000', 'Thẻ: 300.000'],
      itemCount: 1,
      totalAmount: 300000,
    ),
    // R5
    _ReceiptCase(
      'R5: column header row not merged into item name',
      ['Món SL Giá T.Tiền', 'Phở bò 50.000'],
      itemCount: 1,
      firstItemName: 'Phở bò',
      firstItemTotal: 50000,
    ),
    _ReceiptCase(
      'R5: table A1 row not merged into item name',
      ['Bàn A1', 'Phở bò 50.000'],
      itemCount: 1,
      firstItemName: 'Phở bò',
      firstItemTotal: 50000,
    ),
    // R6
    _ReceiptCase(
      'R6: split-line summary label not merged into item',
      ['Phở 100.000', 'Tiền hàng', '100.000', 'Tổng cộng 100.000'],
      itemCount: 1,
      totalAmount: 100000,
    ),
    // R7
    _ReceiptCase(
      'R7: first split-line item not mistaken for storeName',
      ['HÓA ĐƠN BÁN HÀNG', 'Bun bo hue', '2 50.000 100.000', 'Com tam 45.000'],
      itemCount: 2,
      firstItemName: 'Bun bo hue',
      firstItemTotal: 100000,
      expectNullStoreName: true,
    ),
    // R8
    _ReceiptCase(
      'R8: lower final total overrides earlier subtotal-like total',
      ['Món 500.000', 'Tổng cộng 500.000', 'VAT 10% 50.000', 'Tổng tiền thanh toán 550.000'],
      totalAmount: 550000,
    ),
    _ReceiptCase(
      'R8: lower Thanh toán after discount overrides Tổng tiền',
      ['Món 300.000', 'Tổng tiền 300.000', 'Giảm giá 30.000', 'Thanh toán 270.000'],
      totalAmount: 270000,
    ),
    // 5.4b.2 Weighted items
    _ReceiptCase(
      '5.4b.2: weighted item on split line appends weight to name',
      ['SIÊU THỊ A', 'Thịt heo ba rọi', '0,512 kg x 89.000 = 45.568'],
      itemCount: 1,
      firstItemName: 'Thịt heo ba rọi (0,512 kg)',
      firstItemQty: 1,
      firstItemTotal: 45568,
    ),
    // 5.4b.3 SL x unitPrice
    _ReceiptCase(
      '5.4b.3: split line SL x unitPrice total',
      ['SIÊU THỊ A', 'Mì Hảo Hảo', '2 x 4.500  9.000'],
      itemCount: 1,
      firstItemName: 'Mì Hảo Hảo',
      firstItemQty: 2,
      firstItemTotal: 9000,
    ),
    // 5.4b.5 VAT-included total & tax summary table
    _ReceiptCase(
      '5.4b.5: VAT-included total and tax table ignored',
      ['SIÊU THỊ A', 'Sữa tươi  512.000', 'Tổng tiền (đã gồm VAT) 512.000', 'Thuế suất 8%  Tiền thuế 37.926'],
      itemCount: 1,
      totalAmount: 512000,
    ),
    // 5.4b.6 Item-level promo
    _ReceiptCase(
      '5.4b.6: KM -5.000 below item is discount -5000',
      ['SIÊU THỊ A', 'Sữa tươi  32.000', 'KM -5.000', 'Tổng cộng  27.000'],
      itemCount: 1,
      firstAdjustmentAmount: -5000,
      totalAmount: 27000,
    ),
  ];

  group('money parser regression corpus', () {
    for (final c in moneyCases) {
      test(c.description, () {
        expect(parseMoneyTokens(c.row).map((t) => t.value).toList(), c.expected);
      }, skip: c.skip);
    }
  });

  group('row classifier regression corpus', () {
    for (final c in classifyCases) {
      test(c.description, () {
        final actual = classifyRow(c.row, hasMoney: c.hasMoney);
        if (c.expected != null) expect(actual, c.expected);
        if (c.notExpected != null) expect(actual, isNot(c.notExpected));
      }, skip: c.skip);
    }
  });

  group('item row parser regression corpus', () {
    for (final c in itemCases) {
      test(c.description, () {
        final item = parseItemRow(c.row);
        expect(item, isNotNull);
        expect(item!.name, c.name);
        expect(item.quantity, c.qty);
        expect(item.totalPrice, c.total);
        if (c.unit != null) expect(item.unitPrice, c.unit);
      }, skip: c.skip);
    }
  });

  group('receipt parser regression corpus', () {
    for (final c in receiptCases) {
      test(c.description, () {
        final parsed = parser.parse(c.rows);
        if (c.itemCount != null) expect(parsed.items, hasLength(c.itemCount));
        if (c.firstItemName != null) expect(parsed.items.first.name, c.firstItemName);
        if (c.firstItemQty != null) expect(parsed.items.first.quantity, c.firstItemQty);
        if (c.firstItemTotal != null) expect(parsed.items.first.totalPrice, c.firstItemTotal);
        if (c.secondItemName != null) expect(parsed.items[1].name, c.secondItemName);
        if (c.secondItemTotal != null) expect(parsed.items[1].totalPrice, c.secondItemTotal);
        if (c.totalAmount != null) expect(parsed.totalAmount, c.totalAmount);
        if (c.firstAdjustmentAmount != null) {
          expect(parsed.adjustments, isNotEmpty);
          expect(parsed.adjustments.first.amount, c.firstAdjustmentAmount);
        }
        if (c.expectNullStoreName) expect(parsed.storeName, isNull);
      }, skip: c.skip);
    }

    test('5.4b.7: 40-item supermarket receipt parses all 40 items', () {
      final rows = <String>[
        'SIÊU THỊ BÁCH HOÁ',
        for (var i = 1; i <= 40; i++) 'Sản phẩm số $i  10.000',
        'Tổng cộng  400.000',
      ];
      final parsed = parser.parse(rows);
      expect(parsed.items, hasLength(40));
      expect(parsed.totalAmount, 400000);
    });
  });
}
