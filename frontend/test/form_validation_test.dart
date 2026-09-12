import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:split_debt/core/theme/app_theme.dart';
import 'package:split_debt/data/api.dart';
import 'package:split_debt/features/home/forms.dart';

Widget app(Widget child) => MaterialApp(theme: AppTheme.lightTheme, home: child);

Future<void> tapFilledButton(WidgetTester tester, String label) async {
  final button = find.widgetWithText(FilledButton, label);
  expect(button, findsOneWidget);
  await tester.ensureVisible(button);
  await tester.pump();
  await tester.tap(button);
  await tester.pump();
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    Api.resetTestOverrides();
    await Session.clear();
  });

  tearDown(() async {
    Api.resetTestOverrides();
    await Session.clear();
  });

  testWidgets('create group requires a name', (tester) async {
    await tester.pumpWidget(app(const CreateGroupScreen()));
    await tapFilledButton(tester, 'Tạo nhóm');
    expect(find.text('Nhập tên nhóm.'), findsOneWidget);
  });

  testWidgets('join group requires an invite code', (tester) async {
    await tester.pumpWidget(app(const JoinGroupScreen()));
    await tapFilledButton(tester, 'Tham gia');
    expect(find.text('Nhập mã mời.'), findsOneWidget);
  });

  testWidgets('edit profile rejects a name shorter than two characters', (tester) async {
    await tester.pumpWidget(app(const EditProfileScreen(name: 'A')));
    await tapFilledButton(tester, 'Lưu thay đổi');
    expect(find.text('Nhập họ tên.'), findsOneWidget);
  });

  testWidgets('add member accepts email or phone and rejects invalid identifier', (tester) async {
    await tester.pumpWidget(app(const AddMemberScreen(groupId: 1)));
    await tester.enterText(find.byType(TextFormField), 'not-email');
    await tapFilledButton(tester, 'Thêm vào nhóm');
    expect(find.text('Số điện thoại chưa hợp lệ.'), findsOneWidget);
  });
}
