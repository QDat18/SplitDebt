// Trách nhiệm file: Phần hiển thị thương hiệu của màn khởi động (icon, tên app, khẩu hiệu).

import 'package:flutter/cupertino.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_mark.dart';

const kSplashTitle = 'Xén Nợ';
const kSplashTagline = 'Đi cùng nhau, chia tiền nhẹ tênh';

/// Icon, tên app và khẩu hiệu, xuất hiện bằng một hiệu ứng phóng nhẹ và hiện dần.
/// Nếu người dùng tắt hiệu ứng trong cài đặt hệ thống thì hiện ngay, không chuyển động.
class SplashBrand extends StatefulWidget {
  const SplashBrand({super.key});

  @override
  State<SplashBrand> createState() => _SplashBrandState();
}

class _SplashBrandState extends State<SplashBrand>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );

  static const _ease = Cubic(0.32, 0.72, 0, 1);

  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, 0.8, curve: Curves.easeOut),
  );
  late final Animation<double> _scale = Tween<double>(begin: 0.92, end: 1)
      .animate(CurvedAnimation(parent: _controller, curve: _ease));
  late final Animation<double> _textFade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.3, 1, curve: Curves.easeOut),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller.isAnimating || _controller.isCompleted) return;
    if (MediaQuery.of(context).disableAnimations) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Spacer(flex: 5),
        FadeTransition(
          opacity: _fade,
          child: ScaleTransition(scale: _scale, child: const AppMark()),
        ),
        const SizedBox(height: 24),
        FadeTransition(
          opacity: _textFade,
          child: const Column(
            children: [
              Text(
                kSplashTitle,
                style: TextStyle(
                  fontSize: 28,
                  height: 34 / 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 28 * -0.022,
                  color: AppColors.n800,
                ),
              ),
              SizedBox(height: 8),
              Text(
                kSplashTagline,
                style: TextStyle(
                  fontSize: 15,
                  height: 20 / 15,
                  fontWeight: FontWeight.w400,
                  color: AppColors.n600,
                ),
              ),
            ],
          ),
        ),
        const Spacer(flex: 6),
        FadeTransition(
          opacity: _textFade,
          child: const CupertinoActivityIndicator(
            radius: 10,
            color: AppColors.n500,
          ),
        ),
        const SizedBox(height: 48),
      ],
    );
  }
}
