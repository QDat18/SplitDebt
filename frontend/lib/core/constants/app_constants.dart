// Trách nhiệm file: Cung cấp các hằng số cấu hình ứng dụng được đọc từ biến môi trường.

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  static String get fcmWebVapidKey =>
      dotenv.env['FCM_WEB_VAPID_KEY']?.trim() ?? '';

  static String get apiBaseUrl {
    const override = String.fromEnvironment('API_BASE_URL');
    final url = override.isNotEmpty
        ? override
        : dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:8081/api';
    if (kIsWeb && url.contains('10.0.2.2')) {
      return url.replaceAll('10.0.2.2', 'localhost');
    }
    return url;
  }
}
