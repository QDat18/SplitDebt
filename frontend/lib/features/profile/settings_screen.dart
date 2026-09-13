import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_typography.dart';
import '../auth/providers/auth_provider.dart';
import '../auth/login_screen.dart';

/// ----------------------------------------------------------------------------
/// MÀN HÌNH CÀI ĐẶT NHÓM & CÁ NHÂN (SETTINGS SCREEN)
/// Cấu hình Tiền tệ, Hạn mức ngân sách, Auto-Freeze, Dark Mode & Notification
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

  // Cấu hình Cài đặt Nhóm
  String _selectedCurrency = 'VND';
  bool _smartSettlementEnabled = true;
  double _monthlyBudget = 5000000;
  double _autoFreezeDay = 28;

  // Cấu hình Cài đặt Cá nhân
  bool _isDarkMode = false;
  String _language = 'Tiếng Việt';
  bool _notifyDebtReminder = true;
  bool _biometricsEnabled = true;

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
              // --- 1. PHẦN CÀI ĐẶT NHÓM ---
              _buildSectionHeader('CÀI ĐẶT NHÓM (DU LỊCH HÀ GIANG)'),
              const SizedBox(height: AppDimensions.s12),
              _buildGroupSettingsCard(),
              const SizedBox(height: AppDimensions.s24),

              // --- 2. PHẦN CÀI ĐẶT CÁ NHÂN ---
              _buildSectionHeader('CÀI ĐẶT CÁ NHÂN & ỨNG DỤNG'),
              const SizedBox(height: AppDimensions.s12),
              _buildUserSettingsCard(),
              const SizedBox(height: AppDimensions.s20),
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

  // --- CARD CÀI ĐẶT NHÓM ---
  Widget _buildGroupSettingsCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.n0,
        borderRadius: AppDimensions.radius20,
        boxShadow: AppDimensions.shadowSm,
      ),
      child: Column(
        children: [
          // Đơn vị tiền tệ
          ListTile(
            leading: const Icon(Icons.monetization_on_rounded,
                color: AppColors.p500),
            title: Text('Đơn vị tiền tệ nhóm',
                style: AppTypography.bodyMedium
                    .copyWith(fontWeight: FontWeight.w600)),
            trailing: DropdownButton<String>(
              value: _selectedCurrency,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 'VND', child: Text('VND (₫)')),
                DropdownMenuItem(value: 'USD', child: Text('USD (\$)')),
                DropdownMenuItem(value: 'EUR', child: Text('EUR (€)')),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedCurrency = val;
                  });
                }
              },
            ),
          ),

          const Divider(height: 1, color: AppColors.n100),

          // Tối ưu nợ thông minh (Smart Settlement Min-Cash-Flow)
          SwitchListTile(
            activeColor: AppColors.p500,
            secondary: const Icon(Icons.bolt_rounded, color: AppColors.warning),
            title: Text('Tối ưu nợ thông minh (Min-Cash-Flow)',
                style: AppTypography.bodyMedium
                    .copyWith(fontWeight: FontWeight.w600)),
            subtitle: Text('Rút gọn các giao dịch nợ vòng quanh',
                style: AppTypography.caption),
            value: _smartSettlementEnabled,
            onChanged: (val) {
              setState(() {
                _smartSettlementEnabled = val;
              });
            },
          ),

          const Divider(height: 1, color: AppColors.n100),

          // Hạn mức ngân sách hàng tháng
          Padding(
            padding: const EdgeInsets.all(AppDimensions.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Ngân sách hàng tháng nhóm',
                        style: AppTypography.bodyMedium
                            .copyWith(fontWeight: FontWeight.w600)),
                    Text(
                        '${(_monthlyBudget / 1000000).toStringAsFixed(1)} Tr ₫',
                        style: AppTypography.title
                            .copyWith(fontSize: 14, color: AppColors.p600)),
                  ],
                ),
                Slider(
                  value: _monthlyBudget,
                  min: 1000000,
                  max: 20000000,
                  divisions: 19,
                  activeColor: AppColors.p500,
                  onChanged: (val) {
                    setState(() {
                      _monthlyBudget = val;
                    });
                  },
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.n100),

          // Ngày tự động đóng băng sổ sách
          ListTile(
            leading: const Icon(Icons.ac_unit_rounded, color: AppColors.info),
            title: Text('Ngày tự đóng băng sổ sách',
                style: AppTypography.bodyMedium
                    .copyWith(fontWeight: FontWeight.w600)),
            subtitle: Text(
                'Tự động chốt sổ vào ngày ${_autoFreezeDay.toInt()} hàng tháng',
                style: AppTypography.caption),
            trailing: Text('Ngày ${_autoFreezeDay.toInt()}',
                style: AppTypography.title
                    .copyWith(fontSize: 14, color: AppColors.p600)),
          ),
        ],
      ),
    );
  }

  // --- CARD CÀI ĐẶT CÁ NHÂN ---
  Widget _buildUserSettingsCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.n0,
        borderRadius: AppDimensions.radius20,
        boxShadow: AppDimensions.shadowSm,
      ),
      child: Column(
        children: [
          // Dark Mode Toggle
          SwitchListTile(
            activeColor: AppColors.p500,
            secondary:
                const Icon(Icons.dark_mode_rounded, color: AppColors.p500),
            title: Text('Giao diện Tối (Dark Mode)',
                style: AppTypography.bodyMedium
                    .copyWith(fontWeight: FontWeight.w600)),
            value: _isDarkMode,
            onChanged: (val) {
              setState(() {
                _isDarkMode = val;
              });
            },
          ),

          const Divider(height: 1, color: AppColors.n100),

          // Ngôn ngữ
          ListTile(
            leading: const Icon(Icons.language_rounded, color: AppColors.p500),
            title: Text('Ngôn ngữ',
                style: AppTypography.bodyMedium
                    .copyWith(fontWeight: FontWeight.w600)),
            trailing: DropdownButton<String>(
              value: _language,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(
                    value: 'Tiếng Việt', child: Text('Tiếng Việt 🇻🇳')),
                DropdownMenuItem(value: 'English', child: Text('English 🇺🇸')),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _language = val;
                  });
                }
              },
            ),
          ),

          const Divider(height: 1, color: AppColors.n100),

          // Sinh trắc học Biometrics
          SwitchListTile(
            activeColor: AppColors.p500,
            secondary:
                const Icon(Icons.fingerprint_rounded, color: AppColors.success),
            title: Text('Xác thực Sinh trắc học (FaceID)',
                style: AppTypography.bodyMedium
                    .copyWith(fontWeight: FontWeight.w600)),
            subtitle: Text('Bảo mật mở app bằng vân tay/FaceID',
                style: AppTypography.caption),
            value: _biometricsEnabled,
            onChanged: (val) {
              setState(() {
                _biometricsEnabled = val;
              });
            },
          ),

          const Divider(height: 1, color: AppColors.n100),

          // Thông báo nhắc nợ
          SwitchListTile(
            activeColor: AppColors.p500,
            secondary: const Icon(Icons.notifications_active_rounded,
                color: AppColors.warning),
            title: Text('Thông báo nhắc nợ & Quyết toán',
                style: AppTypography.bodyMedium
                    .copyWith(fontWeight: FontWeight.w600)),
            value: _notifyDebtReminder,
            onChanged: (val) {
              setState(() {
                _notifyDebtReminder = val;
              });
            },
          ),
        ],
      ),
    );
  }
}
