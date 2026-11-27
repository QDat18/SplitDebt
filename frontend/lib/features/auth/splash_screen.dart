import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app/app_keys.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/widgets/motion_kit.dart';
import '../../core/widgets/premium_shell.dart';
import '../../data/repositories/auth_repository.dart';
import '../../main_layout_screen.dart';
import '../notifications/push_notification_service.dart';
import 'login_screen.dart';
import 'onboarding_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  late final AnimationController _animation;

  @override
  void initState() {
    super.initState();
    _animation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    )..forward();
    _timer = Timer(const Duration(milliseconds: 150), _checkAuthAndNavigate);
  }

  Future<void> _checkAuthAndNavigate() async {
    final isAuthenticated = await ref.read(authProvider.notifier).checkToken();
    if (!mounted) return;

    if (isAuthenticated) {
      unawaited(_restorePushAndTheme());
      Navigator.of(context).pushReplacement(
        fintechRoute(const MainLayoutScreen()),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final seen = prefs.getBool('onboarding_complete') ?? false;
    Navigator.of(context).pushReplacement(
      fintechRoute(seen ? const LoginScreen() : const OnboardingScreen()),
    );
  }

  Future<void> _restorePushAndTheme() async {
    try {
      final userId = await AuthRepository().getCurrentUserId();
      final push = PushNotificationService.instance;
      push.bindMessenger(scaffoldMessengerKey);
      await push.initialize();
      await push.subscribeToUser(userId);
    } catch (error) {
      debugPrint('Không khôi phục được thông báo: $error');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fade = CurvedAnimation(parent: _animation, curve: Curves.easeOut);
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: Center(
        child: FadeTransition(
          opacity: fade,
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SplitDebtMark(size: 76),
              SizedBox(height: 18),
              Text(
                'SplitDebt',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Quản lý chi tiêu nhóm & chia nợ',
                style: TextStyle(
                  color: Color(0xFF8E8E93),
                  fontSize: 13.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
