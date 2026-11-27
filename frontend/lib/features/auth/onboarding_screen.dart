// Trách nhiệm file: Hiển thị các trang giới thiệu và điều hướng đăng nhập.
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
  bool _finishing = false;
  final _pages = const [
    (
      '💸',
      'Ghi chi tiêu nhóm dễ dàng',
      'Thêm khoản chi trong vài giây, chia đều hoặc tùy chỉnh cho từng thành viên',
    ),
    (
      '✂️',
      'Xén nợ thông minh',
      'Tự động gộp các khoản nợ chéo thành ít giao dịch nhất có thể',
    ),
    (
      '📈',
      'Theo dõi minh bạch',
      'Biết rõ ai nợ ai, bao nhiêu và thanh toán chỉ với một chạm',
    ),
  ];

  void _next(int displayedPage) {
    if (_finishing || _page != displayedPage) return;
    if (_page >= _pages.length - 1) {
      _finish();
      return;
    }
    setState(() => _page++);
  }

  Future<void> _finish() async {
    if (_finishing || !mounted) return;
    setState(() => _finishing = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = await prefs.setBool('onboarding_complete', true);
      if (!saved) {
        throw StateError('Không thể lưu trạng thái giới thiệu');
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _finishing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể tiếp tục. Vui lòng thử lại.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final displayedPage = _page;
    final page = _pages[displayedPage];
    final isLast = displayedPage == _pages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 620;
            final illustrationSize = compact ? 140.0 : 210.0;
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: illustrationSize,
                            height: illustrationSize,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: colors.primaryContainer,
                              borderRadius: BorderRadius.circular(32),
                            ),
                            child: Text(
                              page.$1,
                              style: TextStyle(fontSize: compact ? 60 : 86),
                            ),
                          ),
                          SizedBox(height: compact ? 20 : 36),
                          Text(
                            page.$2,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            page.$3,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: compact ? 16 : 28),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              _pages.length,
                              (i) => AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                width: displayedPage == i ? 22 : 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: displayedPage == i
                                      ? colors.primary
                                      : colors.outlineVariant,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          FilledButton(
                            onPressed:
                                _finishing ? null : () => _next(displayedPage),
                            child: Text(isLast ? 'Bắt đầu' : 'Tiếp tục'),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _finishing ? null : _finish,
                            child: Text(isLast ? 'Đăng nhập' : 'Bỏ qua'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
