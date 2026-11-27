// Trách nhiệm file: Cung cấp các hằng số cấu hình ứng dụng được đọc từ biến môi trường.

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  static String get fcmWebVapidKey =>
      dotenv.env['FCM_WEB_VAPID_KEY']?.trim() ?? '';

  static String get apiBaseUrl {
    const override = String.fromEnvironment('API_BASE_URL');
    final configured = override.trim().isNotEmpty
        ? override.trim()
        : (dotenv.env['API_BASE_URL'] ?? '').trim();
    final fallback = kIsWeb ? 'http://localhost:8081/api' : 'http://10.0.2.2:8081/api';
    final url = configured.isEmpty ? fallback : configured;
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasAuthority ||
        !const ['http', 'https'].contains(uri.scheme) || uri.host.isEmpty ||
        uri.hasQuery || uri.hasFragment || uri.userInfo.isNotEmpty) {
      throw FormatException('API_BASE_URL không hợp lệ.');
    }
    final resolved = kIsWeb && uri.host == '10.0.2.2'
        ? uri.replace(host: 'localhost') : uri;
    return resolved.toString().replaceFirst(RegExp(r'/+$'), '');
  }
}
