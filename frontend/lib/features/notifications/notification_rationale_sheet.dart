// Trách nhiệm file: Bottom sheet giải thích lý do xin quyền thông báo trước khi mở hộp thoại hệ thống.

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';

class NotificationRationaleSheet extends StatelessWidget {
  const NotificationRationaleSheet({super.key});

  static Future<bool> show(BuildContext context) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.n0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const NotificationRationaleSheet(),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.s20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: AppDimensions.radius12,
                ),
                child: const Icon(
                  Icons.notifications_active_outlined,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.s16),
            Text(
              'Bật thông báo',
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.n900,
              ),
            ),
            const SizedBox(height: AppDimensions.s8),
            Text(
              'Bật thông báo để biết ngay khi có người yêu cầu thanh toán, xác nhận khoản trả hoặc nhắn tin trong nhóm.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.n600,
              ),
            ),
            const SizedBox(height: AppDimensions.s20),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Bật thông báo'),
            ),
            const SizedBox(height: AppDimensions.s8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Để sau'),
            ),
          ],
        ),
      ),
    );
  }
}

