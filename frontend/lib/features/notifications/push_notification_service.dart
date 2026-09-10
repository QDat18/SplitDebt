import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance =
  PushNotificationService._();

  StreamSubscription<RemoteMessage>? _messageSubscription;
  StreamSubscription<String>? _tokenSubscription;

  int? _subscribedUserId;

  Future<void> initialize() async {
    final FirebaseMessaging messaging =
        FirebaseMessaging.instance;

    final NotificationSettings settings =
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint(
      'FCM permission: ${settings.authorizationStatus}',
    );

    try {
      final String? token =
      await messaging.getToken();

      debugPrint(
        'FCM TOKEN: $token',
      );
    } catch (e) {
      debugPrint(
        'Không lấy được FCM token: $e',
      );
    }

    await _messageSubscription?.cancel();

    _messageSubscription =
        FirebaseMessaging.onMessage.listen(
          _handleForegroundMessage,
        );

    await _tokenSubscription?.cancel();

    _tokenSubscription =
        messaging.onTokenRefresh.listen(
              (token) {
            debugPrint(
              'FCM token refreshed: $token',
            );
          },
        );
  }

  Future<void> subscribeToUser(
      int userId,
      ) async {
    if (_subscribedUserId == userId) {
      return;
    }

    if (_subscribedUserId != null) {
      try {
        await FirebaseMessaging.instance
            .unsubscribeFromTopic(
          'user_$_subscribedUserId',
        );
      } catch (e) {
        debugPrint(
          'Không unsubscribe được topic cũ: $e',
        );
      }
    }

    final String topic =
        'user_$userId';

    await FirebaseMessaging.instance
        .subscribeToTopic(topic);

    _subscribedUserId = userId;

    debugPrint(
      'Đã subscribe FCM topic: $topic',
    );
  }

  Future<void> unsubscribeCurrentUser() async {
    final int? userId =
        _subscribedUserId;

    if (userId == null) {
      return;
    }

    await FirebaseMessaging.instance
        .unsubscribeFromTopic(
      'user_$userId',
    );

    _subscribedUserId = null;
  }

  void _handleForegroundMessage(
      RemoteMessage message,
      ) {
    final String title =
        message.notification?.title ??
            message.data['title'] ??
            'SplitDebt';

    final String body =
        message.notification?.body ??
            message.data['body'] ??
            'Bạn có thông báo mới';

    debugPrint(
      'FCM foreground: $title - $body',
    );

    final messenger =
    scaffoldMessengerResolver?.call();

    messenger?.showSnackBar(
      SnackBar(
        content: Text(
          '$title\n$body',
        ),
        behavior:
        SnackBarBehavior.floating,
      ),
    );
  }

  ScaffoldMessengerState?
  Function()? scaffoldMessengerResolver;

  void bindMessenger(
      GlobalKey<ScaffoldMessengerState> key,
      ) {
    scaffoldMessengerResolver =
        () => key.currentState;
  }

  Future<void> dispose() async {
    await _messageSubscription?.cancel();
    await _tokenSubscription?.cancel();
  }
}