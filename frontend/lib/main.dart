import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'features/auth/login_screen.dart';

import 'features/auth/splash_screen.dart';

void main() async {
  // Đảm bảo các binding của Flutter được khởi tạo trước khi gọi native code
  WidgetsFlutterBinding.ensureInitialized();

  // Load cấu hình URL và Key từ file .env
  await dotenv.load(fileName: ".env");

  // Khởi tạo kết nối an toàn với Supabase
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  runApp(
    // ProviderScope bắt buộc để quản lý trạng thái bằng Riverpod
    const ProviderScope(
      child: SplitDebtApp(),
    ),
  );
}

class SplitDebtApp extends StatelessWidget {
  const SplitDebtApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SplitDebt',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}