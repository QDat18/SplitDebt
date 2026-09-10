import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/auth_provider.dart';
import '../home/home_screen.dart';
import 'login_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: -15.0, end: 15.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );

    // Wait briefly, then check auth
    Timer(const Duration(seconds: 2), () {
      _checkAuthAndNavigate();
    });
  }

  void _checkAuthAndNavigate() {
    final authState = ref.read(authProvider);
    if (authState == AuthState.authenticated) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Optionally listen to changes to immediately pop if state changes during timer
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next != AuthState.loading) {
        // If it finishes loading early, we could navigate, but we're using a fixed Timer for animation.
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF6750A4),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _animation.value),
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
