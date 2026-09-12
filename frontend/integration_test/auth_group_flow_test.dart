import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:split_debt/core/theme/app_theme.dart';
import 'package:split_debt/data/api.dart';
import 'package:split_debt/features/auth/login_screen.dart';
import 'package:split_debt/features/home/home_screen.dart';
import 'package:split_debt/main.dart';

Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  int maxPumps = 120,
  Duration step = const Duration(milliseconds: 100),
}) async {
  for (var i = 0; i < maxPumps; i++) {
    if (finder.evaluate().isNotEmpty) return;
    await tester.pump(step);
  }
  expect(finder, findsOneWidget);
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pump();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('real API flow: register -> login -> create group', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await Session.clear();
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final email = 'flutter.e2e.$stamp@example.com';
    const password = 'password123';

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: const SessionGate(),
    ));
    await pumpUntilFound(tester, find.byType(LoginScreen));
    expect(find.byType(LoginScreen), findsOneWidget);

    await tapVisible(tester, find.text('Đăng ký'));
    await pumpUntilFound(tester, find.text('Tạo tài khoản SplitDebt'));

    final registerFields = find.byType(TextFormField);
    await tester.enterText(registerFields.at(0), 'Flutter E2E User');
    await tester.enterText(registerFields.at(1), email);
    await tester.enterText(registerFields.at(3), password);
    await tester.ensureVisible(find.byType(Checkbox));
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tapVisible(tester, find.widgetWithText(FilledButton, 'Tạo tài khoản'));
    await pumpUntilFound(tester, find.text('Tạo tài khoản thành công'));
    expect(find.text('Tạo tài khoản thành công'), findsOneWidget);

    await tapVisible(tester, find.text('Đăng nhập ngay'));
    await pumpUntilFound(tester, find.byType(LoginScreen));

    final loginFields = find.byType(TextFormField);
    await tester.enterText(loginFields.at(0), email);
    await tester.enterText(loginFields.at(1), password);
    await tapVisible(tester, find.widgetWithText(FilledButton, 'Đăng nhập'));
    await pumpUntilFound(tester, find.byType(HomeScreen));
    expect(find.byType(HomeScreen), findsOneWidget);

    // New accounts are offered the quick guide once. Dismiss it for this flow.
    for (var i = 0; i < 15 && find.text('Để sau').evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    if (find.text('Để sau').evaluate().isNotEmpty) {
      await tapVisible(tester, find.text('Để sau'));
      await tester.pump(const Duration(milliseconds: 350));
    }

    final createFirst = find.text('Tạo nhóm đầu tiên');
    if (createFirst.evaluate().isNotEmpty) {
      await tapVisible(tester, createFirst);
    } else {
      await tapVisible(tester, find.widgetWithText(FilledButton, 'Tạo nhóm').first);
    }
    await pumpUntilFound(tester, find.text('Tạo nhóm mới'));

    final createFields = find.byType(TextFormField);
    await tester.enterText(createFields.at(0), 'E2E Group $stamp');
    await tapVisible(tester, find.widgetWithText(FilledButton, 'Tạo nhóm'));
    await pumpUntilFound(tester, find.text('E2E Group $stamp'));

    expect(find.text('E2E Group $stamp'), findsOneWidget);
    expect(Session.authenticated.value, true);
  });
}
