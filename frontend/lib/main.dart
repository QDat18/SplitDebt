import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/app/app_keys.dart';
import 'core/app/mobile_app_frame.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/splash_screen.dart';
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
  // Supabase
  // ================================================================
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  // ================================================================
  // KHÔNG initialize PushNotificationService ở main.
  //
  // Chỉ initialize FCM sau khi user login thành công.
  // ================================================================

  runApp(
    const ProviderScope(
      child: SplitDebtApp(),
    ),
  );
}

class SplitDebtApp extends StatelessWidget {
  const SplitDebtApp({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return MaterialApp(
      title: 'SplitDebt',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: scaffoldMessengerKey,
      theme: AppTheme.lightTheme,
      builder: (context, child) => MobileAppFrame(child: child!),
      home: const SplashScreen(),
    );
  }
}
