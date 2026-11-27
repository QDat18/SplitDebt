// Trách nhiệm file: Giới hạn và căn bố cục ứng dụng phù hợp cho màn hình mobile.

import 'package:flutter/material.dart';

import '../theme/app_dimensions.dart';

/// Constrain the navigator during build, before route/overlay layout begins.
class MobileAppFrame extends StatelessWidget {
  final Widget child;
  const MobileAppFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final width = media.size.width.clamp(0.0, AppDimensions.maxAppWidth);
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
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
