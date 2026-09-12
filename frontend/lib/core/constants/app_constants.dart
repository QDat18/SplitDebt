import 'package:flutter/foundation.dart';

class AppConstants {
  const AppConstants._();

  /// Override at build/run time when needed, for example:
  /// flutter run --dart-define=API_URL=http://192.168.1.10:8080/api
  ///
  /// Without an override:
  /// - Flutter Web / desktop connects to localhost.
  /// - Android Emulator connects to the host through 10.0.2.2.
  static const String _configuredApiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: '',
  );

  /// Google OAuth Web Client ID. Pass the same Web OAuth client ID to the
  /// Backend as GOOGLE_CLIENT_ID. On Android it is used as serverClientId so
  /// Google returns an ID token that the Backend can verify.
  static const String _googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: '',
  );

  static String get googleWebClientId => _googleWebClientId.trim();
  static bool get googleSignInConfigured => googleWebClientId.isNotEmpty;

  static String get apiUrl {
    final configured = _configuredApiUrl.trim();
    final value = configured.isNotEmpty ? configured : _defaultApiUrl;
    return value.replaceAll(RegExp(r'/$'), '');
  }

  static String get _defaultApiUrl {
    if (kIsWeb) return 'http://localhost:8080/api';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080/api';
    }
    return 'http://localhost:8080/api';
  }

  static bool get configured =>
      apiUrl.startsWith('http://') || apiUrl.startsWith('https://');
}
