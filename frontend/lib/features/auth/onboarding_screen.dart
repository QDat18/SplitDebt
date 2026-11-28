// Trách nhiệm file: Màn hình Onboarding theo bố cục Midnight Navy Hero + nền trắng thoáng + nút CTA Royal Blue.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/state/app_sync.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/widgets/motion_kit.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _page = 0;
  bool _finishing = false;

  static const _icons = [
    CupertinoIcons.doc_text_fill,
    CupertinoIcons.arrow_2_squarepath,
    CupertinoIcons.checkmark_shield_fill,
  ];

  void _next(int displayedPage) {
    if (_finishing || _page != displayedPage) return;
    if (_page >= _icons.length - 1) {
      _finish();
      return;
    }
    setState(() => _page = (_page + 1).clamp(0, _icons.length - 1));
  }

  Future<void> _finish() async {
    if (_finishing || !mounted) return;
    setState(() => _finishing = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = await prefs.setBool('onboarding_complete', true);
      if (!saved) {
        throw StateError('Unable to persist onboarding flag');
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacement(fintechRoute(const LoginScreen()));
    } catch (_) {
      if (!mounted) return;
      setState(() => _finishing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              context,
              'Không thể tiếp tục. Vui lòng thử lại.',
              'Could not continue. Please try again.',
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final displayedPage = _page.clamp(0, _icons.length - 1);
    final isLast = displayedPage == _icons.length - 1;
    final safeTop = MediaQuery.paddingOf(context).top;

    final titles = [
      tr(context, 'Ghi chi tiêu nhóm nhanh gọn', 'Log group expenses fast'),
      tr(context, 'Tối ưu số lần chuyển khoản', 'Simplify group debts'),
      tr(context, 'Xác nhận thanh toán minh bạch', 'Transparent settlement'),
    ];
    final descriptions = [
      tr(
        context,
        'Nhập thủ công hoặc quét hóa đơn, chia đều, theo tỷ lệ, hệ số hay từng món.',
        'Enter manually or scan receipts, split equally, by percentage, weight, or item.',
      ),
      tr(
        context,
        'Tự động gộp các khoản nợ chéo trong nhóm thành ít giao dịch nhất.',
        'Automatically consolidate cross-debts into the fewest transfers possible.',
      ),
      tr(
        context,
        'Công nợ chỉ được trừ khi người nhận xác nhận đã nhận tiền.',
        'Balances update only after the recipient confirms payment.',
      ),
    ];

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxHeight < 620;
          final heroHeight = compact ? 200.0 : 280.0;
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      // Top Midnight Navy curved hero panel matching template
                      Container(
                        width: double.infinity,
                        height: heroHeight + safeTop,
                        padding: EdgeInsets.only(top: safeTop),
                        decoration: const BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.vertical(
                            bottom: Radius.circular(32),
                          ),
                        ),
                        child: Center(
                          child: Container(
                            width: compact ? 84 : 104,
                            height: compact ? 84 : 104,
                            decoration: BoxDecoration(
                              color: AppColors.p500.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(26),
                              border: Border.all(
                                color: AppColors.p400.withValues(alpha: 0.45),
                                width: 1.2,
                              ),
                            ),
                            child: Icon(
                              _icons[displayedPage],
                              size: compact ? 38 : 46,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              AppDimensions.s24,
                              compact ? AppDimensions.s24 : AppDimensions.s32,
                              AppDimensions.s24,
                              AppDimensions.s16,
                            ),
                            child: Column(
                              children: [
                                Text(
                                  titles[displayedPage],
                                  textAlign: TextAlign.center,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineMedium,
                                ),
                                const SizedBox(height: AppDimensions.s12),
                                Text(
                                  descriptions[displayedPage],
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                ),
                                SizedBox(
                                  height: compact
                                      ? AppDimensions.s20
                                      : AppDimensions.s28,
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(
                                    _icons.length,
                                    (i) => AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                      width: displayedPage == i ? 22 : 7,
                                      height: 7,
                                      decoration: BoxDecoration(
                                        color: displayedPage == i
                                            ? scheme.primary
                                            : scheme.outlineVariant,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SafeArea(
                    top: false,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppDimensions.s24,
                            AppDimensions.s8,
                            AppDimensions.s24,
                            AppDimensions.s20,
                          ),
                          child: isLast
                              ? Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    FilledButton(
                                      onPressed: _finishing
                                          ? null
                                          : () => _next(displayedPage),
                                      child: Text(
                                        tr(context, 'Bắt đầu', 'Get started'),
                                      ),
                                    ),
                                  ],
                                )
                              : Row(
                                  children: [
                                    TextButton(
                                      onPressed: _finishing ? null : _finish,
                                      child: Text(
                                        tr(context, 'Bỏ qua', 'Skip'),
                                      ),
                                    ),
                                    const Spacer(),
                                    FilledButton(
                                      onPressed: _finishing
                                          ? null
                                          : () => _next(displayedPage),
                                      style: FilledButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 28,
                                        ),
                                      ),
                                      child: Text(
                                        tr(context, 'Tiếp tục', 'Next'),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
