// Trách nhiệm file: Khởi tạo Flutter, nạp biến môi trường, cấu hình Firebase và dựng cây ứng dụng gốc.

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/app/app_keys.dart';
import 'core/constants/app_constants.dart';
import 'core/app/mobile_app_frame.dart';
import 'core/state/app_sync.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/splash_screen.dart';
import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (!dotenv.isInitialized) {
    await dotenv.load(fileName: AppConstants.clientConfigAsset);
  }
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  try {
    await dotenv.load(fileName: AppConstants.clientConfigAsset);
    // Validate before creating providers or the global Dio client.
    final apiUrl = AppConstants.apiBaseUrl;
    debugPrint('API configured: ${Uri.parse(apiUrl).host}');
  } catch (_) {
    runApp(const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('Bản ứng dụng chưa có địa chỉ máy chủ hợp lệ. '
                  'Vui lòng liên hệ nhóm phát triển để nhận bản APK đã cấu hình.'),
            ),
          ),
        ),
      ),
    ));
    return;
  }

  final firebaseEnabled =
      (dotenv.env['FIREBASE_ENABLED'] ?? 'false').toLowerCase() == 'true';
  if (firebaseEnabled) {
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)
          .timeout(const Duration(seconds: 8));
      if (!kIsWeb) {
        FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      }
    } catch (_) {
      // Database notifications and login do not depend on push notifications.
      debugPrint('Firebase push unavailable; continuing without FCM.');
    }
  }

  runApp(const ProviderScope(child: SplitDebtApp()));
}

class SplitDebtApp extends ConsumerWidget {
  const SplitDebtApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp(
      title: 'SplitDebt',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: scaffoldMessengerKey,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      locale: ref.watch(localeProvider),
      supportedLocales: const [Locale('vi'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: (context, child) => MobileAppFrame(child: child!),
      home: const SplashScreen(),
    );
  }
}
