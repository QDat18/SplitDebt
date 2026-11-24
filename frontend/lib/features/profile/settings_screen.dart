// Trách nhiệm file: Xây dựng màn hình settings screen và điều phối tương tác người dùng với trạng thái nghiệp vụ.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_typography.dart';
import '../auth/login_screen.dart';
import '../auth/providers/auth_provider.dart';
import 'user_preferences.dart';

/// ----------------------------------------------------------------------------
/// MÀN HÌNH CÀI ĐẶT CÁ NHÂN (SETTINGS SCREEN)
/// Cấu hình tùy chọn Thông báo và Đăng xuất
/// ----------------------------------------------------------------------------
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prefsAsync = ref.watch(userPreferencesProvider);

    return Scaffold(
      backgroundColor: AppColors.n50,
      appBar: AppBar(
        backgroundColor: AppColors.n50,
        elevation: 0,
        title: Text('Cài đặt & Cấu hình',
            style: AppTypography.title.copyWith(fontSize: 17)),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.s20, vertical: AppDimensions.s12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('THÔNG BÁO'),
              const SizedBox(height: AppDimensions.s12),
              _buildNotificationSettingsCard(prefsAsync),
              const SizedBox(height: AppDimensions.s24),
              OutlinedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text('Đăng xuất'),
                onPressed: () async {
                  await ref.read(authProvider.notifier).logout();
                  if (!context.mounted) return;
                  Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (_) => false);
                },
              ),
              const SizedBox(height: AppDimensions.s32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: AppTypography.caption.copyWith(
        letterSpacing: 1.0,
        fontWeight: FontWeight.w800,
        color: AppColors.p700,
      ),
    );
  }

  Widget _buildNotificationSettingsCard(
      AsyncValue<UserPreferences> prefsAsync) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.n0,
        borderRadius: AppDimensions.radius20,
        boxShadow: AppDimensions.shadowSm,
      ),
      child: prefsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(AppDimensions.s24),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (err, stack) => Padding(
          padding: const EdgeInsets.all(AppDimensions.s20),
          child: Column(
            children: [
              const Text('Không tải được cài đặt.'),
              const SizedBox(height: AppDimensions.s12),
              TextButton(
                onPressed: () =>
                    ref.read(userPreferencesProvider.notifier).load(),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
        data: (prefs) => Column(
          children: [
            SwitchListTile(
              activeColor: AppColors.p500,
              secondary: const Icon(Icons.notifications_active_rounded,
                  color: AppColors.warning),
              title: Text('Nhắc thanh toán nợ',
                  style: AppTypography.bodyMedium
                      .copyWith(fontWeight: FontWeight.w600)),
              subtitle: Text('Khi có người yêu cầu bạn thanh toán',
                  style: AppTypography.caption),
              value: prefs.notifyOnDebtReminder,
              onChanged: (val) async {
                final success = await ref
                    .read(userPreferencesProvider.notifier)
                    .setNotifyOnDebtReminder(val);
                if (!success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content:
                            Text('Không lưu được cài đặt. Vui lòng thử lại.')),
                  );
                }
              },
            ),
            const Divider(height: 1, color: AppColors.n100),
            SwitchListTile(
              activeColor: AppColors.p500,
              secondary: const Icon(Icons.check_circle_outline_rounded,
                  color: AppColors.success),
              title: Text('Cập nhật quyết toán',
                  style: AppTypography.bodyMedium
                      .copyWith(fontWeight: FontWeight.w600)),
              subtitle: Text(
                  'Khi khoản thanh toán được đánh dấu hoặc xác nhận',
                  style: AppTypography.caption),
              value: prefs.notifyOnSettlement,
              onChanged: (val) async {
                final success = await ref
                    .read(userPreferencesProvider.notifier)
                    .setNotifyOnSettlement(val);
                if (!success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content:
                            Text('Không lưu được cài đặt. Vui lòng thử lại.')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
