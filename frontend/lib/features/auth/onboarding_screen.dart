// Trách nhiệm file: Xây dựng màn hình onboarding screen và điều phối tương tác người dùng với trạng thái nghiệp vụ.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import 'login_screen.dart';

class OnboardingPage {
  final IconData icon;
  final String title;
  final String body;

  const OnboardingPage(this.icon, this.title, this.body);
}

/// Ba trang giới thiệu, theo chủ đề chuyến đi chung của cả nhóm.
const kOnboardingPages = [
  OnboardingPage(
    Icons.luggage_rounded,
    'Ghi chi tiêu chuyến đi',
    'Vé xe, phòng nghỉ, bữa ăn: thêm khoản chi trong vài giây, chia đều hoặc tuỳ chỉnh cho từng người.',
  ),
  OnboardingPage(
    Icons.alt_route_rounded,
    'Xén nợ thông minh',
    'Tự động gộp các khoản nợ chéo thành ít lần chuyển tiền nhất.',
  ),
  OnboardingPage(
    Icons.map_rounded,
    'Về nhà, sòng phẳng',
    'Biết rõ ai nợ ai, bao nhiêu, và thanh toán chỉ với một chạm.',
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _page = 0;

  bool get _isLast => _page == kOnboardingPages.length - 1;

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    if (mounted) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final page = kOnboardingPages[_page];
    return Scaffold(
      backgroundColor: AppColors.n0,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeOut,
                  child: Column(
                    key: ValueKey(_page),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          color: AppColors.p50,
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: Icon(page.icon, size: 72, color: AppColors.p500),
                      ),
                      const SizedBox(height: 40),
                      Text(
                        page.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 28,
                          height: 34 / 28,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 28 * -0.022,
                          color: AppColors.n800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        page.body,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 17,
                          height: 24 / 17,
                          color: AppColors.n600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                kOnboardingPages.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _page == i ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _page == i ? AppColors.p500 : AppColors.n200,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton(
                    onPressed:
                        _isLast ? _finish : () => setState(() => _page++),
                    child: Text(_isLast ? 'Bắt đầu' : 'Tiếp tục'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    style: TextButton.styleFrom(
                        minimumSize: const Size.fromHeight(44)),
                    onPressed: _finish,
                    child: Text(_isLast ? 'Đăng nhập' : 'Bỏ qua',
                        style: const TextStyle(
                            color: AppColors.n600, fontSize: 15)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
