import 'package:flutter/material.dart';

/// Constrain the navigator during build, before route/overlay layout begins.
class MobileAppFrame extends StatelessWidget {
  final Widget child;
  const MobileAppFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final width = media.size.width.clamp(0.0, 430.0);
    return ColoredBox(
      color: const Color(0xFFECECF3),
      child: Center(
        child: SizedBox(
          width: width,
          child: ClipRect(
            child: MediaQuery(
              data: media.copyWith(size: Size(width, media.size.height)),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
