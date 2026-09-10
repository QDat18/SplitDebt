import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../data/api.dart' show money;

class Surface extends StatefulWidget {
  final Widget child;
  final EdgeInsets padding;
  final bool interactive;

  const Surface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.interactive = true,
  });

  @override
  State<Surface> createState() => _SurfaceState();
}

class _SurfaceState extends State<Surface> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final transform = Matrix4.identity()..setEntry(3, 2, 0.001);
    if (hovered && widget.interactive && !reducedMotion) {
      transform
        ..translate(0.0, -3.0)
        ..rotateX(.008)
        ..rotateY(-.006);
    }

    return MouseRegion(
      onEnter: widget.interactive ? (_) => setState(() => hovered = true) : null,
      onExit: widget.interactive ? (_) => setState(() => hovered = false) : null,
      child: AnimatedContainer(
        duration: reducedMotion ? Duration.zero : const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        transform: transform,
        transformAlignment: Alignment.center,
        padding: widget.padding,
        decoration: BoxDecoration(
          color: dark ? const Color(0xE61B2233) : Colors.white.withOpacity(.94),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: hovered
                ? AppColors.primary.withOpacity(dark ? .34 : .20)
                : Theme.of(context).dividerColor,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(dark ? .20 : .055),
              blurRadius: hovered ? 34 : 24,
              offset: Offset(0, hovered ? 17 : 10),
            ),
            if (hovered)
              BoxShadow(
                color: AppColors.primary.withOpacity(dark ? .14 : .09),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
          ],
        ),
        child: widget.child,
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
            border: Border.all(color: const Color(0xFFDAD2FF), width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x407055E8),
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
                    color: Colors.white.withOpacity(.17),
                  ),
                ),
              ),
              Icon(icon, color: Colors.white, size: size * .46),
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
                color: Color(0x357055E8),
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
                            color: Color(0xFFE3DBFF),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      const Icon(Icons.auto_awesome_rounded, color: Color(0xFFD7CCFF)),
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
                    style: const TextStyle(color: Color(0xFFE9E2FF), height: 1.5),
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
              Colors.white.withOpacity(opacity * 1.8),
              Colors.white.withOpacity(opacity),
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
      FeedbackKind.success => (dark ? const Color(0xFF59D8B7) : AppColors.success, Icons.check_circle_rounded),
      FeedbackKind.error => (Theme.of(context).colorScheme.error, Icons.error_rounded),
      FeedbackKind.warning => (AppColors.warning, Icons.warning_amber_rounded),
      FeedbackKind.info => (dark ? const Color(0xFF83B7FF) : AppColors.info, Icons.info_rounded),
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
          color: dark ? const Color(0xFF20283A) : Colors.white,
          border: Border.all(color: color.withOpacity(.28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(dark ? .35 : .12),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
            BoxShadow(color: color.withOpacity(.10), blurRadius: 28),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(.12),
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

  const Avatar(this.name, {super.key, this.radius = 20});

  @override
  Widget build(BuildContext context) => Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primaryLight, AppColors.accentBlue.withOpacity(.16)],
          ),
          border: Border.all(color: Colors.white.withOpacity(.75), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(.12),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          name.isEmpty ? '?' : name.characters.first.toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary),
        ),
      );
}

/// Native, transparent brand asset; no network image or runtime font dependency.
class BrandMark extends StatelessWidget {
  final double size;
  final bool wordmark;

  const BrandMark({super.key, this.size = 120, this.wordmark = false});

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'SplitDebt',
        image: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: Image.asset(
                'assets/brand/splitdebt-mark.png',
                width: size,
                height: size,
                filterQuality: FilterQuality.high,
              ),
            ),
            if (wordmark)
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: 'Split', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                    const TextSpan(text: 'Debt', style: TextStyle(color: AppColors.primary)),
                  ],
                ),
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -.8),
              ),
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
              borderRadius: BorderRadius.circular(18),
              gradient: enabled ? AppColors.primaryGradient : null,
              boxShadow: enabled
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(hovered ? .34 : .22),
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
              color: AppColors.primary.withOpacity(.16),
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
          colors: [Color(0xFFADCFF3), Color(0xFFE5EAF4)],
        ).createShader(rect),
    );
    canvas.drawCircle(
      Offset(size.width * .76, size.height * .23),
      size.width * .10,
      Paint()..color = const Color(0xFFFFE0A0),
    );
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height * .75)
        ..lineTo(size.width * .38, size.height * .30)
        ..lineTo(size.width, size.height * .90)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close(),
      Paint()..color = const Color(0xFF668A9C),
    );
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height * .92)
        ..lineTo(size.width * .72, size.height * .48)
        ..lineTo(size.width, size.height * .76)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close(),
      Paint()..color = const Color(0xFF315D66),
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
              BoxShadow(color: Color(0x347055E8), blurRadius: 28, offset: Offset(0, 12)),
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
                          style: TextStyle(color: Color(0xFFF2EDFF), height: 1.45),
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
        ? (dark ? const Color(0xFF73D6BB) : AppColors.success)
        : (dark ? const Color(0xFFBBA9FF) : const Color(0xFF68648B));
    return Surface(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(.12),
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
                  BoxShadow(color: Color(0x347055E8), blurRadius: 28, offset: Offset(0, 12)),
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
                              style: const TextStyle(color: Color(0xFFF0EAFF), fontWeight: FontWeight.w700),
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
    const labels = ['Chi tiêu', 'Công nợ', 'Thành viên'];
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
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).dividerColor),
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
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TextButton(
                  onPressed: () => onChanged(i),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 4),
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
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(.18)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w800),
      ),
    );
  }
}
