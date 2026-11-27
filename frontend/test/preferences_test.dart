import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:split_debt/core/state/app_sync.dart';

void main() {
  test('Theme supports light, dark and device mode', () {
    expect(parseBackendThemeMode('light'), ThemeMode.light);
    expect(parseBackendThemeMode(' DARK '), ThemeMode.dark);
    expect(parseBackendThemeMode('SYSTEM'), ThemeMode.system);
    expect(parseBackendThemeMode(null), ThemeMode.system);
  });
  test('Language preferences are normalized', () {
    expect(parseBackendLocale('EN').languageCode, 'en');
    expect(parseBackendLocale('vi').languageCode, 'vi');
    expect(parseBackendLocale(null).languageCode, 'vi');
  });
}
