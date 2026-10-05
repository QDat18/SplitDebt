// Trách nhiệm file: Nạp môi trường, dựng khung hình đầu và khởi tạo Firebase không chặn giao diện.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/app/app_keys.dart';
import 'core/app/firebase_bootstrap.dart';
import 'core/app/mobile_app_frame.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(
    fileName: '.env',
  );

  FirebaseBootstrap.registerBackgroundHandler();

  runApp(
    const ProviderScope(
      child: SplitDebtApp(),
    ),
  );

  // Firebase có thể chậm trên emulator/thiết bị yếu; không chặn khung hình đầu.
  unawaited(
    FirebaseBootstrap.ensureInitialized().catchError((Object error) {
      debugPrint('Firebase initialization failed: $error');
    }),
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
