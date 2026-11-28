// Trách nhiệm file: Cung cấp nền trắng thoáng / Midnight Navy, thẻ bề mặt cool-ice, biểu tượng thương hiệu và tiêu đề theo mẫu thiết kế Fintech.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Nền trang sạch sẽ: trắng tinh khiết ở Light Mode, Midnight Navy sâu ở Dark Mode.
class PremiumBackground extends StatelessWidget {
  const PremiumBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ColoredBox(
      color: isDark ? AppColors.navy950 : AppColors.n0,
      child: child,
    );
  }
}

/// Bề mặt thẻ theo mẫu: nền ice-tint nhẹ (#F4F6FC) hoặc trắng nổi (#FFFFFF) trên Light Mode, Midnight Slate (#141236) trên Dark Mode.
class PremiumSurface extends StatelessWidget {
  const PremiumSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 16,
    this.borderColor,
    this.elevated = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? borderColor;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark
        ? AppColors.navy800
        : (elevated ? AppColors.n0 : AppColors.n50);
    final defaultBorder = isDark ? AppColors.navy600 : AppColors.n100;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? defaultBorder, width: 0.8),
        boxShadow: (!isDark && elevated)
            ? const [
                BoxShadow(
                  color: Color(0x0F0F0B36),
                  blurRadius: 18,
                  offset: Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Biểu tượng thương hiệu SplitDebt theo bảng màu Midnight Navy & Royal Blue.
class SplitDebtMark extends StatelessWidget {
  const SplitDebtMark({super.key, this.size = 56});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(size * .26),
        border: Border.all(
          color: AppColors.p500.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            right: size * 0.12,
            top: size * 0.12,
            child: Container(
              width: size * 0.22,
              height: size * 0.22,
              decoration: const BoxDecoration(
                color: AppColors.p500,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Icon(
            CupertinoIcons.creditcard_fill,
            color: Colors.white,
            size: size * .46,
          ),
        ],
      ),
    );
  }
}

/// Tiêu đề trang sắc nét theo phân cấp chữ Midnight Navy.
class PremiumHeader extends StatelessWidget {
  const PremiumHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    this.trailing,
    this.onDark = false,
  });

  final String eyebrow;
  final String title;
  final Widget? trailing;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final titleColor = onDark ? Colors.white : scheme.onSurface;
    final eyebrowColor = onDark
        ? Colors.white.withValues(alpha: 0.72)
        : scheme.onSurfaceVariant;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (eyebrow.trim().isNotEmpty) ...[
                Text(
                  eyebrow,
                  style: TextStyle(
                    color: eyebrowColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
              ],
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.6,
                  color: titleColor,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
