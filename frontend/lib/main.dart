// Trách nhiệm file: Khởi tạo Flutter, nạp biến môi trường, cấu hình Firebase và dựng cây ứng dụng gốc.

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/app/app_keys.dart';
import 'core/app/mobile_app_frame.dart';
import 'core/localization/app_strings.dart';
import 'core/localization/locale_provider.dart';
import 'core/navigation/route_observer.dart';
import 'core/network/dio_client.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/splash_screen.dart';
import 'features/legal/reconsent_screen.dart';
import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  debugPrint(
    'FCM background message: ${message.messageId}',
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(
    fileName: '.env',
  );

  // ================================================================
  // Firebase Core
  // ================================================================
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  debugPrint(
    'Firebase initialized: '
    '${DefaultFirebaseOptions.currentPlatform.projectId}',
  );

  // Web dùng firebase-messaging-sw.js.
  // Chỉ Android/mobile mới đăng ký background handler Dart.
  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(
      firebaseMessagingBackgroundHandler,
    );
  }

  // ================================================================
  // KHÔNG initialize PushNotificationService ở main.
  //
  // Chỉ initialize FCM sau khi user login thành công.
  // ================================================================

  // Tùy biến ErrorWidget chuẩn Apple HIG thay thế màn hình đỏ mặc định của Flutter
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: const Color(0xFFF2F2F7),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9500).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.wifi_off_rounded,
                    size: 32,
                    color: Color(0xFFFF9500),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Không thể kết nối đến máy chủ',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1C1C1E),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  details.exception.toString().contains('Connection refused')
                      ? 'Lỗi kết nối mạng (Connection Refused). Vui lòng kiểm tra backend Spring Boot (cổng 8081) hoặc cấu hình API_BASE_URL.'
                      : 'Đã xảy ra sự cố hiển thị. Vui lòng thử lại sau.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF8E8E93),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  };

  runApp(
    const ProviderScope(
      child: SplitDebtApp(),
    ),
  );
}

class SplitDebtApp extends ConsumerWidget {
  const SplitDebtApp({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final locale = ref.watch(localeProvider);
    DioClient.onReconsentRequired ??= () {
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const ReconsentScreen()),
        (route) => false,
      );
    };
    return AppLocaleScope(
      locale: locale,
      child: MaterialApp(
        title: 'SplitDebt',
        debugShowCheckedModeBanner: false,
        navigatorKey: navigatorKey,
        scaffoldMessengerKey: scaffoldMessengerKey,
        navigatorObservers: [appRouteObserver],
        theme: AppTheme.lightTheme,
        builder: (context, child) => MobileAppFrame(child: child!),
        home: const SplashScreen(),
      ),
    );
  }
}
