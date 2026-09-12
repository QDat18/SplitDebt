import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../data/api.dart' show money;

class Surface extends StatefulWidget {
  final Widget child;
  final EdgeInsets padding;
  final bool interactive;
  final VoidCallback? onTap;

  const Surface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.interactive = true,
    this.onTap,
  });

  @override
  State<Surface> createState() => _SurfaceState();
}

class _SurfaceState extends State<Surface> {
  bool hovered = false;
  bool pressed = false;

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final radius = BorderRadius.circular(16);
    final transform = Matrix4.identity()..setEntry(3, 2, .001);

    if (pressed && widget.interactive && !reducedMotion) {
      transform
        ..translate(0.0, 1.5)
        ..scale(.978, .978);
    } else if (hovered && widget.interactive && !reducedMotion) {
      transform
        ..translate(0.0, -2.0)
        ..rotateX(.006)
        ..rotateY(-.005);
    }

    return MouseRegion(
      onEnter: widget.interactive ? (_) => setState(() => hovered = true) : null,
      onExit: widget.interactive
          ? (_) => setState(() {
                hovered = false;
                pressed = false;
              })
          : null,
      child: Listener(
        onPointerDown: widget.interactive ? (_) => setState(() => pressed = true) : null,
        onPointerUp: widget.interactive ? (_) => setState(() => pressed = false) : null,
        onPointerCancel: widget.interactive ? (_) => setState(() => pressed = false) : null,
        child: AnimatedContainer(
          duration: reducedMotion ? Duration.zero : const Duration(milliseconds: 180),
          // BoxDecoration interpolates BoxShadow values. An overshooting curve
          // can temporarily make blurRadius negative, so use a bounded curve.
          curve: Curves.easeOutCubic,
          transform: transform,
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .38),
                blurRadius: hovered ? 36 : 28,
                offset: Offset(0, hovered ? 16 : 12),
              ),
              // Keep the list length constant during animation.
              BoxShadow(
                color: AppColors.primary.withValues(alpha: hovered ? .10 : 0),
                blurRadius: 28,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.glassFill,
                  borderRadius: radius,
                  border: Border.all(
                    color: hovered
                        ? AppColors.primary.withValues(alpha: .24)
                        : AppColors.glassBorder,
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: .035),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Material(
                  type: MaterialType.transparency,
                  borderRadius: radius,
                  clipBehavior: Clip.antiAlias,
                  child: widget.onTap == null
                      ? Padding(padding: widget.padding, child: widget.child)
                      : InkWell(
                          onTap: widget.onTap,
                          borderRadius: radius,
                          child: Padding(
                            padding: widget.padding,
                            child: widget.child,
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

class Orb extends StatelessWidget {
  final IconData icon;
  final double size;

  const Orb({
    super.key,
    this.icon = Icons.content_cut_rounded,
    this.size = 72,
  });

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 700),
        curve: Curves.easeOutBack,
        builder: (context, value, child) => Transform.translate(
          offset: Offset(0, 12 * (1 - value)),
          child: Transform.rotate(angle: -.08 * value, child: child),
        ),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * .30),
            gradient: AppColors.primaryGradient,
            border: Border.all(color: Colors.white.withValues(alpha: .20), width: 1.2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x664EDEA3),
                blurRadius: 24,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                top: size * .10,
                left: size * .14,
                child: Container(
                  width: size * .42,
                  height: size * .16,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(99),
                    color: Colors.white.withValues(alpha: .17),
                  ),
                ),
              ),
              Icon(icon, color: const Color(0xFF003824), size: size * .46),
            ],
          ),
        ),
      );
}

class HeroCard extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;
  final Widget? footer;

  const HeroCard({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    this.footer,
  });

  @override
  Widget build(BuildContext context) => _TiltShell(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: AppColors.primaryGradient,
            boxShadow: const [
              BoxShadow(
                color: Color(0x334EDEA3),
                blurRadius: 30,
                offset: Offset(0, 14),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -24,
                top: -30,
                child: _GlossSphere(size: 128, opacity: .12),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          eyebrow.toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFFBBCABF),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      const Icon(Icons.auto_awesome_rounded, color: Color(0xFFFFB95F)),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Color(0xFFBBCABF), height: 1.5),
                  ),
                  if (footer != null) ...[const SizedBox(height: 20), footer!],
                ],
              ),
            ],
          ),
        ),
      );
}

class _TiltShell extends StatefulWidget {
  const _TiltShell({required this.child});
  final Widget child;
  @override
  State<_TiltShell> createState() => _TiltShellState();
}

class _TiltShellState extends State<_TiltShell> {
  Offset pointer = Offset.zero;
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    final disabled = MediaQuery.disableAnimationsOf(context);
    return MouseRegion(
      onEnter: disabled ? null : (_) => setState(() => hovered = true),
      onExit: disabled
          ? null
          : (_) => setState(() {
                hovered = false;
                pointer = Offset.zero;
              }),
      onHover: disabled
          ? null
          : (event) {
              final box = context.findRenderObject();
              if (box is! RenderBox || !box.hasSize) return;
              final p = box.globalToLocal(event.position);
              setState(() {
                pointer = Offset(
                  (p.dx / math.max(box.size.width, 1)) - .5,
                  (p.dy / math.max(box.size.height, 1)) - .5,
                );
              });
            },
      child: AnimatedContainer(
        duration: disabled ? Duration.zero : const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        transformAlignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, .001)
          ..rotateX(hovered ? -pointer.dy * .055 : 0)
          ..rotateY(hovered ? pointer.dx * .055 : 0)
          ..translate(0.0, hovered ? -2.0 : 0.0),
        child: widget.child,
      ),
    );
  }
}

class _GlossSphere extends StatelessWidget {
  const _GlossSphere({required this.size, required this.opacity});
  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: const Alignment(-.35, -.4),
            colors: [
              Colors.white.withValues(alpha: opacity * 1.8),
              Colors.white.withValues(alpha: opacity),
              Colors.transparent,
            ],
          ),
        ),
      );
}

class EmptyState extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.title,
    required this.description,
    this.icon = Icons.layers_outlined,
    this.action,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        child: Column(
          children: [
            Orb(icon: icon),
            const SizedBox(height: 24),
            Text(title, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(description, textAlign: TextAlign.center),
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      );
}

class BusyButton extends StatelessWidget {
  final bool busy;
  final String label;
  final VoidCallback onPressed;

  const BusyButton({
    super.key,
    required this.busy,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) => BrandButton(
        label: label,
        onPressed: onPressed,
        busy: busy,
      );
}

enum FeedbackKind { success, error, warning, info }

void showFeedback(
  BuildContext context, {
  required String title,
  required String message,
  FeedbackKind kind = FeedbackKind.info,
  Duration duration = const Duration(seconds: 4),
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        duration: duration,
        content: _FeedbackBanner(title: title, message: message, kind: kind),
      ),
    );
}

void showError(BuildContext context, Object error) => showFeedback(
      context,
      title: 'Có lỗi xảy ra',
      message: _friendlyError(error),
      kind: FeedbackKind.error,
      duration: const Duration(seconds: 6),
    );

void showSuccess(BuildContext context, String message, {String title = 'Thành công'}) => showFeedback(
      context,
      title: title,
      message: message,
      kind: FeedbackKind.success,
    );

void showWarning(BuildContext context, String message, {String title = 'Cần kiểm tra'}) => showFeedback(
      context,
      title: title,
      message: message,
      kind: FeedbackKind.warning,
      duration: const Duration(seconds: 5),
    );

void showInfo(BuildContext context, String message, {String title = 'Thông tin'}) => showFeedback(
      context,
      title: title,
      message: message,
      kind: FeedbackKind.info,
    );

String _friendlyError(Object error) {
  final raw = error.toString().trim();
  if (raw.isEmpty) return 'Không thể hoàn tất thao tác. Vui lòng thử lại.';
  final lower = raw.toLowerCase();
  if (lower.contains('timed out') || lower.contains('timeout')) {
    return 'Kết nối quá thời gian. Kiểm tra Backend hoặc Internet rồi thử lại.';
  }
  if (lower.contains('cannot reach') || lower.contains('connection')) {
    return 'Không thể kết nối máy chủ SplitDebt. Kiểm tra Backend và địa chỉ API.';
  }
  if (lower.contains('sign in again') || lower.contains('401')) {
    return 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
  }
  if (lower.contains('request failed')) {
    return 'Máy chủ chưa xử lý được yêu cầu. Vui lòng thử lại sau.';
  }
  return raw;
}

class _FeedbackBanner extends StatelessWidget {
  const _FeedbackBanner({
    required this.title,
    required this.message,
    required this.kind,
  });

  final String title;
  final String message;
  final FeedbackKind kind;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final (color, icon) = switch (kind) {
      FeedbackKind.success => (AppColors.success, Icons.check_circle_rounded),
      FeedbackKind.error => (Theme.of(context).colorScheme.error, Icons.error_rounded),
      FeedbackKind.warning => (AppColors.warning, Icons.warning_amber_rounded),
      FeedbackKind.info => (AppColors.info, Icons.info_rounded),
    };

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 320),
      curve: Curves.easeOutBack,
      builder: (context, value, child) => Transform.translate(
        offset: Offset(0, 14 * (1 - value)),
        child: Opacity(opacity: value.clamp(0.0, 1.0).toDouble(), child: child),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 620),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: AppColors.surfaceHigh,
          border: Border.all(color: color.withValues(alpha: .28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: dark ? .35 : .12),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
            BoxShadow(color: color.withValues(alpha: .10), blurRadius: 28),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 3),
                  Text(message, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showSuccessDialog(
  BuildContext context, {
  required String title,
  required String message,
  String actionLabel = 'Xong',
}) async {
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Orb(icon: Icons.check_rounded, size: 76),
          const SizedBox(height: 20),
          Text(title, style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(message, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: Text(actionLabel),
        ),
      ],
    ),
  );
}

class SectionTitle extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const SectionTitle(this.title, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 28, bottom: 14),
        child: Row(
          children: [
            Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
            if (trailing != null) trailing!,
          ],
        ),
      );
}

class Avatar extends StatelessWidget {
  final String name;
  final double radius;
  final String? imageUrl;

  const Avatar(this.name, {super.key, this.radius = 20, this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim() ?? '';
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surfaceHigh, AppColors.surfaceHighest],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: .20), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: .14),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: url.isNotEmpty
          ? Image.network(
              url,
              width: radius * 2,
              height: radius * 2,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _AvatarInitial(name: name),
            )
          : _AvatarInitial(name: name),
    );
  }
}

class _AvatarInitial extends StatelessWidget {
  const _AvatarInitial({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) => Center(
        child: Text(
          name.trim().isEmpty ? '?' : name.trim().characters.first.toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary),
        ),
      );
}

/// Luminous Depth brand tile used by the supplied Stitch reference.
///
/// The mark is rendered from the exact image supplied in the Stitch package.
/// No Flutter primitive is used to redraw or reinterpret the logo.
class BrandMark extends StatelessWidget {
  final double size;
  final bool wordmark;

  const BrandMark({super.key, this.size = 120, this.wordmark = false});

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'SplitDebt logo',
        image: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(math.max(5, size * .06)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: .20),
                    blurRadius: size * .32,
                  ),
                  BoxShadow(
                    color: AppColors.tertiary.withValues(alpha: .11),
                    blurRadius: size * .44,
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
            if (wordmark) ...[
              const SizedBox(height: 10),
              Text(
                'SplitDebt',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.8,
                ),
              ),
            ],
          ],
        ),
      );
}

class BrandButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final IconData? icon;

  const BrandButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.icon,
  });

  @override
  State<BrandButton> createState() => _BrandButtonState();
}

class _BrandButtonState extends State<BrandButton> {
  bool pressed = false;
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.busy;
    final disabledMotion = MediaQuery.disableAnimationsOf(context);
    return MouseRegion(
      onEnter: enabled ? (_) => setState(() => hovered = true) : null,
      onExit: enabled ? (_) => setState(() => hovered = false) : null,
      child: Listener(
        onPointerDown: enabled ? (_) => setState(() => pressed = true) : null,
        onPointerUp: (_) => setState(() => pressed = false),
        onPointerCancel: (_) => setState(() => pressed = false),
        child: AnimatedScale(
          scale: pressed ? .975 : hovered && !disabledMotion ? 1.012 : 1,
          duration: disabledMotion ? Duration.zero : const Duration(milliseconds: 120),
          child: AnimatedContainer(
            duration: disabledMotion ? Duration.zero : const Duration(milliseconds: 180),
            transform: Matrix4.translationValues(0, hovered && enabled ? -1.5 : 0, 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: enabled ? AppColors.primaryGradient : null,
              boxShadow: enabled
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: hovered ? .34 : .22),
                        blurRadius: hovered ? 24 : 15,
                        offset: Offset(0, hovered ? 10 : 6),
                      ),
                    ]
                  : [],
            ),
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
              ),
              onPressed: enabled ? widget.onPressed : null,
              child: widget.busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(widget.icon, size: 20),
                          const SizedBox(width: 10),
                        ],
                        Flexible(child: Text(widget.label, textAlign: TextAlign.center)),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class GroupArtwork extends StatelessWidget {
  final String name;
  final double size;

  const GroupArtwork(this.name, {super.key, this.size = 48});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * .28),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: .16),
              blurRadius: 16,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(size * .27),
          child: CustomPaint(size: Size.square(size), painter: _LandscapePainter()),
        ),
      );
}

class _LandscapePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.surfaceHigh, AppColors.surfaceHighest],
        ).createShader(rect),
    );
    canvas.drawCircle(
      Offset(size.width * .76, size.height * .23),
      size.width * .10,
      Paint()..color = AppColors.tertiary.withValues(alpha: .75),
    );
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height * .75)
        ..lineTo(size.width * .38, size.height * .30)
        ..lineTo(size.width, size.height * .90)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close(),
      Paint()..color = AppColors.primaryDark.withValues(alpha: .85),
    );
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height * .92)
        ..lineTo(size.width * .72, size.height * .48)
        ..lineTo(size.width, size.height * .76)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close(),
      Paint()..color = AppColors.primary.withValues(alpha: .70),
    );
  }

  @override
  bool shouldRepaint(covariant _LandscapePainter oldDelegate) => false;
}

class WelcomeCard extends StatelessWidget {
  final VoidCallback onCreate;
  final VoidCallback? onGuide;

  const WelcomeCard({super.key, required this.onCreate, this.onGuide});

  @override
  Widget build(BuildContext context) => _TiltShell(
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: AppColors.primaryGradient,
            boxShadow: const [
              BoxShadow(color: Color(0x334EDEA3), blurRadius: 28, offset: Offset(0, 12)),
            ],
          ),
          child: Stack(
            children: [
              const Positioned(right: -24, top: -28, child: _GlossSphere(size: 130, opacity: .12)),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Không gian chung',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'Chia chi phí rõ ràng, giữ mọi chuyện nhẹ nhàng.',
                          style: TextStyle(color: Color(0xFFBBCABF), height: 1.45),
                        ),
                        const SizedBox(height: 17),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            FilledButton.tonalIcon(
                              onPressed: onCreate,
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppColors.primary,
                              ),
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Tạo nhóm'),
                            ),
                            if (onGuide != null)
                              TextButton.icon(
                                onPressed: onGuide,
                                style: TextButton.styleFrom(foregroundColor: Colors.white),
                                icon: const Icon(Icons.school_rounded),
                                label: const Text('Hướng dẫn'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.people_alt_rounded, size: 58, color: Color(0x55FFFFFF)),
                ],
              ),
            ],
          ),
        ),
      );
}

class BalancePair extends StatelessWidget {
  final String currency;
  final int receivable;
  final int payable;

  const BalancePair({
    super.key,
    required this.currency,
    required this.receivable,
    required this.payable,
  });

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final stack = constraints.maxWidth < 280 || MediaQuery.textScalerOf(context).scale(14) > 20;
          final cards = [
            _tile(context, 'Bạn được nhận', receivable, true),
            _tile(context, 'Bạn đang nợ', payable, false),
          ];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(currency, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: .8)),
              const SizedBox(height: 8),
              if (stack) ...[
                cards[0],
                const SizedBox(height: 12),
                cards[1],
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: cards[0]),
                    const SizedBox(width: 12),
                    Expanded(child: cards[1]),
                  ],
                ),
            ],
          );
        },
      );

  Widget _tile(BuildContext context, String label, int amount, bool positive) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final color = positive
        ? AppColors.success
        : AppColors.error;
    return Surface(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(positive ? Icons.south_west_rounded : Icons.north_east_rounded, color: color, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    money(amount, currency),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class GroupBalanceCard extends StatelessWidget {
  final int balance;
  final int total;
  final String currency;

  const GroupBalanceCard({
    super.key,
    required this.balance,
    required this.total,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) => Column(
        children: [
          _TiltShell(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                gradient: AppColors.primaryGradient,
                boxShadow: const [
                  BoxShadow(color: Color(0x334EDEA3), blurRadius: 28, offset: Offset(0, 12)),
                ],
              ),
              child: Stack(
                children: [
                  const Positioned(right: -26, top: -30, child: _GlossSphere(size: 126, opacity: .12)),
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(17),
                          boxShadow: const [
                            BoxShadow(color: Color(0x26000000), blurRadius: 14, offset: Offset(0, 7)),
                          ],
                        ),
                        child: Icon(
                          balance == 0
                              ? Icons.check_rounded
                              : balance > 0
                                  ? Icons.south_west_rounded
                                  : Icons.north_east_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              balance == 0
                                  ? 'Đã cân bằng'
                                  : balance > 0
                                      ? 'Bạn được nhận'
                                      : 'Bạn đang nợ',
                              style: const TextStyle(color: Color(0xFFBBCABF), fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 6),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                money(balance.abs(), currency),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -.7,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Expanded(child: Text('Tổng chi tiêu nhóm')),
              Text(money(total, currency), style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ],
      );
}

class GroupTabs extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;

  const GroupTabs({super.key, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const labels = ['Chi tiêu', 'Số dư', 'Thành viên', 'Thống kê'];
    if (MediaQuery.textScalerOf(context).scale(14) > 20) {
      return Wrap(
        spacing: 8,
        children: [
          for (var i = 0; i < labels.length; i++)
            ChoiceChip(
              label: Text(labels[i]),
              selected: selected == i,
              onSelected: (_) => onChanged(i),
            ),
        ],
      );
    }
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow.withValues(alpha: .88),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: AnimatedContainer(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  color: selected == i ? AppColors.primaryLight : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: TextButton(
                  onPressed: () => onChanged(i),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 4),
                    foregroundColor: selected == i
                        ? AppColors.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  child: Text(
                    labels[i],
                    style: TextStyle(fontWeight: selected == i ? FontWeight.w800 : FontWeight.w600),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class TutorialPromoCard extends StatelessWidget {
  const TutorialPromoCard({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Surface(
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: AppColors.softGradient,
                borderRadius: BorderRadius.circular(17),
              ),
              child: const Icon(Icons.school_rounded, color: AppColors.primary),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mới dùng SplitDebt?', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  SizedBox(height: 3),
                  Text('Xem hướng dẫn tạo nhóm, thêm chi tiêu và xén nợ trong vài phút.'),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              tooltip: 'Mở hướng dẫn',
              onPressed: onTap,
              icon: const Icon(Icons.arrow_forward_rounded),
            ),
          ],
        ),
      );
}

class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    required this.kind,
  });

  final String label;
  final FeedbackKind kind;

  @override
  Widget build(BuildContext context) {
    final color = switch (kind) {
      FeedbackKind.success => AppColors.success,
      FeedbackKind.error => AppColors.error,
      FeedbackKind.warning => AppColors.warning,
      FeedbackKind.info => AppColors.info,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: .18)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class LuminousBottomNav extends StatelessWidget {
  const LuminousBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    required this.onAdd,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback onAdd;

  static const _items = <(IconData, IconData, String)>[
    (Icons.home_outlined, Icons.home_rounded, 'Tổng quan'),
    (Icons.groups_outlined, Icons.groups_rounded, 'Nhóm'),
    (Icons.account_balance_wallet_outlined, Icons.account_balance_wallet_rounded, 'Thanh toán'),
    (Icons.leaderboard_outlined, Icons.leaderboard_rounded, 'Thống kê'),
  ];

  @override
  Widget build(BuildContext context) => _LuminousNavShell(
        child: Row(
          children: [
            Expanded(child: _navItem(context, 0)),
            Expanded(child: _navItem(context, 1)),
            const SizedBox(width: 76),
            Expanded(child: _navItem(context, 2)),
            Expanded(child: _navItem(context, 3)),
          ],
        ),
        fab: LuminousFab(onTap: onAdd),
      );

  Widget _navItem(BuildContext context, int index) {
    final selected = selectedIndex == index;
    final item = _items[index];
    return _LuminousNavItem(
      icon: selected ? item.$2 : item.$1,
      label: item.$3,
      selected: selected,
      onTap: () => onSelected(index),
    );
  }
}

/// Seven-action navigation used by the supplied Debt / History / Profile
/// screens: three destinations on each side of the central FAB.
class LuminousExtendedBottomNav extends StatelessWidget {
  const LuminousExtendedBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    required this.onAdd,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback onAdd;

  static const _items = <(IconData, IconData, String)>[
    (Icons.grid_view_outlined, Icons.grid_view_rounded, 'Tổng quan'),
    (Icons.groups_outlined, Icons.groups_rounded, 'Nhóm'),
    (Icons.account_balance_wallet_outlined, Icons.account_balance_wallet_rounded, 'Thanh toán'),
    (Icons.history_outlined, Icons.history_rounded, 'Lịch sử'),
    (Icons.analytics_outlined, Icons.analytics_rounded, 'Thống kê'),
    (Icons.person_outline_rounded, Icons.person_rounded, 'Cá nhân'),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final centerGap = width < 360 ? 52.0 : width < 420 ? 60.0 : 70.0;
    return _LuminousNavShell(
      child: Row(
        children: [
          for (var i = 0; i < 3; i++) Expanded(child: _navItem(context, i)),
          SizedBox(width: centerGap),
          for (var i = 3; i < 6; i++) Expanded(child: _navItem(context, i)),
        ],
      ),
      fab: LuminousFab(onTap: onAdd),
    );
  }

  Widget _navItem(BuildContext context, int index) {
    final selected = selectedIndex == index;
    final item = _items[index];
    return _LuminousNavItem(
      icon: selected ? item.$2 : item.$1,
      label: item.$3,
      selected: selected,
      compact: true,
      onTap: () => onSelected(index),
    );
  }
}

class _LuminousNavShell extends StatelessWidget {
  const _LuminousNavShell({required this.child, required this.fab});
  final Widget child;
  final Widget fab;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final narrow = width < 380;
    final edge = narrow ? 8.0 : 20.0;
    final bottom = narrow ? 8.0 : 16.0;
    final shellHeight = narrow ? 72.0 : 80.0;
    final barHeight = narrow ? 58.0 : 64.0;
    return ColoredBox(
        color: AppColors.background,
        child: SafeArea(
          top: false,
          minimum: EdgeInsets.fromLTRB(edge, 0, edge, bottom),
          child: SizedBox(
            height: shellHeight,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomCenter,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                    child: Container(
                      height: barHeight,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLow.withValues(alpha: .94),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: AppColors.outlineVariant.withValues(alpha: .72),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: .42),
                            blurRadius: 34,
                            offset: const Offset(0, 16),
                          ),
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: .035),
                            blurRadius: 24,
                          ),
                        ],
                      ),
                      child: child,
                    ),
                  ),
                ),
                Positioned(top: 0, child: fab),
              ],
            ),
          ),
        ),
      );
  }
}

class _LuminousNavItem extends StatelessWidget {
  const _LuminousNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.compact = false,
  });
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final tiny = width < 360;
    final iconSize = compact ? (tiny ? 17.0 : 19.0) : 22.0;
    final fontSize = compact ? (tiny ? 7.0 : 8.0) : 10.0;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: SizedBox.expand(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: iconSize, color: selected ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.fade,
              softWrap: false,
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LuminousFab extends StatefulWidget {
  const LuminousFab({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  State<LuminousFab> createState() => _LuminousFabState();
}

class _LuminousFabState extends State<LuminousFab> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  bool pressed = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _pulse.stop();
      _pulse.value = .25;
    } else if (!_pulse.isAnimating) {
      _pulse.repeat();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: 'Thêm mới',
        child: GestureDetector(
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => pressed = true),
          onTapUp: (_) => setState(() => pressed = false),
          onTapCancel: () => setState(() => pressed = false),
          child: AnimatedBuilder(
            animation: _pulse,
            builder: (context, child) {
              final glow = .5 + math.sin(_pulse.value * math.pi * 2) * .5;
              return AnimatedScale(
                scale: pressed ? .92 : 1,
                duration: const Duration(milliseconds: 130),
                curve: Curves.easeOutBack,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.fabGradient,
                    border: Border.all(color: Colors.white.withValues(alpha: .30)),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: .30 + glow * .14),
                        blurRadius: 20 + glow * 10,
                        spreadRadius: 1 + glow,
                      ),
                      BoxShadow(
                        color: AppColors.tertiary.withValues(alpha: .15 + glow * .08),
                        blurRadius: 34 + glow * 12,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add_rounded, size: 31, color: Color(0xFF173127)),
                ),
              );
            },
          ),
        ),
      );
}

class AnimatedMoneyText extends StatelessWidget {
  const AnimatedMoneyText({
    super.key,
    required this.amount,
    required this.currency,
    this.style,
    this.duration = const Duration(milliseconds: 850),
    this.prefix = '',
  });
  final int amount;
  final String currency;
  final TextStyle? style;
  final Duration duration;
  final String prefix;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: amount.toDouble()),
        duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration,
        curve: Curves.easeOutCubic,
        builder: (context, value, _) => Text(
          '$prefix${money(value.round(), currency)}',
          style: style,
        ),
      );
}

class StaggerReveal extends StatelessWidget {
  const StaggerReveal({super.key, required this.child, this.index = 0});
  final Widget child;
  final int index;

  @override
  Widget build(BuildContext context) {
    final disabled = MediaQuery.disableAnimationsOf(context);
    final delay = math.min(index * 65, 390);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: disabled ? Duration.zero : Duration(milliseconds: 420 + delay),
      curve: Interval(disabled ? 0 : delay / (420 + delay), 1, curve: Curves.easeOutCubic),
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(offset: Offset(0, 14 * (1 - value)), child: child),
      ),
      child: child,
    );
  }
}

class LuminousBrandHeader extends StatelessWidget {
  const LuminousBrandHeader({
    super.key,
    required this.section,
    this.trailing,
  });

  final String section;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final narrow = width < 380;
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          height: narrow ? 56 : 60,
          padding: EdgeInsets.symmetric(horizontal: narrow ? 12 : 20),
          decoration: BoxDecoration(
            color: AppColors.background.withValues(alpha: .42),
            border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: .035))),
          ),
          child: Row(
            children: [
              BrandMark(size: narrow ? 28 : 30),
              SizedBox(width: narrow ? 6 : 8),
              Text(
                'SplitDebt',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: narrow ? 18 : 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -.3,
                ),
              ),
              const Spacer(),
              if (!narrow)
                Text(
                  section,
                  style: const TextStyle(
                    fontFamily: 'Geist',
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: .65,
                  ),
                ),
              if (trailing != null) ...[
                SizedBox(width: narrow ? 6 : 12),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
