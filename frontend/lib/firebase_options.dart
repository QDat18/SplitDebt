// Trách nhiệm file: Tạo FirebaseOptions theo nền tảng hoàn toàn từ các biến trong file .env.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Firebase client configuration loaded only from the ignored `.env` file.
/// No real Firebase identifier or key is committed to source control.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return _for('WEB');

    return switch (defaultTargetPlatform) {
      TargetPlatform.android => _for('ANDROID'),
      TargetPlatform.iOS => _for('IOS'),
      TargetPlatform.macOS => throw UnsupportedError(
          'Firebase chưa được cấu hình cho macOS.',
        ),
      TargetPlatform.windows => throw UnsupportedError(
          'Firebase chưa được cấu hình cho Windows.',
        ),
      TargetPlatform.linux => throw UnsupportedError(
          'Firebase chưa được cấu hình cho Linux.',
        ),
      TargetPlatform.fuchsia => throw UnsupportedError(
          'Firebase chưa được cấu hình cho Fuchsia.',
        ),
    };
  }

  static FirebaseOptions _for(String platform) {
    return FirebaseOptions(
      apiKey: _required('FIREBASE_${platform}_API_KEY'),
      appId: _required('FIREBASE_${platform}_APP_ID'),
      messagingSenderId: _required('FIREBASE_${platform}_MESSAGING_SENDER_ID'),
      projectId: _required('FIREBASE_${platform}_PROJECT_ID'),
      authDomain: _optional('FIREBASE_${platform}_AUTH_DOMAIN'),
      storageBucket: _optional('FIREBASE_${platform}_STORAGE_BUCKET'),
      measurementId: _optional('FIREBASE_${platform}_MEASUREMENT_ID'),
      iosClientId: _optional('FIREBASE_${platform}_CLIENT_ID'),
      iosBundleId: _optional('FIREBASE_${platform}_BUNDLE_ID'),
    );
  }

  static String _required(String name) {
    final value = dotenv.env[name]?.trim();
    if (value == null || value.isEmpty) {
      throw StateError('Thiếu biến môi trường bắt buộc: $name');
    }
    return value;
  }

  static String? _optional(String name) {
    final value = dotenv.env[name]?.trim();
    return value == null || value.isEmpty ? null : value;
  }
}
