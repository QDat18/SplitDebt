// Trách nhiệm file: Cung cấp InheritedWidget AppLocaleScope và helper bản địa hoá song ngữ Tiếng Việt / Tiếng Anh.

import 'package:flutter/material.dart';

class AppLocaleScope extends InheritedWidget {
  final Locale locale;

  const AppLocaleScope({
    super.key,
    required this.locale,
    required super.child,
  });

  static Locale of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppLocaleScope>();
    return scope?.locale ?? const Locale('vi');
  }

  @override
  bool updateShouldNotify(AppLocaleScope oldWidget) =>
      locale.languageCode != oldWidget.locale.languageCode;
}

class AppStrings {
  static String tr(Locale locale, String vi, String en) {
    return locale.languageCode == 'en' ? en : vi;
  }

  static String languageName(Locale locale) {
    return locale.languageCode == 'en' ? 'English' : 'Tiếng Việt';
  }
}

extension BuildContextL10n on BuildContext {
  bool get isEnglish => AppLocaleScope.of(this).languageCode == 'en';

  String tr(String vi, String en) {
    return isEnglish ? en : vi;
  }
}
