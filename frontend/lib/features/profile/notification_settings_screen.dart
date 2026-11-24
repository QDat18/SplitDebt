// Trách nhiệm file: Xây dựng màn hình cài đặt thông báo (NotificationSettingsScreen) theo chuẩn Apple HIG.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
        title: const Text('Thông báo'),
        backgroundColor: AppColors.n100,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.s24),
        children: [
          GroupedSection(
            header: 'Nhận thông báo khi',
            footer: 'Thông báo trong ứng dụng vẫn được lưu kể cả khi tắt.',
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
                  title: 'Nhắc thanh toán nợ',
                  subtitle: 'Khi có người yêu cầu bạn thanh toán',
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
                  title: 'Cập nhật quyết toán',
                  subtitle:
                      'Khi khoản thanh toán được đánh dấu hoặc xác nhận',
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
