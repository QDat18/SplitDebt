// Trách nhiệm file: Xây dựng màn hình profile screen theo chuẩn HIG với grouped list.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/app_strings.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/network/dio_client.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/widgets/grouped_list.dart';
import '../auth/login_screen.dart';
import '../expenses/receipt/receipt_ocr_lab_screen.dart';
import '../privacy/privacy_center_screen.dart';
import 'about_screen.dart';
import 'currency_settings_screen.dart';
import 'help_screen.dart';
import 'language_settings_screen.dart';
import 'notification_settings_screen.dart';
import 'personal_info_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  static Map<String, dynamic>? _cachedProfile;
  bool _loading = true;

  String _name = 'Người dùng';
  String _email = '';
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    if (_cachedProfile != null) {
      _name = _cachedProfile!['fullName']?.toString() ?? 'Người dùng';
      _email = _cachedProfile!['email']?.toString() ?? '';
      _avatarUrl = _cachedProfile!['avatarUrl']?.toString();
      _loading = false;
    }
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final response = await dioClient.get('/users/me');

      final raw = response.data;
      final data = raw is Map && raw['data'] is Map ? raw['data'] : raw;

      if (data is Map<String, dynamic> && mounted) {
        _cachedProfile = data;
        setState(() {
          _name = data['fullName']?.toString() ?? 'Người dùng';
          _email = data['email']?.toString() ?? '';
          _avatarUrl = data['avatarUrl']?.toString();
        });
      }
    } catch (_) {
      // Không chặn giao diện nếu endpoint profile lỗi.
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    _cachedProfile = null;
    await ref.read(authProvider.notifier).logout();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showAdaptiveDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog.adaptive(
        title: Text(context.tr('Đăng xuất?', 'Sign out?')),
        content: Text(context.tr(
          'Bạn sẽ cần đăng nhập lại để dùng ứng dụng.',
          'You will need to sign in again to use the app.',
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.tr('Huỷ', 'Cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              context.tr('Đăng xuất', 'Sign out'),
              style: const TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final locale = ref.watch(localeProvider);

    return Scaffold(
      backgroundColor: AppColors.n100,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator.adaptive())
            : ListView(
                padding: const EdgeInsets.symmetric(
                  vertical: AppDimensions.s24,
                ),
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 32,
                      backgroundColor: AppColors.p500,
                      backgroundImage: _avatarUrl != null && _avatarUrl!.isNotEmpty
                          ? NetworkImage(_avatarUrl!)
                          : null,
                      onBackgroundImageError: _avatarUrl != null && _avatarUrl!.isNotEmpty
                          ? (_, __) {}
                          : null,
                      child: _avatarUrl != null && _avatarUrl!.isNotEmpty
                          ? null
                          : Text(
                              _name.isEmpty ? '?' : _name.characters.first,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.s12),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.s24,
                    ),
                    child: Column(
                      children: [
                        Text(
                          _name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.s4),
                        Text(
                          _email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.n600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.s32),
                  GroupedSection(
                    header: context.tr('Tài khoản', 'Account'),
                    children: [
                      GroupedTile(
                        icon: Icons.person_outline,
                        title: context.tr('Thông tin cá nhân', 'Personal info'),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PersonalInfoScreen(
                              name: _name,
                              email: _email,
                              phone: _cachedProfile?['phone']?.toString(),
                              avatarUrl: _avatarUrl,
                              onAvatarChanged: (newUrl) {
                                setState(() {
                                  _avatarUrl = newUrl;
                                  if (_cachedProfile != null) {
                                    _cachedProfile!['avatarUrl'] = newUrl;
                                  }
                                });
                              },
                              onProfileUpdated: (newName, newPhone) {
                                setState(() {
                                  _name = newName;
                                  if (_cachedProfile != null) {
                                    _cachedProfile!['fullName'] = newName;
                                    _cachedProfile!['phone'] = newPhone;
                                  }
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                      GroupedTile(
                        icon: Icons.privacy_tip_outlined,
                        title: context.tr('Quyền riêng tư', 'Privacy'),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PrivacyCenterScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.s32),
                  GroupedSection(
                    header: context.tr('Ứng dụng', 'App'),
                    children: [
                      GroupedTile(
                        icon: Icons.notifications_none,
                        title: context.tr('Thông báo', 'Notifications'),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const NotificationSettingsScreen(),
                          ),
                        ),
                      ),
                      GroupedTile(
                        icon: Icons.attach_money,
                        title: context.tr('Tiền tệ', 'Currency'),
                        value: 'VND',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CurrencySettingsScreen(),
                          ),
                        ),
                      ),
                      GroupedTile(
                        icon: Icons.language,
                        title: context.tr('Ngôn ngữ', 'Language'),
                        value: AppStrings.languageName(locale),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LanguageSettingsScreen(),
                          ),
                        ),
                      ),
                      if (kDebugMode)
                        GroupedTile(
                          icon: Icons.document_scanner_outlined,
                          title: 'OCR Lab (Debug)',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ReceiptOcrLabScreen(),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.s32),
                  GroupedSection(
                    header: context.tr('Hỗ trợ', 'Support'),
                    children: [
                      GroupedTile(
                        icon: Icons.help_outline,
                        title: context.tr('Trợ giúp', 'Help'),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const HelpScreen(),
                          ),
                        ),
                      ),
                      GroupedTile(
                        icon: Icons.info_outline,
                        title: context.tr('Giới thiệu', 'About'),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AboutScreen(),
                          ),
                        ),
                      ),
                      GroupedTile(
                        icon: Icons.privacy_tip_outlined,
                        title: context.tr('Quyền riêng tư', 'Privacy'),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PrivacyCenterScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.s32),
                  GroupedSection(
                    children: [
                      GroupedTile(
                        title: context.tr('Đăng xuất', 'Sign out'),
                        destructive: true,
                        onTap: _confirmLogout,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.s24),
                ],
              ),
      ),
    );
  }
}
