import 'package:flutter_test/flutter_test.dart';
import 'package:split_debt/features/expenses/receipt/row_classifier.dart';

void main() {
  test('cash given and change are ignored', () {
    expect(classifyRow('Tiền khách đưa 500.000', hasMoney: true), RowKind.ignore);
    expect(classifyRow('Tiền thừa 164.400', hasMoney: true), RowKind.ignore);
  });

  test('column header without money is ignored', () {
    expect(
      classifyRow('Tên món  SL  Đơn giá  Thành tiền', hasMoney: false),
      RowKind.ignore,
    );
  });

  test('final total vs subtotal', () {
    expect(classifyRow('Tổng thanh toán 335.600', hasMoney: true), RowKind.total);
    expect(classifyRow('Tổng tiền hàng 320.000', hasMoney: true), RowKind.subtotal);
  });

  test('vat included is ignored, vat amount is vat', () {
    expect(classifyRow('Đã bao gồm VAT 8%', hasMoney: false), RowKind.ignore);
    expect(classifyRow('VAT 8%  25.600', hasMoney: true), RowKind.vat);
  });

  test('service and discount', () {
    expect(classifyRow('Phí dịch vụ 5% 16.000', hasMoney: true), RowKind.service);
    expect(classifyRow('Giảm giá 10.000', hasMoney: true), RowKind.discount);
  });

  test('item row', () {
    expect(
      classifyRow('Thịt bò ba chỉ  2  120.000  240.000', hasMoney: true),
      RowKind.item,
    );
  });

  test('phone and address are ignored', () {
    expect(classifyRow('ĐT: 0901 234 567', hasMoney: false), RowKind.ignore);
    expect(classifyRow('Địa chỉ: 12 Lê Lợi', hasMoney: false), RowKind.ignore);
  });

  test('phone rows are ignored', () {
    expect(classifyRow('ĐT 0901 234 567', hasMoney: false), RowKind.ignore);
    expect(classifyRow('Tel: 028 3822 1234', hasMoney: false), RowKind.ignore);
  });

  test('"Sub Total" with a space is subtotal', () {
    expect(classifyRow('Sub Total 300.000', hasMoney: true), RowKind.subtotal);
  });
}
