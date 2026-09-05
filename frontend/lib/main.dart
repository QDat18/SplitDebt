import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'features/auth/login_screen.dart';

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

// =========================================================================
// MÀN HÌNH SPLASH SCREEN CÓ HIỆU ỨNG ANIMATION "CHẠY NỔI"
// =========================================================================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // 1. Cấu hình AnimationController: lặp lại liên tục và tự động đảo ngược chiều
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    // 2. Tạo quỹ đạo di chuyển (từ -15px lên +15px trên trục Y)
    _animation = Tween<double>(begin: -15.0, end: 15.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );

    // 3. Đặt bộ đếm thời gian: Sau 3 giây sẽ tự động điều hướng
    Timer(const Duration(seconds: 3), () {
      _checkAuthAndNavigate();
    });
  }

  void _checkAuthAndNavigate() {
    // Tạm thời điều hướng thẳng vào LoginScreen.
    // Sau này có thể thêm logic: Nếu Supabase.instance.client.auth.currentSession != null thì vào Home.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  void dispose() {
    _controller.dispose(); // Bắt buộc hủy controller để tránh rò rỉ bộ nhớ
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6750A4), // Nền màu tím full màn hình theo UI[cite: 4]
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Bọc logo trong AnimatedBuilder để áp dụng hiệu ứng nổi
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _animation.value), // Di chuyển theo trục Y
                  child: child,
                );
              },
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2), // Khung nền mờ bo góc
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Icon(
                  Icons.content_cut_rounded, // Icon chiếc kéo tượng trưng cho Xén Nợ[cite: 4]
                  size: 72,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              'XÉN NỢ',
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
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.85),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}