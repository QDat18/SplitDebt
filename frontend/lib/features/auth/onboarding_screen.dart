import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _page = 0;
  final _pages = const [
    (
      '💸',
      'Ghi chi tiêu nhóm dễ dàng',
      'Thêm khoản chi trong vài giây, chia đều hoặc tùy chỉnh cho từng thành viên'
    ),
    (
      '✂️',
      'Xén nợ thông minh',
      'Tự động gộp các khoản nợ chéo thành ít giao dịch nhất có thể'
    ),
    (
      '📈',
      'Theo dõi minh bạch',
      'Biết rõ ai nợ ai, bao nhiêu và thanh toán chỉ với một chạm'
    ),
  ];
  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    if (mounted)
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
          body: SafeArea(
              child: Column(children: [
        Expanded(
            child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                          width: 210,
                          height: 210,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                              color: const Color(0xFFF0EDFF),
                              borderRadius: BorderRadius.circular(32)),
                          child: Text(_pages[_page].$1,
                              style: const TextStyle(fontSize: 86))),
                      const SizedBox(height: 36),
                      Text(_pages[_page].$2,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 23, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 14),
                      Text(_pages[_page].$3,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Color(0xFF778092), fontSize: 14)),
                      const SizedBox(height: 28),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                              3,
                              (i) => AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  width: _page == i ? 22 : 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                      color: _page == i
                                          ? const Color(0xFF6C5CE7)
                                          : const Color(0xFFE0E0EA),
                                      borderRadius:
                                          BorderRadius.circular(8))))),
                    ]))),
        Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton(
                      onPressed:
                          _page == 2 ? _finish : () => setState(() => _page++),
                      child: Text(_page == 2 ? 'Bắt đầu' : 'Tiếp tục')),
                  const SizedBox(height: 8),
                  TextButton(
                      onPressed: _finish,
                      child: Text(_page == 2 ? 'Đăng nhập' : 'Bỏ qua',
                          style: const TextStyle(color: Color(0xFF778092))))
                ])),
      ])));
}
