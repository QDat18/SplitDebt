// Trách nhiệm file: Khởi tạo Firebase bất đồng bộ sau khung hình đầu và cung cấp Future dùng chung cho FCM.

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint('FCM background message: ${message.messageId}');
}

class FirebaseBootstrap {
  FirebaseBootstrap._();

  static Future<void>? _initialization;
  static bool _backgroundHandlerRegistered = false;

  /// Đăng ký handler nhanh trước runApp; không thực hiện I/O chặn khung hình đầu.
  static void registerBackgroundHandler() {
    if (kIsWeb || _backgroundHandlerRegistered) return;
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    _backgroundHandlerRegistered = true;
  }

  /// Chỉ tạo một tiến trình khởi tạo Firebase cho toàn ứng dụng.
  static Future<void> ensureInitialized() {
    return _initialization ??= _initialize();
  }

  static Future<void> _initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint(
      'Firebase initialized: '
      '${DefaultFirebaseOptions.currentPlatform.projectId}',
    );
  }
}
