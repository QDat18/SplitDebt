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
import 'core/app/mobile_app_frame.dart';
import 'core/state/app_sync.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/splash_screen.dart';
import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  debugPrint('FCM background message: ${message.messageId}');
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

  await dotenv.load(fileName: '.env');

  final firebaseEnabled =
      (dotenv.env['FIREBASE_ENABLED'] ?? 'false').toLowerCase() == 'true';
  if (firebaseEnabled) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    debugPrint(
      'Firebase initialized: '
      '${DefaultFirebaseOptions.currentPlatform.projectId}',
    );

    if (!kIsWeb) {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    }
  } else {
    debugPrint('Firebase/FCM is disabled for this environment.');
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
