// Trách nhiệm file: Xây dựng màn hình profile screen theo chuẩn HIG với grouped list.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/widgets/grouped_list.dart';
import '../auth/login_screen.dart';
import 'notification_settings_screen.dart';

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

  @override
  void initState() {
    super.initState();
    if (_cachedProfile != null) {
      _name = _cachedProfile!['fullName']?.toString() ?? 'Người dùng';
      _email = _cachedProfile!['email']?.toString() ?? '';
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
        title: const Text('Đăng xuất?'),
        content: const Text('Bạn sẽ cần đăng nhập lại để dùng ứng dụng.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Huỷ'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Đăng xuất',
              style: TextStyle(
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

  void _showPersonalInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.n100,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: AppDimensions.s24),
          child: GroupedSection(
            header: 'Thông tin cá nhân',
            children: [
              GroupedTile(
                title: 'Họ và tên',
                value: _name,
              ),
              GroupedTile(
                title: 'Email',
                value: _email,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _info(String title, String body) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.s24,
              vertical: AppDimensions.s16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppDimensions.s16),
                Text(
                  body,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.n800,
                  ),
                ),
                const SizedBox(height: AppDimensions.s24),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

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
                      child: Text(
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
                    header: 'Tài khoản',
                    children: [
                      GroupedTile(
                        icon: Icons.person_outline,
                        title: 'Thông tin cá nhân',
                        onTap: () => _showPersonalInfo(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.s32),
                  GroupedSection(
                    header: 'Ứng dụng',
                    children: [
                      GroupedTile(
                        icon: Icons.notifications_none,
                        title: 'Thông báo',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const NotificationSettingsScreen(),
                          ),
                        ),
                      ),
                      const GroupedTile(
                        icon: Icons.attach_money,
                        title: 'Tiền tệ',
                        value: 'VND',
                      ),
                      const GroupedTile(
                        icon: Icons.language,
                        title: 'Ngôn ngữ',
                        value: 'Tiếng Việt',
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.s32),
                  GroupedSection(
                    header: 'Hỗ trợ',
                    children: [
                      GroupedTile(
                        icon: Icons.help_outline,
                        title: 'Trợ giúp',
                        onTap: () => _info(
                          'Trợ giúp',
                          'Tạo nhóm, thêm thành viên bằng email đã đăng ký rồi ghi khoản chi. Người trả báo đã thanh toán, người nhận xác nhận để cập nhật công nợ.',
                        ),
                      ),
                      GroupedTile(
                        icon: Icons.info_outline,
                        title: 'Giới thiệu',
                        onTap: () => _info(
                          'XÉN NỢ',
                          'Chia tiền nhóm, hết lăn tăn. Quản lý khoản chi, tối ưu công nợ và xác nhận thanh toán hai chiều.',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.s32),
                  GroupedSection(
                    children: [
                      GroupedTile(
                        title: 'Đăng xuất',
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
