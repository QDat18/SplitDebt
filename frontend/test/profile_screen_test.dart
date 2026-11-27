import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:split_debt/features/profile/personal_info_screen.dart';
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

  testWidgets('settings items navigate to dedicated screens on tap',
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

    // 1. Tap Thông tin cá nhân pushes PersonalInfoScreen
    await tester.tap(find.text('Thông tin cá nhân'));
    await tester.pumpAndSettle();
    expect(find.text('Hồ sơ người dùng'), findsOneWidget);
    // Tap back button
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Tài khoản'), findsOneWidget);

    // 2. Tap Trợ giúp pushes HelpScreen
    final helpFinder = find.text('Trợ giúp');
    await tester.ensureVisible(helpFinder);
    await tester.tap(helpFinder);
    await tester.pumpAndSettle();
    expect(find.text('Quy trình sử dụng SplitDebt'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    // 3. Tap Giới thiệu pushes AboutScreen
    final aboutFinder = find.text('Giới thiệu');
    await tester.ensureVisible(aboutFinder);
    await tester.tap(aboutFinder);
    await tester.pumpAndSettle();
    expect(find.text('XÉN NỢ (SplitDebt)'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    // 4. Tap Tiền tệ pushes CurrencySettingsScreen
    final currencyFinder = find.text('Tiền tệ');
    await tester.ensureVisible(currencyFinder);
    await tester.tap(currencyFinder);
    await tester.pumpAndSettle();
    expect(find.text('Đơn vị tiền tệ chính'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    // 5. Tap Ngôn ngữ pushes LanguageSettingsScreen
    final langFinder = find.text('Ngôn ngữ');
    await tester.ensureVisible(langFinder);
    await tester.tap(langFinder);
    await tester.pumpAndSettle();
    expect(find.text('Ngôn ngữ hiển thị'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
  });

  testWidgets('personal info screen displays avatar and camera badge',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: PersonalInfoScreen(
          name: 'Nguyễn Văn A',
          email: 'a@example.com',
          avatarUrl: null,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Nguyễn Văn A'), findsWidgets);
    expect(find.text('a@example.com'), findsOneWidget);
    expect(find.byIcon(Icons.camera_alt_rounded), findsOneWidget);
    expect(find.text('Nhấn vào ảnh để thay đổi'), findsOneWidget);

    // Tapping avatar opens image source picker bottom sheet
    await tester.tap(find.byType(CircleAvatar).first);
    await tester.pumpAndSettle();

    expect(find.text('Chọn ảnh đại diện'), findsOneWidget);
    expect(find.text('Chụp ảnh mới'), findsOneWidget);
    expect(find.text('Chọn từ thư viện'), findsOneWidget);
  });
}
