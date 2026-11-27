// Trách nhiệm file: Xây dựng màn hình splash screen và điều phối tương tác người dùng với trạng thái nghiệp vụ.

import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'onboarding_screen.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../main_layout_screen.dart';
import '../legal/reconsent_screen.dart';
import 'login_screen.dart';
import '../../data/repositories/auth_repository.dart';
import '../notifications/push_notification_service.dart';
import '../../core/app/app_keys.dart';
import 'splash_brand.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

/// Thời gian hiển thị tối thiểu của màn khởi động, để hiệu ứng logo chạy xong
/// và màn hình không chớp qua quá nhanh khi kiểm tra đăng nhập trả về ngay.
const kSplashMinDuration = Duration(milliseconds: 1200);

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAuthAndNavigate());
  }

  Route<void> _fadeRoute(Widget page) {
    return PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) => FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      ),
    );
  }

  Future<void> _checkAuthAndNavigate() async {
    // Giữ nguyên AuthNotifier của dev1-huy.
    // Gọi lại checkToken để chắc chắn trạng thái auth đã được xác định.
    // Chạy song song với thời gian hiển thị tối thiểu thay vì chờ cứng 2 giây.
    final results = await Future.wait<Object>([
      ref.read(authProvider.notifier).checkToken(),
      Future<void>.delayed(kSplashMinDuration).then((_) => true),
    ]);
    final isAuthenticated = results.first as bool;

    if (!mounted) return;

    if (isAuthenticated) {
      unawaited(_restorePush());
      final consent = await AuthRepository().fetchConsentStatus();
      if (!mounted) return;
      if (consent?.reconsentRequired == true) {
        Navigator.of(context).pushAndRemoveUntil(
          _fadeRoute(const ReconsentScreen()),
          (route) => false,
        );
        return;
      }
      Navigator.of(context).pushReplacement(
        _fadeRoute(const MainLayoutScreen()),
      );
    } else {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      final seen = prefs.getBool('onboarding_complete') ?? false;
      Navigator.of(context).pushReplacement(
        _fadeRoute(seen ? const LoginScreen() : const OnboardingScreen()),
      );
    }
  }

  Future<void> _restorePush() async {
    try {
      final push = PushNotificationService.instance;
      push.bindMessenger(scaffoldMessengerKey);
      await push.initialize();
      await push.subscribeToUser(await AuthRepository().getCurrentUserId());
    } catch (error) {
      debugPrint('Không khôi phục được thông báo: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.n0,
      body: SafeArea(
        child: SizedBox.expand(child: SplashBrand()),
      ),
    );
  }
}
