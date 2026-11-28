import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  static const clientConfigAsset = 'assets/client.env';
  static String get fcmWebVapidKey => dotenv.env['FCM_WEB_VAPID_KEY']?.trim() ?? '';

  static String get apiBaseUrl {
    const override = String.fromEnvironment('API_BASE_URL');
    if (kReleaseMode && override.trim().isEmpty) {
      throw const FormatException('Bản phát hành chưa được cấu hình địa chỉ máy chủ.');
    }
    final configured = override.trim().isNotEmpty
        ? override.trim()
        : (dotenv.env['API_BASE_URL'] ?? '').trim();
    return resolveApiBaseUrl(configured, release: kReleaseMode, web: kIsWeb);
  }

  @visibleForTesting
  static String resolveApiBaseUrl(String configured, {required bool release, required bool web}) {
    final url = configured.trim().isEmpty && !release
        ? (web ? 'http://localhost:8081/api' : 'http://10.0.2.2:8081/api')
        : configured.trim();
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasAuthority || uri.host.isEmpty ||
        !const ['http', 'https'].contains(uri.scheme) || uri.hasQuery ||
        uri.hasFragment || uri.userInfo.isNotEmpty ||
        uri.path.replaceFirst(RegExp(r'/+$'), '') != '/api') {
      throw const FormatException('Địa chỉ API không hợp lệ. Cần đường dẫn kết thúc bằng /api.');
    }
    final host = uri.host.toLowerCase();
    if (release && (uri.scheme != 'https' || !host.contains('.') ||
        !RegExp(r'^[a-z0-9][a-z0-9.-]*[a-z0-9]$').hasMatch(host) ||
        RegExp(r'^\d+(\.\d+){3}$').hasMatch(host) ||
        host == 'localhost' || host.endsWith('.localhost') ||
        host.endsWith('.local') || host.endsWith('.test') ||
        host.endsWith('.invalid') || host.endsWith('.example'))) {
      throw const FormatException('Bản phát hành cần tên miền HTTPS truy cập được từ Internet.');
    }
    final resolved = web && host == '10.0.2.2' ? uri.replace(host: 'localhost') : uri;
    return resolved.toString().replaceFirst(RegExp(r'/+$'), '');
  }
}
