import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/dio_client.dart';
import '../../data/repositories/auth_repository.dart';

final ValueNotifier<int> appDataSyncSignal = ValueNotifier<int>(0);
void notifyDataChanged() => appDataSyncSignal.value++;
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);
final preferenceRevisionProvider = StateProvider<int>((ref) => 0);
final localeProvider = StateProvider<Locale>((ref) => const Locale('vi'));
ThemeMode parseBackendThemeMode(String? theme) {
  switch (theme?.trim().toUpperCase()) {
    case 'DARK':
      return ThemeMode.dark;
    case 'LIGHT':
      return ThemeMode.light;
    default:
      return ThemeMode.system;
  }
}

Locale parseBackendLocale(String? language) =>
    Locale(language?.toLowerCase() == 'en' ? 'en' : 'vi');

// Call in the long-lived authenticated layout, not a disposed splash route.
Future<Map<String, dynamic>> fetchUserPreferences() async {
  final id = await AuthRepository().getCurrentUserId();
  final response = await dioClient.get('/v1/settings/user/$id');
  return Map<String, dynamic>.from(response.data['data'] as Map);
}

String tr(BuildContext context, String vi, String en) =>
    Localizations.localeOf(context).languageCode == 'en' ? en : vi;
