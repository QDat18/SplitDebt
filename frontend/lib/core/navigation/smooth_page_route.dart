import 'package:flutter/material.dart';

class SmoothPageRoute<T> extends PageRouteBuilder<T> {
  SmoothPageRoute({
    required WidgetBuilder builder,
    super.settings,
    super.fullscreenDialog = false,
  }) : super(
          transitionDuration: const Duration(milliseconds: 360),
          reverseTransitionDuration: const Duration(milliseconds: 280),
          pageBuilder: (context, animation, secondaryAnimation) => builder(context),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            if (MediaQuery.disableAnimationsOf(context)) return child;
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            final fade = Tween<double>(begin: 0, end: 1).animate(curved);
            final slide = Tween<Offset>(
              begin: const Offset(0.045, 0.015),
              end: Offset.zero,
            ).animate(curved);
            final scale = Tween<double>(begin: .985, end: 1).animate(curved);
            return FadeTransition(
              opacity: fade,
              child: SlideTransition(
                position: slide,
                child: ScaleTransition(scale: scale, child: child),
              ),
            );
          },
        );
}
