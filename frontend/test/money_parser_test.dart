import 'package:flutter_test/flutter_test.dart';
import 'package:split_debt/features/expenses/receipt/money_parser.dart';

void main() {
  test('parses dot, comma, space and plain thousands', () {
    expect(parseMoneyTokens('120.000').map((e) => e.value).toList(), [120000]);
    expect(parseMoneyTokens('120,000').map((e) => e.value).toList(), [120000]);
    expect(parseMoneyTokens('120 000').map((e) => e.value).toList(), [120000]);
    expect(parseMoneyTokens('120000').map((e) => e.value).toList(), [120000]);
  });

  test('parses k suffix and currency suffixes', () {
    expect(parseMoneyTokens('45k').map((e) => e.value).toList(), [45000]);
    expect(parseMoneyTokens('45K').map((e) => e.value).toList(), [45000]);
    expect(parseMoneyTokens('1.250.000đ').map((e) => e.value).toList(), [1250000]);
    expect(parseMoneyTokens('1,250,000 VND').map((e) => e.value).toList(), [1250000]);
  });

  test('fixes OCR letters only inside numeric tokens', () {
    expect(parseMoneyTokens('12O.OOO').map((e) => e.value).toList(), [120000]);
    expect(parseMoneyTokens('Bia SOL'), isEmpty);
  });

  test('rejects decimals and out-of-range values', () {
    expect(parseMoneyTokens('12.5'), isEmpty);
    expect(parseMoneyTokens('500'), isEmpty);
    expect(parseMoneyTokens('200.000.000'), isEmpty);
  });

  test('returns multiple tokens in order', () {
    final tokens = parseMoneyTokens('2  120.000  240.000');
    expect(tokens.map((e) => e.value).toList(), [120000, 240000]);
  });

  test('normalizeForMatch strips Vietnamese marks', () {
    expect(normalizeForMatch('Tổng Thanh Toán'), 'tong thanh toan');
  });

  test('space-separated qty / unit / total stay separate', () {
    expect(
      parseMoneyTokens('Bia Tiger 10 15.000 150.000')
          .map((e) => e.value)
          .toList(),
      [15000, 150000],
    );
    expect(
      parseMoneyTokens('Lau thai 1 350.000 350.000')
          .map((e) => e.value)
          .toList(),
      [350000, 350000],
    );
    expect(
      parseMoneyTokens('Cafe 2 125.000 250.000')
          .map((e) => e.value)
          .toList(),
      [125000, 250000],
    );
  });

  test('space as thousands separator only when the token has no dot/comma', () {
    expect(parseMoneyTokens('120 000').map((e) => e.value).toList(), [120000]);
    expect(
      parseMoneyTokens('1 250 000').map((e) => e.value).toList(),
      [1250000],
    );
  });

  test('phone numbers are not money', () {
    expect(parseMoneyTokens('DT 0901 234 567'), isEmpty);
    expect(parseMoneyTokens('Tel: 0901 234 567'), isEmpty);
    expect(parseMoneyTokens('Hotline 1900 1234'), isEmpty);
  });
}
