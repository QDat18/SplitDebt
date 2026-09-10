import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class PremiumBackground extends StatefulWidget {
  const PremiumBackground({
    super.key,
    required this.child,
    this.animate = true,
  });

  final Widget child;
  final bool animate;

  @override
  State<PremiumBackground> createState() => _PremiumBackgroundState();
}

class _PremiumBackgroundState extends State<PremiumBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    );

    if (widget.animate) {
      _controller.repeat(reverse: true);
    } else {
      _controller.value = 0.35;
    }
  }

  @override
  void didUpdateWidget(covariant PremiumBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate == oldWidget.animate) return;
    if (widget.animate) {
      _controller.repeat(reverse: true);
    } else {
      _controller.stop();
      _controller.value = 0.35;
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
    final background =
        isDark ? AppColors.darkBackground : AppColors.lightBackground;

    return ColoredBox(
      color: background,
      child: Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final t = _controller.value;
                return IgnorePointer(
                  child: Stack(
                    children: [
                      Positioned(
                        top: -130 + (t * 42),
                        right: -110 + (t * 22),
                        child: _GlowBlob(
                          size: 310,
                          color: AppColors.primary.withOpacity(
                            isDark ? 0.20 : 0.15,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 250 - (t * 28),
                        left: -160 + (t * 38),
                        child: _GlowBlob(
                          size: 290,
                          color: AppColors.accentBlue.withOpacity(
                            isDark ? 0.13 : 0.10,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -170 + (t * 34),
                        right: -120 - (t * 24),
                        child: _GlowBlob(
                          size: 330,
                          color: AppColors.primaryAlt.withOpacity(
                            isDark ? 0.15 : 0.10,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 42, sigmaY: 42),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}

class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 28,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = BorderRadius.circular(borderRadius);

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            color: isDark
                ? const Color(0xB3162231)
                : const Color(0xD9FFFFFF),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.white.withOpacity(0.92),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.22 : 0.08),
                blurRadius: 34,
                offset: const Offset(0, 16),
              ),
              if (!isDark)
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.05),
                  blurRadius: 38,
                  offset: const Offset(0, 18),
                ),
            ],
          ),
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}

class SplitDebtBrandMark extends StatelessWidget {
  const SplitDebtBrandMark({
    super.key,
    this.size = 68,
    this.showCoin = true,
  });

  final double size;
  final bool showCoin;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size + (showCoin ? 12 : 0),
      height: size + (showCoin ? 10 : 0),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(size * 0.28),
              gradient: AppColors.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.34),
                  blurRadius: 30,
                  offset: const Offset(0, 14),
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.18),
                  blurRadius: 1,
                  offset: const Offset(-1, -1),
                ),
              ],
            ),
            child: Icon(
              Icons.account_balance_wallet_rounded,
              color: Colors.white,
              size: size * 0.48,
            ),
          ),
          if (showCoin)
            Positioned(
              right: 0,
              top: -3,
              child: _Coin(size: size * 0.32),
            ),
        ],
      ),
    );
  }
}

class _Coin extends StatelessWidget {
  const _Coin({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.28,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFE59A),
              Color(0xFFF7A93D),
            ],
          ),
          border: Border.all(
            color: const Color(0xFFFFE9AF),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF6A63A).withOpacity(0.30),
              blurRadius: 14,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Icon(
          Icons.attach_money_rounded,
          size: size * 0.64,
          color: const Color(0xFF9A5B00),
        ),
      ),
    );
  }
}

class FloatingCoin extends StatelessWidget {
  const FloatingCoin({
    super.key,
    required this.animation,
    this.size = 42,
    this.rotation = 0,
  });

  final Animation<double> animation;
  final double size;
  final double rotation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final t = animation.value;
        return Transform.translate(
          offset: Offset(
            math.sin(t * math.pi * 2) * 4,
            math.cos(t * math.pi * 2) * 10,
          ),
          child: Transform.rotate(
            angle: rotation + math.sin(t * math.pi * 2) * 0.10,
            child: child,
          ),
        );
      },
      child: _Coin(size: size),
    );
  }
}

class PremiumPrimaryButton extends StatefulWidget {
  const PremiumPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  @override
  State<PremiumPrimaryButton> createState() => _PremiumPrimaryButtonState();
}

class _PremiumPrimaryButtonState extends State<PremiumPrimaryButton> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null && !widget.isLoading;

  void _setPressed(bool value) {
    if (!_enabled || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.985 : 1,
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOut,
      child: Opacity(
        opacity: _enabled || widget.isLoading ? 1 : 0.48,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: AppColors.primaryGradient,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(_pressed ? 0.18 : 0.30),
                blurRadius: _pressed ? 12 : 22,
                offset: Offset(0, _pressed ? 5 : 10),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              onTap: _enabled ? widget.onPressed : null,
              onTapDown: (_) => _setPressed(true),
              onTapUp: (_) => _setPressed(false),
              onTapCancel: () => _setPressed(false),
              borderRadius: BorderRadius.circular(18),
              splashColor: Colors.white.withOpacity(0.12),
              highlightColor: Colors.white.withOpacity(0.04),
              child: SizedBox(
                height: 56,
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: widget.isLoading
                        ? const SizedBox(
                            key: ValueKey('loader'),
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            key: const ValueKey('label'),
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (widget.icon != null) ...[
                                Icon(
                                  widget.icon,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                              ],
                              Text(
                                widget.label,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SoftIconButton extends StatelessWidget {
  const SoftIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      style: IconButton.styleFrom(
        backgroundColor: isDark
            ? Colors.white.withOpacity(0.06)
            : Colors.white.withOpacity(0.80),
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        minimumSize: const Size.square(46),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      icon: Icon(icon, size: 21),
    );
  }
}

class Entrance extends StatelessWidget {
  const Entrance({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = 18,
  });

  final Widget child;
  final Duration delay;
  final double offset;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 440 + delay.inMilliseconds),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final delayed = delay.inMilliseconds == 0
            ? value
            : ((value * (440 + delay.inMilliseconds) -
                        delay.inMilliseconds) /
                    440)
                .clamp(0.0, 1.0)
                .toDouble();

        return Opacity(
          opacity: delayed,
          child: Transform.translate(
            offset: Offset(0, (1 - delayed) * offset),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
