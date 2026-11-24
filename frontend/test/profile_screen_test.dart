import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:split_debt/features/profile/profile_screen.dart';

void main() {
  testWidgets('profile screen renders HIG sections and logout dialog',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: ProfileScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Check user info and sections
    expect(find.text('Tài khoản'), findsOneWidget);
    expect(find.text('Thông tin cá nhân'), findsOneWidget);
    expect(find.text('Ứng dụng'), findsOneWidget);
    expect(find.text('Thông báo'), findsOneWidget);
    expect(find.text('Tiền tệ'), findsOneWidget);
    expect(find.text('VND'), findsOneWidget);
    expect(find.text('Ngôn ngữ'), findsOneWidget);
    expect(find.text('Tiếng Việt'), findsOneWidget);
    expect(find.text('Hỗ trợ'), findsOneWidget);
    expect(find.text('Trợ giúp'), findsOneWidget);
    expect(find.text('Giới thiệu'), findsOneWidget);

    final logoutFinder = find.text('Đăng xuất');
    await tester.ensureVisible(logoutFinder);
    expect(logoutFinder, findsOneWidget);

    // Tap Đăng xuất opens confirmation dialog
    await tester.tap(logoutFinder);
    await tester.pumpAndSettle();

    expect(find.text('Đăng xuất?'), findsOneWidget);
    expect(
        find.text('Bạn sẽ cần đăng nhập lại để dùng ứng dụng.'), findsOneWidget);
    expect(find.text('Huỷ'), findsOneWidget);

    // Tapping Huỷ closes dialog without crashing
    await tester.tap(find.text('Huỷ'));
    await tester.pumpAndSettle();

    expect(find.text('Đăng xuất?'), findsNothing);
  });
}
