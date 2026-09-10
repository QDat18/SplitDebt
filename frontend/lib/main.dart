import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/login_screen.dart';
import 'firebase_options.dart';

/// Handler xử lý Firebase Cloud Messaging khi ứng dụng chạy nền.
///
/// Phải là hàm top-level, không đặt bên trong class.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  debugPrint('FCM background message: ${message.messageId}');
}

Future<void> main() async {
  // Đảm bảo Flutter binding được khởi tạo trước khi gọi native code.
  WidgetsFlutterBinding.ensureInitialized();

  // =========================================================
  // 1. LOAD FILE .ENV
  // =========================================================
  await dotenv.load(fileName: '.env');

  // =========================================================
  // 2. KHỞI TẠO FIREBASE
  // =========================================================
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Đăng ký handler xử lý notification khi app chạy background.
  FirebaseMessaging.onBackgroundMessage(
    firebaseMessagingBackgroundHandler,
  );

  // =========================================================
  // 3. KHỞI TẠO SUPABASE
  // =========================================================
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  // =========================================================
  // 4. CHẠY APP
  // =========================================================
  runApp(
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

// =========================================================================
// SPLASH SCREEN
// =========================================================================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // =========================================================
    // ANIMATION LOGO
    // =========================================================
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: -15.0,
      end: 15.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutSine,
      ),
    );

    // Hiện tại giữ Timer tắt để có thể test backend bằng nút bên dưới.
    //
    // Timer(const Duration(seconds: 3), () {
    //   if (mounted) {
    //     _checkAuthAndNavigate();
    //   }
    // });
  }

  void _checkAuthAndNavigate() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // =========================================================================
  // TEST KẾT NỐI SPRING BOOT
  // =========================================================================
  Future<void> _testBackendConnection() async {
    try {
      /*
       * QUAN TRỌNG:
       *
       * Nếu chạy Android Emulator:
       *   http://10.0.2.2:8080/api/health
       *
       * Nếu chạy Flutter Web trên Chrome:
       *   http://localhost:8080/api/health
       *
       * Hiện tại bạn đang chuẩn bị chạy Android Emulator,
       * nên để 10.0.2.2.
       */
      final url = Uri.parse(
        'http://10.0.2.2:8080/api/health',
      );

      final response = await http.get(url);

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${response.body}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '⚠️ Lỗi Server: ${response.statusCode}',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '❌ Mất kết nối Backend: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6750A4),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 24,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // =========================================================
                // LOGO ANIMATION
                // =========================================================
                AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(
                        0,
                        _animation.value,
                      ),
                      child: child,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: const Icon(
                      Icons.content_cut_rounded,
                      size: 72,
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // =========================================================
                // APP NAME
                // =========================================================
                const Text(
                  'XÉN NỢ',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 2.5,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  'Chia tiền nhóm, hết lăn tăn',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.85),
                    letterSpacing: 0.5,
                  ),
                ),

                const SizedBox(height: 40),

                // =========================================================
                // TEST BACKEND
                // =========================================================
                ElevatedButton(
                  onPressed: _testBackendConnection,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF6750A4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                  ),
                  child: const Text(
                    'Test Kết Nối Backend',
                  ),
                ),

                const SizedBox(height: 16),

                // =========================================================
                // VÀO LOGIN
                // =========================================================
                TextButton(
                  onPressed: _checkAuthAndNavigate,
                  child: const Text(
                    'Vào màn hình Login ->',
                    style: TextStyle(
                      color: Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}