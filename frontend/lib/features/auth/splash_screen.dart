import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'onboarding_screen.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../main_layout_screen.dart';
import 'login_screen.dart';
import 'data/auth_repository.dart';
import '../notifications/push_notification_service.dart';
import '../../core/app/app_keys.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _timer = Timer(
      const Duration(seconds: 2),
      _checkAuthAndNavigate,
    );
  }

  Future<void> _checkAuthAndNavigate() async {
    // Giữ nguyên AuthNotifier của dev1-huy.
    // Gọi lại checkToken để chắc chắn trạng thái auth đã được xác định.
    final isAuthenticated = await ref.read(authProvider.notifier).checkToken();

    if (!mounted) return;

    if (isAuthenticated) {
      unawaited(_restorePush());
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const MainLayoutScreen(),
        ),
      );
    } else {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      final seen = prefs.getBool('onboarding_complete') ?? false;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => seen ? const LoginScreen() : const OnboardingScreen(),
        ),
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
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Center(
                child: Text(
                  '✂️',
                  style: TextStyle(fontSize: 48),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'XÉN NỢ',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Chia tiền nhóm, hết lăn tăn',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
