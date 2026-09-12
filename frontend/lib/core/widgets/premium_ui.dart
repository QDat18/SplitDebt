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

/// Flutter interpretation of the WebGL shader shipped in the Stitch source.
/// The shader itself mixes Deep Slate Navy with an emerald signal using
/// sin/cos time noise. Keeping the same formula here preserves the moving,
/// atmospheric depth on Android, iOS and web without falling back to a flat
/// gradient.
class _PremiumBackgroundState extends State<PremiumBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final ValueNotifier<Offset> _pointer;

  @override
  void initState() {
    super.initState();
    _pointer = ValueNotifier<Offset>(const Offset(.5, .5));
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..value = .18;
  }

  void _syncAnimation() {
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (widget.animate && !reduceMotion) {
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      _controller.stop();
      _controller.value = .18;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant PremiumBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animate != widget.animate) _syncAnimation();
  }

  @override
  void dispose() {
    _pointer.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return MouseRegion(
      onHover: reduceMotion
          ? null
          : (event) {
              final box = context.findRenderObject();
              if (box is! RenderBox || !box.hasSize) return;
              final local = box.globalToLocal(event.position);
              final next = Offset(
                (local.dx / box.size.width).clamp(0.0, 1.0),
                (local.dy / box.size.height).clamp(0.0, 1.0),
              );
              if ((next - _pointer.value).distance > .02) {
                _pointer.value = next;
              }
            },
      child: ColoredBox(
        color: AppColors.background,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF080F21), AppColors.background, Color(0xFF071B20)],
                ),
              ),
            ),
            ValueListenableBuilder<Offset>(
              valueListenable: _pointer,
              builder: (context, pointer, _) => RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) => CustomPaint(
                    painter: _LuminousShaderPainter(
                      time: _controller.value * math.pi * 2,
                      pointer: pointer,
                    ),
                  ),
                ),
              ),
            ),
            IgnorePointer(
              child: ValueListenableBuilder<Offset>(
                valueListenable: _pointer,
                builder: (context, pointer, _) => DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(pointer.dx * 2 - 1, pointer.dy * 2 - 1),
                      radius: .72,
                      colors: [
                        AppColors.primary.withValues(alpha: .035),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            widget.child,
          ],
        ),
      ),
    );
  }
}

class _LuminousShaderPainter extends CustomPainter {
  const _LuminousShaderPainter({required this.time, required this.pointer});

  final double time;
  final Offset pointer;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    const navy = Color(0xFF0F172A);
    const emerald = Color(0xFF107451);
    const cols = 22;
    final rows = math.max(18, (cols * size.height / size.width).round());
    final cellW = size.width / cols;
    final cellH = size.height / rows;
    final paint = Paint();

    for (var y = 0; y < rows; y++) {
      final ny = (y + .5) / rows;
      for (var x = 0; x < cols; x++) {
        final nx = (x + .5) / cols;
        final noise = math.sin(nx * 10 + time) * math.cos(ny * 10 + time * .5);
        final mouseDistance = (Offset(nx, ny) - pointer).distance;
        final mouseLift = math.max(0.0, .30 - mouseDistance) * .15;
        final mix = (noise * .10 + .055 + mouseLift).clamp(0.0, .22);
        paint.color = Color.lerp(navy, emerald, mix)!;
        canvas.drawRect(
          Rect.fromLTWH(x * cellW, y * cellH, cellW + 1, cellH + 1),
          paint,
        );
      }
    }

    final haze = Paint()
      ..shader = RadialGradient(
        center: Alignment(pointer.dx * 2 - 1, pointer.dy * 2 - 1),
        radius: .75,
        colors: const [Color(0x164EDEA3), Color(0x000B1326)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, haze);
  }

  @override
  bool shouldRepaint(covariant _LuminousShaderPainter oldDelegate) =>
      oldDelegate.time != time || oldDelegate.pointer != pointer;
}

class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 16,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            color: AppColors.glassFill,
            border: Border.all(color: AppColors.glassBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .40),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.white.withValues(alpha: .18),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Padding(padding: padding, child: child),
            ],
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
  // Kept for backwards source compatibility. The supplied reference logo is
  // always rendered as an image and is never rebuilt from Flutter primitives.
  final bool showCoin;

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'SplitDebt logo',
        image: true,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(math.max(6, size * .06)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: .20),
                blurRadius: size * .32,
                spreadRadius: size * .015,
              ),
              BoxShadow(
                color: AppColors.tertiary.withValues(alpha: .12),
                blurRadius: size * .46,
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.asset(
            'assets/brand/splitdebt-reference-logo.png',
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),
      );
}

class _Coin extends StatelessWidget {
  const _Coin({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) => Transform.rotate(
        angle: -.28,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFDFA8), Color(0xFFFFB95F), Color(0xFFE29100)],
            ),
            border: Border.all(color: const Color(0xFFFFE7C5), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: AppColors.tertiary.withValues(alpha: .25),
                blurRadius: 16,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Icon(
            Icons.attach_money_rounded,
            size: size * .64,
            color: const Color(0xFF653E00),
          ),
        ),
      );
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
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          final t = animation.value;
          return Transform.translate(
            offset: Offset(
              math.sin(t * math.pi * 2) * 4,
              math.cos(t * math.pi * 2) * 10,
            ),
            child: Transform.rotate(
              angle: rotation + math.sin(t * math.pi * 2) * .10,
              child: child,
            ),
          );
        },
        child: _Coin(size: size),
      );
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
  Widget build(BuildContext context) => AnimatedScale(
        scale: _pressed ? .97 : 1,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: Opacity(
          opacity: _enabled || widget.isLoading ? 1 : .45,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: AppColors.primaryGradient,
              border: Border.all(color: Colors.white.withValues(alpha: .22)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: _pressed ? .20 : .32),
                  blurRadius: _pressed ? 12 : 22,
                  offset: Offset(0, _pressed ? 4 : 10),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: _enabled ? widget.onPressed : null,
                onTapDown: (_) => _setPressed(true),
                onTapUp: (_) => _setPressed(false),
                onTapCancel: () => _setPressed(false),
                borderRadius: BorderRadius.circular(12),
                splashColor: Colors.white.withValues(alpha: .10),
                highlightColor: Colors.white.withValues(alpha: .04),
                child: SizedBox(
                  height: 52,
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: widget.isLoading
                          ? const SizedBox(
                              key: ValueKey('loader'),
                              width: 21,
                              height: 21,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Color(0xFF003824),
                              ),
                            )
                          : Row(
                              key: const ValueKey('label'),
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (widget.icon != null) ...[
                                  Icon(widget.icon, color: const Color(0xFF003824), size: 19),
                                  const SizedBox(width: 9),
                                ],
                                Text(
                                  widget.label,
                                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                        color: const Color(0xFF003824),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
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
  Widget build(BuildContext context) => IconButton(
        onPressed: onPressed,
        tooltip: tooltip,
        style: IconButton.styleFrom(
          backgroundColor: AppColors.surfaceHigh.withValues(alpha: .62),
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          minimumSize: const Size.square(44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.glassBorder),
          ),
        ),
        icon: Icon(icon, size: 20),
      );
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
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : Duration(milliseconds: 440 + delay.inMilliseconds),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          final delayed = delay.inMilliseconds == 0
              ? value
              : ((value * (440 + delay.inMilliseconds) - delay.inMilliseconds) / 440)
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
