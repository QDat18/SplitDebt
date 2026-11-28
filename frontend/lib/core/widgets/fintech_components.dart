// Trách nhiệm file: Cung cấp các component Fintech theo mẫu Midnight Navy & Royal Blue (NavyHeroHeader, BalanceSummaryCard, GroupAvatar, SectionLabel, Empty/Error State).

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../state/app_sync.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import 'motion_kit.dart';
import 'premium_shell.dart';

/// Khung tiêu đề Midnight Navy bo cong đáy theo mẫu thiết kế, hỗ trợ thẻ nổi chồng lên ranh giới dưới.
class NavyHeroHeader extends StatelessWidget {
  const NavyHeroHeader({
    super.key,
    required this.headerContent,
    this.floatingCard,
    this.topPadding = 12,
  });

  final Widget headerContent;
  final Widget? floatingCard;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    final safeTop = MediaQuery.paddingOf(context).top;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                AppDimensions.s20,
                safeTop + topPadding,
                AppDimensions.s20,
                floatingCard != null ? 56 : AppDimensions.s24,
              ),
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(28),
                ),
              ),
              child: headerContent,
            ),
            if (floatingCard != null)
              Padding(
                padding: EdgeInsets.only(
                  top: safeTop + topPadding,
                  left: AppDimensions.s16,
                  right: AppDimensions.s16,
                ),
                child: Column(
                  children: [
                    Opacity(
                      opacity: 0,
                      child: IgnorePointer(child: headerContent),
                    ),
                    const SizedBox(height: AppDimensions.s16),
                    floatingCard!,
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Nút hành động phụ nền Midnight Navy đậm (như nút "Explore more", "Add card", "Top up" trong mẫu).
class NavyActionButton extends StatelessWidget {
  const NavyActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final style = FilledButton.styleFrom(
      backgroundColor: isDark ? AppColors.navy700 : AppColors.navy900,
      foregroundColor: Colors.white,
      side: isDark
          ? const BorderSide(color: AppColors.navy600, width: 1)
          : null,
    );
    if (icon != null) {
      return FilledButton.icon(
        style: style,
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
      );
    }
    return FilledButton(style: style, onPressed: onPressed, child: Text(label));
  }
}

/// Avatar nhóm sạch sẽ dùng icon nghiệp vụ với nền ice-blue nhẹ (không dùng emoji).
class GroupAvatar extends StatelessWidget {
  const GroupAvatar({
    super.key,
    required this.name,
    this.size = 44,
    this.radius = AppDimensions.r12,
  });

  final String name;
  final double size;
  final double radius;

  static IconData iconForName(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('trip') ||
        lower.contains('du lịch') ||
        lower.contains('đà lạt') ||
        lower.contains('hải phòng') ||
        lower.contains('phú quốc') ||
        lower.contains('travel')) {
      return CupertinoIcons.airplane;
    }
    if (lower.contains('project') ||
        lower.contains('team') ||
        lower.contains('lập trình') ||
        lower.contains('work') ||
        lower.contains('công ty')) {
      return CupertinoIcons.briefcase;
    }
    if (lower.contains('trọ') ||
        lower.contains('phòng') ||
        lower.contains('nhà') ||
        lower.contains('home') ||
        lower.contains('house')) {
      return CupertinoIcons.house;
    }
    if (lower.contains('ăn') ||
        lower.contains('uống') ||
        lower.contains('cơm') ||
        lower.contains('nhậu') ||
        lower.contains('food') ||
        lower.contains('cafe') ||
        lower.contains('cà phê')) {
      return Icons.restaurant_outlined;
    }
    return CupertinoIcons.person_2;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(iconForName(name), size: size * 0.48, color: scheme.primary),
    );
  }
}

/// Biểu tượng khoản chi chuẩn Fintech (không dùng emoji).
class ExpenseIconBadge extends StatelessWidget {
  const ExpenseIconBadge({
    super.key,
    this.title = '',
    this.categoryName,
    this.size = 40,
    this.color,
  });

  final String title;
  final String? categoryName;
  final double size;
  final Color? color;

  static IconData iconFor(String title, String? category) {
    final text = '${category ?? ''} $title'.toLowerCase();
    if (text.contains('ăn') ||
        text.contains('cơm') ||
        text.contains('trưa') ||
        text.contains('tối') ||
        text.contains('sáng') ||
        text.contains('lẩu') ||
        text.contains('nướng') ||
        text.contains('food')) {
      return Icons.restaurant_outlined;
    }
    if (text.contains('cafe') ||
        text.contains('cà phê') ||
        text.contains('trà') ||
        text.contains('uống') ||
        text.contains('drink')) {
      return Icons.local_cafe_outlined;
    }
    if (text.contains('xe') ||
        text.contains('grab') ||
        text.contains('taxi') ||
        text.contains('xăng') ||
        text.contains('vé') ||
        text.contains('di chuyển')) {
      return Icons.directions_car_outlined;
    }
    if (text.contains('phòng') ||
        text.contains('khách sạn') ||
        text.contains('hotel') ||
        text.contains('nhà') ||
        text.contains('điện') ||
        text.contains('nước')) {
      return Icons.home_outlined;
    }
    if (text.contains('mua') ||
        text.contains('siêu thị') ||
        text.contains('chợ') ||
        text.contains('shop')) {
      return Icons.shopping_bag_outlined;
    }
    return Icons.receipt_long_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tintColor = color ?? scheme.primary;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color != null
            ? tintColor.withValues(alpha: 0.12)
            : scheme.primaryContainer,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Icon(
        iconFor(title, categoryName),
        size: size * 0.5,
        color: tintColor,
      ),
    );
  }
}

/// Tiêu đề mục theo mẫu thiết kế: đậm, rõ phân cấp, có nút "Xem tất cả" màu Royal Blue.
class SectionLabel extends StatelessWidget {
  const SectionLabel({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.s4),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: scheme.onSurface,
                ),
              ),
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 36),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                actionLabel!,
                style: TextStyle(
                  color: scheme.primary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Thẻ tổng quan số dư theo mẫu Midnight Navy + Royal Blue (tương phản cao WCAG AA).
class BalanceSummaryCard extends StatelessWidget {
  const BalanceSummaryCard({
    super.key,
    required this.net,
    required this.receivable,
    required this.payable,
    this.title,
    this.subtitle,
  });

  final double net;
  final double receivable;
  final double payable;
  final String? title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final statusText = net > 0
        ? tr(context, 'Đang được nhận', 'You are owed')
        : net < 0
        ? tr(context, 'Cần thanh toán', 'You owe')
        : tr(context, 'Đã cân bằng', 'All settled');
    final statusIcon = net > 0
        ? CupertinoIcons.arrow_down_left
        : net < 0
        ? CupertinoIcons.arrow_up_right
        : CupertinoIcons.checkmark_circle;
    final statusColor = net > 0
        ? AppColors.successOnDark
        : net < 0
        ? AppColors.errorOnDark
        : Colors.white.withValues(alpha: 0.78);

    return Container(
      padding: const EdgeInsets.all(AppDimensions.s20),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: AppDimensions.radius20,
        border: Border.all(
          color: AppColors.p400.withValues(alpha: 0.22),
          width: 0.9,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title ?? tr(context, 'Tổng số dư công nợ', 'Net balance'),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 12, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.s8),
          AnimatedMoneyText(
            amount: net,
            showSign: true,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.8,
            ),
          ),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.s4),
            Text(
              subtitle!,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 12.5,
              ),
            ),
          ],
          const SizedBox(height: AppDimensions.s16),
          Container(height: 0.8, color: Colors.white.withValues(alpha: 0.12)),
          const SizedBox(height: AppDimensions.s12),
          Row(
            children: [
              Expanded(
                child: _subMetric(
                  icon: CupertinoIcons.arrow_down_left,
                  color: AppColors.successOnDark,
                  label: tr(context, 'Được nhận', 'To receive'),
                  amount: receivable,
                ),
              ),
              Container(
                width: 0.8,
                height: 34,
                color: Colors.white.withValues(alpha: 0.12),
              ),
              const SizedBox(width: AppDimensions.s16),
              Expanded(
                child: _subMetric(
                  icon: CupertinoIcons.arrow_up_right,
                  color: AppColors.errorOnDark,
                  label: tr(context, 'Cần trả', 'To pay'),
                  amount: payable,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _subMetric({
    required IconData icon,
    required Color color,
    required String label,
    required double amount,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.68),
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.s4),
        AnimatedMoneyText(
          amount: amount,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Trạng thái trống chuẩn hóa, tối giản, tương thích Light & Dark mode.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PremiumSurface(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.s20,
        vertical: AppDimensions.s24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: AppDimensions.radius16,
            ),
            child: Icon(icon, size: 24, color: scheme.primary),
          ),
          const SizedBox(height: AppDimensions.s12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppDimensions.s4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppDimensions.s16),
            FilledButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

/// Trạng thái lỗi chuẩn hóa, rõ ràng, có nút thử lại.
class AppErrorState extends StatelessWidget {
  const AppErrorState({
    super.key,
    required this.title,
    required this.message,
    required this.onRetry,
    this.retryLabel,
  });

  final String title;
  final String message;
  final VoidCallback onRetry;
  final String? retryLabel;

  @override
  Widget build(BuildContext context) {
    final errorColor = AppColors.errorFor(context);
    return PremiumSurface(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.s20,
        vertical: AppDimensions.s24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.exclamationmark_circle,
            size: 36,
            color: errorColor,
          ),
          const SizedBox(height: AppDimensions.s12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppDimensions.s4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppDimensions.s16),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(retryLabel ?? tr(context, 'Thử lại', 'Retry')),
          ),
        ],
      ),
    );
  }
}
