import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:split_debt/core/widgets/app_mark.dart';
import 'package:split_debt/features/auth/splash_brand.dart';

void main() {
  Widget host({bool disableAnimations = false}) => MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: disableAnimations),
          child: const Scaffold(body: SplashBrand()),
        ),
      );

  testWidgets('shows title, tagline and travel app mark without emoji', (tester) async {
    await tester.pumpWidget(host());
    // Không dùng pumpAndSettle: vòng xoay chờ chạy mãi nên không bao giờ "settle".
    await tester.pump(const Duration(seconds: 1));

    expect(find.text(kSplashTitle), findsOneWidget);
    expect(find.text(kSplashTagline), findsOneWidget);
    expect(find.byIcon(kAppMarkIcon), findsOneWidget);
    expect(find.textContaining('✂'), findsNothing);
  });

  testWidgets('is fully visible immediately when animations are disabled',
      (tester) async {
    await tester.pumpWidget(host(disableAnimations: true));
    await tester.pump();

    final fades = tester.widgetList<FadeTransition>(find.byType(FadeTransition));
    expect(fades, isNotEmpty);
    for (final f in fades) {
      expect(f.opacity.value, 1.0);
    }
  });
}
