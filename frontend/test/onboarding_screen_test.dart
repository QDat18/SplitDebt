import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:split_debt/features/auth/onboarding_screen.dart';

void main() {
  testWidgets('pages use icons, not emoji, and advance on Tiếp tục',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));

    expect(find.byIcon(kOnboardingPages[0].icon), findsOneWidget);
    expect(find.text(kOnboardingPages[0].title), findsOneWidget);
    for (final e in ['✂', '💸', '📈']) {
      expect(find.textContaining(e), findsNothing);
    }

    await tester.tap(find.text('Tiếp tục'));
    await tester.pumpAndSettle();
    expect(find.text(kOnboardingPages[1].title), findsOneWidget);

    await tester.tap(find.text('Tiếp tục'));
    await tester.pumpAndSettle();
    expect(find.text(kOnboardingPages[2].title), findsOneWidget);
    expect(find.text('Bắt đầu'), findsOneWidget);
  });
}
