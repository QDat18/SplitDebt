import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:split_debt/data/api.dart';
import 'package:split_debt/core/theme/app_theme.dart';
import 'package:split_debt/widgets/design.dart';

void main() {
  test('money parsing keeps integer minor units', () {
    expect(parseMoney('10.01', 'USD'), 1001);
    expect(parseMoney('0.10', 'USD'), 10);
    expect(parseMoney('10.1', 'VND'), isNull);
    expect(parseMoney('0', 'USD'), isNull);
    expect(parseMoney('-1', 'USD'), isNull);
    expect(parseMoney('1.001', 'USD'), isNull);
    expect(parseMoney('1000000000001', 'VND'), isNull);
  });

  testWidgets('hero supports narrow screens and large text', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      home: const MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(1.5)),
        child: Scaffold(
          body: SingleChildScrollView(
            child: HeroCard(
              eyebrow: 'Số dư của bạn',
              title: 'Chia tiền rõ ràng.',
              subtitle: 'Chi tiêu nhóm và công nợ trong một nơi.',
            ),
          ),
        ),
      ),
    ));
    expect(tester.takeException(), isNull);
  });

  testWidgets('group controls stay usable on a narrow dark screen', (tester) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.darkTheme,
      home: MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
        child: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              const BrandMark(size: 112),
              const BalancePair(currency: 'VND', receivable: 1000000000000, payable: 0),
              GroupTabs(selected: 0, onChanged: (_) {}),
              BrandButton(label: 'Xác nhận thanh toán', onPressed: () {}),
            ]),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Chi tiêu'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('busy save action cannot submit again', (tester) async {
    var calls = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: BrandButton(label: 'Lưu khoản chi', busy: true, onPressed: () => calls++)),
    ));
    await tester.tap(find.byType(FilledButton));
    expect(calls, 0);
  });
}
