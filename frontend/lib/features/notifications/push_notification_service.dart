import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'notification_repository.dart';

class PushNotificationService {
  PushNotificationService._();
  static final instance = PushNotificationService._();
  static const _webVapidKey = String.fromEnvironment('FCM_WEB_VAPID_KEY',
      defaultValue:
          'BJYhLXwvrXGySDDzjR9Gx3i0BeYeGBqAkjGdtpLNlUjEpFW1WDZjsnbx-SK6diq7chYuNX3oEFFjSVLISvL00f0');
  final _repository = NotificationRepository();
  StreamSubscription<RemoteMessage>? _messageSubscription;
  StreamSubscription<String>? _tokenSubscription;
  int? _subscribedUserId;
  String? _registeredToken;
  ScaffoldMessengerState? Function()? scaffoldMessengerResolver;

  Future<void> initialize() async {
    if (!await FirebaseMessaging.instance.isSupported()) return;
    _messageSubscription ??=
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    _tokenSubscription ??=
        FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      try {
        await _register(token);
      } catch (error) {
        debugPrint('Không cập nhật được FCM token: $error');
      }
    }, onError: (Object error) => debugPrint('FCM token refresh: $error'));
    await FirebaseMessaging.instance
        .requestPermission(alert: true, badge: true, sound: true);
  }

  Future<String?> getToken() async {
    try {
      if (!await FirebaseMessaging.instance.isSupported()) return null;
      final settings =
          await FirebaseMessaging.instance.getNotificationSettings();
      if (settings.authorizationStatus == AuthorizationStatus.denied)
        return null;
      return await FirebaseMessaging.instance
          .getToken(vapidKey: kIsWeb ? _webVapidKey : null);
    } catch (error) {
      debugPrint('Không lấy được FCM token: $error');
      return null;
    }
  }

  Future<void> _register(String token) async {
    final userId = _subscribedUserId;
    if (userId == null || token.isEmpty) return;
    await _repository.registerFcmToken(
        userId: userId,
        token: token,
        platform: kIsWeb ? 'WEB' : defaultTargetPlatform.name.toUpperCase());
    _registeredToken = token;
  }

  Future<void> subscribeToUser(int userId) async {
    _subscribedUserId = userId;
    // Remove subscriptions left by older clients to avoid duplicate delivery.
    if (!kIsWeb) {
      try {
        await FirebaseMessaging.instance.unsubscribeFromTopic('user_$userId');
      } catch (error) {
        debugPrint('Không gỡ được topic FCM cũ: $error');
      }
    }
    final token = await getToken();
    if (token == null) {
      throw Exception(
          'Hãy cho phép Notifications của trang và dùng hồ sơ trình duyệt thường, sau đó thử lại.');
    }
    await _register(token);
  }

  Future<void> unsubscribeCurrentUser() async {
    _subscribedUserId = null;
    final token = _registeredToken;
    _registeredToken = null;
    try {
      if (token != null) await _repository.removeFcmToken(token: token);
    } finally {
      await FirebaseMessaging.instance.deleteToken();
    }
  }

  void bindMessenger(GlobalKey<ScaffoldMessengerState> key) {
    scaffoldMessengerResolver = () => key.currentState;
  }

  Future<void> dispose() async {
    await _messageSubscription?.cancel();
    await _tokenSubscription?.cancel();
    _messageSubscription = null;
    _tokenSubscription = null;
  }

  void _handleForegroundMessage(
    RemoteMessage message,
  ) {
    final String title = message.notification?.title ??
        message.data['title']?.toString() ??
        'SplitDebt';

    final String body = message.notification?.body ??
        message.data['body']?.toString() ??
        'Bạn có thông báo mới';

    debugPrint(
      'FCM foreground: $title - $body',
    );

    debugPrint(
      'FCM messageId: ${message.messageId}',
    );

    debugPrint(
      'FCM data: ${message.data}',
    );

    final String? type = message.data['type']?.toString();

    final Color bgColor = switch (type) {
      'SETTLEMENT_CONFIRMED' => const Color(0xFF15803D), // xanh lá đậm
      'SETTLEMENT_PAID' => const Color(0xFFD97706), // cam
      'SETTLEMENT_REQUEST' => const Color(0xFF7C3AED), // tím
      _ => const Color(0xFF4338CA), // tím đậm mặc định
    };

    final IconData icon = switch (type) {
      'SETTLEMENT_CONFIRMED' => Icons.check_circle_rounded,
      'SETTLEMENT_PAID' => Icons.move_to_inbox_rounded,
      'SETTLEMENT_REQUEST' => Icons.payment_rounded,
      _ => Icons.notifications_active_rounded,
    };

    final ScaffoldMessengerState? messenger = scaffoldMessengerResolver?.call();

    if (messenger == null) {
      debugPrint('FCM: ScaffoldMessenger chưa sẵn sàng.');
      return;
    }

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      body,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: bgColor,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 100, left: 16, right: 16),
          duration: const Duration(seconds: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
  }
}
