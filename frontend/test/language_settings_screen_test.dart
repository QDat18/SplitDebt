import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:split_debt/core/localization/app_strings.dart';
import 'package:split_debt/core/localization/locale_provider.dart';
import 'package:split_debt/features/profile/language_settings_screen.dart';

void main() {
  testWidgets('switches language between Vietnamese and English',
      (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      ProviderScope(
        child: Consumer(
          builder: (context, ref, _) {
            final locale = ref.watch(localeProvider);
            return AppLocaleScope(
              locale: locale,
              child: const MaterialApp(
                home: LanguageSettingsScreen(),
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ngôn ngữ'), findsOneWidget);
    expect(find.text('Tiếng Việt'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    expect(find.text('Language'), findsOneWidget);

    await tester.tap(find.text('Tiếng Việt'));
    await tester.pumpAndSettle();

    expect(find.text('Ngôn ngữ'), findsOneWidget);
  });
}
