import 'package:flutter_test/flutter_test.dart';
import 'package:split_debt/features/expenses/receipt/item_row_parser.dart';

void main() {
  test('qty, unit price, total', () {
    final item = parseItemRow('Thịt bò ba chỉ  2  120.000  240.000');
    expect(item, isNotNull);
    expect(item!.name, 'Thịt bò ba chỉ');
    expect(item.quantity, 2);
    expect(item.unitPrice, 120000);
    expect(item.totalPrice, 240000);
  });

  test('only total', () {
    final item = parseItemRow('Nước lẩu Thái  80.000');
    expect(item, isNotNull);
    expect(item!.name, 'Nước lẩu Thái');
    expect(item.quantity, 1);
    expect(item.unitPrice, isNull);
    expect(item.totalPrice, 80000);
  });

  test('x2 notation', () {
    final item = parseItemRow('Trà đá x2  10.000');
    expect(item, isNotNull);
    expect(item!.name, 'Trà đá');
    expect(item.quantity, 2);
    expect(item.totalPrice, 10000);
  });

  test('number inside name stays in name', () {
    final bia = parseItemRow('Bia 333  3  15.000  45.000');
    expect(bia, isNotNull);
    expect(bia!.name, 'Bia 333');
    expect(bia.quantity, 3);
    expect(bia.unitPrice, 15000);
    expect(bia.totalPrice, 45000);

    final combo = parseItemRow('Combo 2 người  299.000');
    expect(combo, isNotNull);
    expect(combo!.name, 'Combo 2 người');
    expect(combo.quantity, 1);
    expect(combo.totalPrice, 299000);
  });

  test('qty without unit price stays in name unless xN notation', () {
    final item = parseItemRow('Combo 2  99.000');
    expect(item, isNotNull);
    expect(item!.name, 'Combo 2');
    expect(item.quantity, 1);
    expect(item.totalPrice, 99000);
    expect(item.unitPrice, isNull);
  });

  test('qty between unit price and total', () {
    final item = parseItemRow('Cafe 25.000 2 50.000');
    expect(item, isNotNull);
    expect(item!.name, 'Cafe');
    expect(item.quantity, 2);
    expect(item.unitPrice, 25000);
    expect(item.totalPrice, 50000);
  });

  test('item rows with 3 numbers parse fully', () {
    final item = parseItemRow('Bia Tiger 10 15.000 150.000');
    expect(item, isNotNull);
    expect(item!.name, 'Bia Tiger');
    expect(item.quantity, 10);
    expect(item.unitPrice, 15000);
    expect(item.totalPrice, 150000);
  });
}
