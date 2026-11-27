// Trách nhiệm file: Quản lý trạng thái ngôn ngữ (vi/en) của ứng dụng và lưu trữ vào SharedPreferences.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _appLanguageKey = 'app_language';

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('vi'));

  Future<void> loadSavedLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_appLanguageKey);
      if (code == 'en' || code == 'vi') {
        if (mounted) {
          state = Locale(code!);
        }
      }
    } catch (_) {
      // Giữ ngôn ngữ mặc định nếu không đọc được SharedPreferences
    }
  }

  Future<void> setLocale(Locale locale) async {
    final code = locale.languageCode == 'en' ? 'en' : 'vi';
    state = Locale(code);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_appLanguageKey, code);
    } catch (_) {
      // Bỏ qua lỗi lưu trữ cục bộ
    }
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  final notifier = LocaleNotifier();
  notifier.loadSavedLocale();
  return notifier;
});

