import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:split_debt/core/theme/app_theme.dart';
import 'package:split_debt/features/auth/login_screen.dart';
import 'package:split_debt/features/help/quick_guide_screen.dart';
import 'package:split_debt/main.dart';

Widget app(Widget child) => MaterialApp(theme: AppTheme.lightTheme, home: child);

/// PremiumBackground intentionally contains a repeating animation, so using
/// pumpAndSettle() on onboarding/guide screens will never settle. Pump a bounded
/// number of frames until the expected UI appears instead.
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

Future<void> tapAndWait(
  WidgetTester tester,
  Finder button,
  Finder expected,
) async {
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pump();
  // Both onboarding and quick-guide use PageController animations of 260 ms.
  // Finish that transition before interacting with the next-page button again.
  await tester.pump(const Duration(milliseconds: 320));
  await pumpUntilFound(tester, expected);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    onboardingDone = false;
  });

  testWidgets('onboarding skip stores completion and moves to login gate', (tester) async {
    await tester.pumpWidget(app(const OnboardingScreen()));
    expect(find.text('Chia tiền nhóm dễ dàng & công bằng'), findsOneWidget);

    await tapAndWait(
      tester,
      find.text('Bỏ qua'),
      find.byType(LoginScreen),
    );

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('onboarding_done'), true);
    expect(onboardingDone, true);
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('onboarding can be completed through all three pages', (tester) async {
    await tester.pumpWidget(app(const OnboardingScreen()));

    await tapAndWait(
      tester,
      find.widgetWithText(FilledButton, 'Tiếp tục'),
      find.text('Thanh toán gọn, không chuyển vòng vèo'),
    );
    expect(find.text('Thanh toán gọn, không chuyển vòng vèo'), findsOneWidget);

    await tapAndWait(
      tester,
      find.widgetWithText(FilledButton, 'Tiếp tục'),
      find.text('Biết mình đã chi bao nhiêu theo thời gian'),
    );
    expect(find.text('Biết mình đã chi bao nhiêu theo thời gian'), findsOneWidget);
    expect(find.text('Bắt đầu trải nghiệm'), findsOneWidget);

    await tapAndWait(
      tester,
      find.widgetWithText(FilledButton, 'Bắt đầu trải nghiệm'),
      find.byType(LoginScreen),
    );
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('quick guide walks through home group expense and settlement concepts', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: FilledButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const QuickGuideScreen()),
              ),
              child: const Text('Mở hướng dẫn'),
            ),
          ),
        ),
      ),
    ));

    await tapAndWait(
      tester,
      find.text('Mở hướng dẫn'),
      find.textContaining('Nắm nhanh tình hình'),
    );
    expect(find.textContaining('Nắm nhanh tình hình'), findsOneWidget);

    for (final title in [
      'Tạo nhóm trước khi chia tiền',
      'Chọn cách chia phù hợp',
      'Quyết toán ít giao dịch hơn',
    ]) {
      await tapAndWait(
        tester,
        find.widgetWithText(FilledButton, 'Tiếp tục'),
        find.text(title),
      );
      expect(find.text(title), findsOneWidget);
    }

    await tapAndWait(
      tester,
      find.widgetWithText(FilledButton, 'Hoàn tất hướng dẫn'),
      find.text('Mở hướng dẫn'),
    );
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('quick_guide_completed'), true);
    expect(find.text('Mở hướng dẫn'), findsOneWidget);
  });
}
