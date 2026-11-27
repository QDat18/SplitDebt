import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:split_debt/core/localization/app_strings.dart';
import 'package:split_debt/core/localization/locale_provider.dart';

void main() {
  test('LocaleNotifier defaults to vi and persists language switch', () async {
    SharedPreferences.setMockInitialValues({});
    final notifier = LocaleNotifier();
    await notifier.loadSavedLocale();
    expect(notifier.state.languageCode, 'vi');

    await notifier.setLocale(const Locale('en'));
    expect(notifier.state.languageCode, 'en');

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('app_language'), 'en');

    // Reloading in a new notifier reads persisted value
    final reloaded = LocaleNotifier();
    await reloaded.loadSavedLocale();
    expect(reloaded.state.languageCode, 'en');
  });

  test('AppStrings returns Vietnamese or English based on locale', () {
    expect(AppStrings.tr(const Locale('vi'), 'Ngôn ngữ', 'Language'), 'Ngôn ngữ');
    expect(AppStrings.tr(const Locale('en'), 'Ngôn ngữ', 'Language'), 'Language');
  });
}

