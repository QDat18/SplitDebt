import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:split_debt/features/expenses/ocr/receipt_data.dart';

String _receipt({
  Object? date = '2026-11-26',
  Object? merchant = 'Quán cơm',
  Object? amount,
  int total = 90000,
  int quantity = 2,
}) => jsonEncode({
  'type': 'splitdebt_receipt',
  'version': 1,
  'currency': 'VND',
  'total': total,
  'date': date,
  'merchant': merchant,
  'items': [
    {
      'name': ' Cơm gà ',
      'quantity': quantity,
      'unitPrice': 45000,
      if (amount != null) 'amount': amount,
    },
  ],
});

String _tag(String key, String value) =>
    '$key${value.length.toString().padLeft(2, '0')}$value';
String _withCrc(String raw) {
  raw += '6304';
  var crc = 0xffff;
  for (final byte in raw.codeUnits) {
    crc ^= byte << 8;
    for (var i = 0; i < 8; i++) {
      crc = ((crc & 0x8000) != 0 ? (crc << 1) ^ 0x1021 : crc << 1) & 0xffff;
    }
  }
  return '$raw${crc.toRadixString(16).padLeft(4, '0').toUpperCase()}';
}

String _payment({
  String? amount = '90000',
  String aid = 'A000000727',
  String? extra,
}) => _withCrc(
  [
    _tag('00', '01'),
    _tag('01', '12'),
    _tag(
      '38',
      _tag('00', aid) +
          _tag('01', _tag('00', '970436') + _tag('01', '1234567890')) +
          _tag('02', 'QRIBFTTA'),
    ),
    _tag('53', '704'),
    if (amount != null) _tag('54', amount),
    _tag('58', 'VN'),
    if (extra != null) extra,
  ].join(),
);

void main() {
  test('structured receipt preserves quantity and line amount', () {
    final result = parseReceiptQr(_receipt());
    expect(result['total'], 90000);
    expect(result['items'][0]['amount'], 90000);
    expect(result['items'][0]['name'], 'Cơm gà');
    expect(result['warnings'], isEmpty);
  });
  test('copied QR accepts whitespace and BOM', () {
    expect(parseReceiptQr(' \uFEFF${_receipt()} \n')['total'], 90000);
  });
  test('arbitrary invoice URLs are never followed', () {
    expect(
      () => parseReceiptQr('https://example.com/invoice/123'),
      throwsFormatException,
    );
  });
  test('negative quantities and inconsistent line amounts are rejected', () {
    expect(() => parseReceiptQr(_receipt(quantity: -2)), throwsFormatException);
    expect(
      () => parseReceiptQr(_receipt(amount: 95000)),
      throwsFormatException,
    );
  });
  test('invalid metadata cannot crash the review form', () {
    expect(
      () => parseReceiptQr(_receipt(merchant: ['Unexpected'])),
      throwsFormatException,
    );
    final result = parseReceiptQr(_receipt(date: {'year': 2026}));
    expect(result['date'], isNull);
    expect(result['warnings'], isNotEmpty);
  });
  test('overflow calendar dates are not silently normalized', () {
    final result = parseReceiptQr(_receipt(date: '2026-02-31'));
    expect(result['date'], isNull);
    expect(result['warnings'], isNotEmpty);
  });
  test('tax or discount differences are explicitly flagged', () {
    final result = parseReceiptQr(_receipt(total: 99000));
    expect(result['total'], 99000);
    expect(result['items'][0]['amount'], 90000);
    expect(result['warnings'], isNotEmpty);
  });
  test('VietQR amount imports without inventing date or line items', () {
    final result = parseReceiptQr(_payment());
    expect(result['total'], 90000);
    expect(result['date'], isNull);
    expect(result['items'], isEmpty);
    expect(result['warnings'], isNotEmpty);
  });
  test('static VietQR does not invent an amount', () {
    expect(parseReceiptQr(_payment(amount: null))['total'], isNull);
  });
  test('whole VND decimal amounts are supported', () {
    expect(parseReceiptQr(_payment(amount: '90000.00'))['total'], 90000);
    expect(parseReceiptQr(_payment(amount: '90000.0'))['total'], 90000);
  });
  test('fractional and zero VND payment amounts are rejected', () {
    expect(
      () => parseReceiptQr(_payment(amount: '90000.50')),
      throwsFormatException,
    );
    expect(() => parseReceiptQr(_payment(amount: '0')), throwsFormatException);
  });
  test('valid CRC cannot hide duplicate tags or a false merchant template', () {
    expect(
      () => parseReceiptQr(_payment(extra: _tag('54', '10000'))),
      throwsFormatException,
    );
    expect(
      () => parseReceiptQr(_payment(aid: 'XA000000727')),
      throwsFormatException,
    );
  });
  test('corrupted CRC is rejected', () {
    final qr = _payment();
    final damaged = '${qr.substring(0, qr.length - 4)}0000';
    expect(() => parseReceiptQr(damaged), throwsFormatException);
  });
  test('truncated TLV is rejected', () {
    expect(
      () => parseReceiptQr('0002013899short63040000'),
      throwsFormatException,
    );
  });
}
