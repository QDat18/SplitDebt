import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:split_debt/core/theme/app_theme.dart';
import 'package:split_debt/data/api.dart';
import 'package:split_debt/features/auth/login_screen.dart';
import 'package:split_debt/features/auth/register_screen.dart';

Widget app(Widget child) => MaterialApp(theme: AppTheme.lightTheme, home: child);

EditableText editableInside(Finder textFormField) {
  final finder = find.descendant(
    of: textFormField,
    matching: find.byType(EditableText),
  );
  expect(finder, findsOneWidget);
  return finder.evaluate().single.widget as EditableText;
}

Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  int maxPumps = 40,
  Duration step = const Duration(milliseconds: 50),
}) async {
  for (var i = 0; i < maxPumps; i++) {
    if (finder.evaluate().isNotEmpty) return;
    await tester.pump(step);
  }
  expect(finder, findsOneWidget);
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    Api.resetTestOverrides();
    Api.baseUrlOverride = 'http://splitdebt.test/api';
    await Session.clear();
  });

  tearDown(() async {
    Api.resetTestOverrides();
    await Session.clear();
  });

  testWidgets('login validates email and password before sending a request', (tester) async {
    var calls = 0;
    Api.clientFactory = () => MockClient((_) async {
      calls++;
      return http.Response('{}', 200);
    });
    await tester.pumpWidget(app(const LoginScreen()));

    await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
    await tester.pump();

    expect(find.text('Nhập email hợp lệ.'), findsOneWidget);
    expect(find.text('Nhập mật khẩu.'), findsOneWidget);
    expect(calls, 0);
  });

  testWidgets('login password can be shown and hidden', (tester) async {
    await tester.pumpWidget(app(const LoginScreen()));
    final passwordField = find.byType(TextFormField).at(1);

    expect(editableInside(passwordField).obscureText, true);

    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pump();

    expect(editableInside(passwordField).obscureText, false);
    expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
  });

  testWidgets('successful login updates Session and persists token', (tester) async {
    Api.clientFactory = () => MockClient((request) async {
      return http.Response(jsonEncode({
        'token': 'ui-test-token',
        'user': {'id': 77, 'email': 'user@example.com', 'name': 'UI User'}
      }), 200);
    });
    await tester.pumpWidget(app(const LoginScreen()));
    await tester.enterText(find.byType(TextFormField).at(0), 'user@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
    await tester.pump(const Duration(milliseconds: 900));

    expect(Session.authenticated.value, true);
    expect(Session.userId, 77);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('auth_token'), 'ui-test-token');
  });

  testWidgets('register validates required fields before network request', (tester) async {
    var calls = 0;
    Api.clientFactory = () => MockClient((_) async {
      calls++;
      return http.Response('{}', 200);
    });
    await tester.pumpWidget(app(const RegisterScreen()));
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Tạo tài khoản'));
    await tester.tap(find.widgetWithText(FilledButton, 'Tạo tài khoản'));
    await tester.pump();

    expect(find.text('Nhập họ tên.'), findsOneWidget);
    expect(find.text('Nhập email hợp lệ.'), findsOneWidget);
    expect(find.text('Mật khẩu cần ít nhất 8 ký tự.'), findsOneWidget);
    expect(calls, 0);
  });

  testWidgets('register requires terms acceptance and shows friendly feedback', (tester) async {
    var calls = 0;
    Api.clientFactory = () => MockClient((_) async {
      calls++;
      return http.Response('{}', 200);
    });
    await tester.pumpWidget(app(const RegisterScreen()));
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Valid User');
    await tester.enterText(fields.at(1), 'valid@example.com');
    await tester.enterText(fields.at(3), 'password123');
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Tạo tài khoản'));
    await tester.tap(find.widgetWithText(FilledButton, 'Tạo tài khoản'));
    await tester.pump();

    expect(find.text('Có lỗi xảy ra'), findsOneWidget);
    expect(find.textContaining('đồng ý Điều khoản'), findsOneWidget);
    expect(calls, 0);
  });

  testWidgets('successful registration displays success dialog', (tester) async {
    Api.clientFactory = () => MockClient((request) async {
      expect(request.url.path, '/api/auth/register');
      return http.Response(jsonEncode({'id': 1, 'message': 'ok'}), 200);
    });
    await tester.pumpWidget(app(const RegisterScreen()));
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Valid User');
    await tester.enterText(fields.at(1), 'valid@example.com');
    await tester.enterText(fields.at(2), '0900000000');
    await tester.enterText(fields.at(3), 'password123');
    await tester.ensureVisible(find.byType(Checkbox));
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Tạo tài khoản'));
    await tester.tap(find.widgetWithText(FilledButton, 'Tạo tài khoản'));
    await tester.pump();
    await pumpUntilFound(tester, find.text('Tạo tài khoản thành công'));

    expect(find.text('Tạo tài khoản thành công'), findsOneWidget);
    expect(find.text('Đăng nhập ngay'), findsOneWidget);
  });
}
