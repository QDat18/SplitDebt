// Trách nhiệm file: Xây dựng màn hình cài đặt thông báo (NotificationSettingsScreen) theo chuẩn Apple HIG.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/widgets/grouped_list.dart';
import 'user_preferences.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final prefsAsync = ref.watch(userPreferencesProvider);
    final notifier = ref.read(userPreferencesProvider.notifier);
    final isSaving = notifier.isSaving;

    return Scaffold(
      backgroundColor: AppColors.n100,
      appBar: AppBar(
        title: Text(context.tr('Thông báo', 'Notifications')),
        backgroundColor: AppColors.n100,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.s24),
        children: [
          GroupedSection(
            header: context.tr('Nhận thông báo khi', 'Notify me when'),
            footer: context.tr(
              'Thông báo trong ứng dụng vẫn được lưu kể cả khi tắt.',
              'In-app notifications are still saved even when muted.',
            ),
            children: prefsAsync.when(
              loading: () => [
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 52),
                  child: const Center(
                    child: CircularProgressIndicator.adaptive(),
                  ),
                ),
              ],
              error: (err, stack) => [
                GroupedTile(
                  title: 'Không tải được cài đặt',
                  trailing: TextButton(
                    onPressed: () =>
                        ref.read(userPreferencesProvider.notifier).load(),
                    child: const Text('Thử lại'),
                  ),
                ),
              ],
              data: (prefs) => [
                GroupedSwitchTile(
                  icon: Icons.payments_outlined,
                  title: context.tr('Nhắc thanh toán nợ', 'Debt reminders'),
                  subtitle: context.tr(
                    'Khi có người yêu cầu bạn thanh toán',
                    'When someone requests a payment from you',
                  ),
                  value: prefs.notifyOnDebtReminder,
                  onChanged: isSaving
                      ? null
                      : (val) async {
                          setState(() {});
                          final success =
                              await notifier.setNotifyOnDebtReminder(val);
                          if (mounted) setState(() {});
                          if (success == false && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Không lưu được cài đặt. Vui lòng thử lại.'),
                              ),
                            );
                          }
                        },
                ),
                GroupedSwitchTile(
                  icon: Icons.task_alt,
                  title: context.tr('Cập nhật quyết toán', 'Settlement updates'),
                  subtitle: context.tr(
                    'Khi khoản thanh toán được đánh dấu hoặc xác nhận',
                    'When a payment is marked paid or confirmed',
                  ),
                  value: prefs.notifyOnSettlement,
                  onChanged: isSaving
                      ? null
                      : (val) async {
                          setState(() {});
                          final success =
                              await notifier.setNotifyOnSettlement(val);
                          if (mounted) setState(() {});
                          if (success == false && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Không lưu được cài đặt. Vui lòng thử lại.'),
                              ),
                            );
                          }
                        },
                ),
                GroupedSwitchTile(
                  icon: Icons.chat_bubble_outline,
                  title: context.tr('Tin nhắn nhóm', 'Group messages'),
                  subtitle: context.tr(
                    'Khi có tin nhắn mới trong nhóm',
                    'When there is a new message in a group',
                  ),
                  value: prefs.notifyOnGroupMessage,
                  onChanged: isSaving
                      ? null
                      : (val) async {
                          setState(() {});
                          final success =
                              await notifier.setNotifyOnGroupMessage(val);
                          if (mounted) setState(() {});
                          if (success == false && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Không lưu được cài đặt. Vui lòng thử lại.'),
                              ),
                            );
                          }
                        },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
