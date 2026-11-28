// Trách nhiệm file: Cung cấp bộ chuyển động tinh tế chuẩn iOS (CupertinoPageRoute, nhấn nhẹ, đếm số mượt, shimmer).

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../theme/app_colors.dart';

/// Xuất hiện nhẹ nhàng theo thứ tự (tinh tế, nhanh kiểu iOS).
class StaggeredEntrance extends StatefulWidget {
  const StaggeredEntrance({
    super.key,
    required this.child,
    this.index = 0,
    this.delay,
    this.duration = const Duration(milliseconds: 280),
    this.offsetY = 10,
  });

  final Widget child;
  final int index;
  final Duration? delay;
  final Duration duration;
  final double offsetY;

  @override
  State<StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<StaggeredEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _translateY;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _opacity = Tween<double>(begin: 0, end: 1).animate(curve);
    _translateY = Tween<double>(begin: widget.offsetY, end: 0).animate(curve);

    final effectiveDelay =
        widget.delay ?? Duration(milliseconds: (widget.index.clamp(0, 6)) * 35);
    if (effectiveDelay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(effectiveDelay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: _opacity.value,
        child: Transform.translate(
          offset: Offset(0, _translateY.value),
          child: child,
        ),
      ),
    );
  }
}

/// Phản hồi chạm tinh tế kiểu iOS (nhún nhẹ + giảm opacity nhẹ + haptic).
class ScaleTap extends StatefulWidget {
  const ScaleTap({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scaleDown = 0.98,
    this.haptic = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scaleDown;
  final bool haptic;

  @override
  State<ScaleTap> createState() => _ScaleTapState();
}

class _ScaleTapState extends State<ScaleTap> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.onTap != null ? (_) => _setPressed(true) : null,
      onTapUp: widget.onTap != null ? (_) => _setPressed(false) : null,
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap == null
          ? null
          : () {
              if (widget.haptic) HapticFeedback.selectionClick();
              widget.onTap!();
            },
      onLongPress: widget.onLongPress,
      child: AnimatedOpacity(
        opacity: _pressed ? 0.82 : 1.0,
        duration: reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 90),
        child: AnimatedScale(
          scale: _pressed ? widget.scaleDown : 1.0,
          duration: reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 110),
          curve: Curves.easeOutCubic,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Hiển thị số tiền VND với hiệu ứng chuyển số mượt mà và tabular figures.
class AnimatedMoneyText extends StatelessWidget {
  const AnimatedMoneyText({
    super.key,
    required this.amount,
    this.style,
    this.showSign = false,
    this.symbol = '₫',
    this.duration = const Duration(milliseconds: 480),
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
  });

  final double amount;
  final TextStyle? style;
  final bool showSign;
  final String symbol;
  final Duration duration;
  final int maxLines;
  final TextOverflow overflow;

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: symbol,
      decimalDigits: 0,
    );

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: amount),
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : duration,
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        final sign = showSign
            ? (value > 0
                  ? '+'
                  : value < 0
                  ? '-'
                  : '')
            : (value < 0 ? '-' : '');
        final text = '$sign${formatter.format(value.abs())}';
        return Text(
          text,
          maxLines: maxLines,
          overflow: overflow,
          style: (style ?? const TextStyle()).copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        );
      },
    );
  }
}

/// Nhãn trạng thái tối giản chuẩn iOS.
class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    required this.color,
    this.backgroundColor,
    this.icon,
    this.compact = false,
  });

  final String label;
  final Color color;
  final Color? backgroundColor;
  final IconData? icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final foreground = color == AppColors.success
        ? AppColors.successFor(context)
        : color == AppColors.warning
        ? AppColors.warningFor(context)
        : color == AppColors.error
        ? AppColors.errorFor(context)
        : color;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: backgroundColor ?? foreground.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: compact ? 12 : 14, color: foreground),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: compact ? 12 : 12.5,
              fontWeight: FontWeight.w600,
              height: 1.1,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// Khối shimmer loading tương thích cả Light & Dark mode.
class ShimmerBox extends StatefulWidget {
  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.radius = 12,
  });

  final double width;
  final double height;
  final double radius;

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? AppColors.navy800 : AppColors.n50;
    final highlight = isDark ? AppColors.navy700 : const Color(0xFFFFFFFF);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final slide = (_controller.value * 2.4) - 1.2;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(slide - 0.6, -0.1),
              end: Alignment(slide + 0.6, 0.1),
              colors: [base, highlight, base],
            ),
          ),
        );
      },
    );
  }
}

/// Chuyển trang chuẩn iOS (CupertinoPageRoute hỗ trợ vuốt cạnh trái quay lại).
Route<T> fintechRoute<T>(Widget page) {
  return CupertinoPageRoute<T>(builder: (_) => page);
}
