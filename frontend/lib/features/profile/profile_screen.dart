// Trách nhiệm file: Màn hình Cá nhân theo mẫu Midnight Navy Hero + thẻ nổi hồ sơ + danh sách cài đặt chuẩn Mobile.

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';
import '../../core/network/network_error.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/state/app_sync.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/widgets/fintech_components.dart';
import '../../core/widgets/motion_kit.dart';
import '../../core/widgets/premium_shell.dart';
import '../auth/login_screen.dart';
import '../groups/providers/group_provider.dart';
import '../notifications/notification_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  Map<String, dynamic>? _cachedProfile;
  bool _loading = true;
  String _name = '';
  String _email = '';
  String _phone = '';

  @override
  void initState() {
    super.initState();
    if (_cachedProfile != null) _applyProfile(_cachedProfile!);
    _loadProfile();
    appDataSyncSignal.addListener(_loadProfile);
  }

  @override
  void dispose() {
    appDataSyncSignal.removeListener(_loadProfile);
    super.dispose();
  }

  void _applyProfile(Map<String, dynamic> data) {
    _name = data['fullName']?.toString() ?? '';
    _email = data['email']?.toString() ?? '';
    _phone = data['phone']?.toString() ?? '';
    _loading = false;
  }

  Future<void> _loadProfile() async {
    try {
      final response = await dioClient.get('/users/me');
      final raw = response.data;
      final data = raw is Map && raw['data'] is Map ? raw['data'] : raw;
      if (data is Map && mounted) {
        final map = Map<String, dynamic>.from(data);
        _cachedProfile = map;
        setState(() => _applyProfile(map));
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _editProfile() async {
    final nameController = TextEditingController(text: _name);
    final phoneController = TextEditingController(text: _phone);
    final formKey = GlobalKey<FormState>();

    final save = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(tr(dialogContext, 'Cập nhật hồ sơ', 'Update profile')),
        content: SizedBox(
          width: 420,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: tr(dialogContext, 'Họ và tên', 'Full name'),
                    prefixIcon: const Icon(CupertinoIcons.person),
                  ),
                  validator: (value) {
                    final name = value?.trim() ?? '';
                    if (name.length < 2) {
                      return tr(
                        dialogContext,
                        'Họ tên phải có ít nhất 2 ký tự.',
                        'Name must be at least 2 characters.',
                      );
                    }
                    if (name.length > 100) {
                      return tr(
                        dialogContext,
                        'Họ tên tối đa 100 ký tự.',
                        'Name must be at most 100 characters.',
                      );
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppDimensions.s12),
                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: tr(
                      dialogContext,
                      'Số điện thoại',
                      'Phone number',
                    ),
                    prefixIcon: const Icon(CupertinoIcons.phone),
                  ),
                  validator: (value) {
                    final phone = value?.trim() ?? '';
                    if (phone.isEmpty) return null;
                    return RegExp(r'^[0-9+(). -]{8,20}$').hasMatch(phone)
                        ? null
                        : tr(
                            dialogContext,
                            'Số điện thoại không hợp lệ.',
                            'Invalid phone number.',
                          );
                  },
                ),
                const SizedBox(height: AppDimensions.s12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    tr(
                      dialogContext,
                      'Email là tài khoản đăng nhập nên không thay đổi tại đây.',
                      'Your login email cannot be changed here.',
                    ),
                    style: Theme.of(dialogContext).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(tr(dialogContext, 'Hủy', 'Cancel')),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() == true) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: Text(tr(dialogContext, 'Lưu', 'Save')),
          ),
        ],
      ),
    );

    if (save != true || !mounted) {
      nameController.dispose();
      phoneController.dispose();
      return;
    }

    try {
      final response = await dioClient.patch(
        '/users/me',
        data: {
          'fullName': nameController.text.trim(),
          'phone': phoneController.text.trim(),
        },
      );
      final raw = response.data;
      final data = raw is Map && raw['data'] is Map ? raw['data'] : raw;
      if (data is Map && mounted) {
        final map = Map<String, dynamic>.from(data);
        _cachedProfile = map;
        setState(() => _applyProfile(map));
        notifyDataChanged();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr(context, 'Đã cập nhật hồ sơ.', 'Profile updated.'),
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        final msg = error is DioException
            ? networkErrorMessage(error)
            : tr(
                context,
                'Không cập nhật được hồ sơ. Vui lòng thử lại.',
                'Could not update profile. Please try again.',
              );
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      nameController.dispose();
      phoneController.dispose();
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr(ctx, 'Đăng xuất', 'Sign out')),
        content: Text(
          tr(
            ctx,
            'Bạn có chắc muốn đăng xuất khỏi SplitDebt?',
            'Are you sure you want to sign out of SplitDebt?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr(ctx, 'Hủy', 'Cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.errorFor(ctx),
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr(ctx, 'Đăng xuất', 'Sign out')),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    _cachedProfile = null;
    ref.invalidate(userGroupsProvider);
    ref.read(themeModeProvider.notifier).state = ThemeMode.system;
    ref.read(localeProvider.notifier).state = const Locale('vi');
    await ref.read(authProvider.notifier).logout();
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushAndRemoveUntil(fintechRoute(const LoginScreen()), (_) => false);
  }

  void _info(String title, String body) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(ctx).textTheme.titleMedium),
              const SizedBox(height: AppDimensions.s8),
              Text(
                body,
                style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuRow({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: scheme.primaryContainer,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: scheme.primary, size: 19),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
      ),
      subtitle: subtitle != null
          ? Text(subtitle, style: Theme.of(context).textTheme.bodySmall)
          : null,
      trailing: Icon(
        CupertinoIcons.chevron_forward,
        size: 16,
        color: scheme.onSurfaceVariant,
      ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final scheme = Theme.of(context).colorScheme;
    final displayName = _name.isEmpty
        ? tr(context, 'Người dùng', 'User')
        : _name;
    final safeTop = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: PremiumBackground(
        child: _loading
            ? Padding(
                padding: EdgeInsets.fromLTRB(16, safeTop + 16, 16, 16),
                child: const Column(
                  children: [
                    ShimmerBox(width: double.infinity, height: 170, radius: 20),
                    SizedBox(height: 16),
                    ShimmerBox(width: double.infinity, height: 180, radius: 16),
                  ],
                ),
              )
            : RefreshIndicator(
                color: scheme.primary,
                onRefresh: _loadProfile,
                child: ListView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  padding: const EdgeInsets.only(bottom: 96),
                  children: [
                    NavyHeroHeader(
                      headerContent: Column(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: AppColors.p500,
                            child: Text(
                              displayName.characters.first.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppDimensions.s12),
                          Text(
                            displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _phone.isNotEmpty ? '$_email · $_phone' : _email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.72),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      floatingCard: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: AppDimensions.maxContentWidth,
                          ),
                          child: PremiumSurface(
                            elevated: true,
                            padding: const EdgeInsets.all(AppDimensions.s14),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tr(
                                          context,
                                          'Tài khoản cá nhân',
                                          'Personal account',
                                        ),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14.5,
                                          color: scheme.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        tr(
                                          context,
                                          'Cập nhật tên hiển thị & số điện thoại',
                                          'Update display name & phone',
                                        ),
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: AppDimensions.s12),
                                NavyActionButton(
                                  label: tr(context, 'Chỉnh sửa', 'Edit'),
                                  onPressed: _editProfile,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.s20),
                    Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: AppDimensions.maxContentWidth,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.s16,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              PremiumSurface(
                                padding: EdgeInsets.zero,
                                child: Column(
                                  children: [
                                    _menuRow(
                                      icon: CupertinoIcons.bell,
                                      title: tr(
                                        context,
                                        'Thông báo',
                                        'Notifications',
                                      ),
                                      onTap: () => Navigator.push(
                                        context,
                                        fintechRoute(
                                          const NotificationScreen(),
                                        ),
                                      ),
                                    ),
                                    const Divider(height: 1, indent: 64),
                                    _menuRow(
                                      icon: CupertinoIcons.gear,
                                      title: tr(context, 'Cài đặt', 'Settings'),
                                      subtitle: tr(
                                        context,
                                        'Giao diện, ngôn ngữ và thông báo đẩy',
                                        'Appearance, language and push alerts',
                                      ),
                                      onTap: () => Navigator.push(
                                        context,
                                        fintechRoute(const SettingsScreen()),
                                      ),
                                    ),
                                    const Divider(height: 1, indent: 64),
                                    _menuRow(
                                      icon: CupertinoIcons.question_circle,
                                      title: tr(
                                        context,
                                        'Hướng dẫn sử dụng',
                                        'User guide',
                                      ),
                                      onTap: () => _info(
                                        tr(
                                          context,
                                          'Hướng dẫn sử dụng',
                                          'User guide',
                                        ),
                                        tr(
                                          context,
                                          'Tạo nhóm, thêm thành viên bằng email, ghi nhận khoản chi (thủ công hoặc quét hóa đơn) và chọn cách chia phù hợp. Dùng Thanh toán để tối ưu số lần chuyển khoản; công nợ chỉ trừ sau khi người nhận xác nhận.',
                                          'Create a group, add members by email, record expenses manually or by scanning receipts, and choose a split method. Use Settle up to minimize transfers; balances update only after the recipient confirms.',
                                        ),
                                      ),
                                    ),
                                    const Divider(height: 1, indent: 64),
                                    _menuRow(
                                      icon: CupertinoIcons.info_circle,
                                      title: tr(
                                        context,
                                        'Giới thiệu SplitDebt',
                                        'About SplitDebt',
                                      ),
                                      onTap: () => _info(
                                        'SplitDebt',
                                        tr(
                                          context,
                                          'Ứng dụng quản lý chi tiêu nhóm, tối ưu hóa công nợ và xác nhận thanh toán hai bước.',
                                          'Group expense management with smart debt simplification and two-step payment confirmation.',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: AppDimensions.s20),
                              OutlinedButton.icon(
                                onPressed: _logout,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.errorFor(context),
                                  side: BorderSide(
                                    color: AppColors.errorFor(context),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.logout_rounded,
                                  size: 18,
                                ),
                                label: Text(
                                  tr(context, 'Đăng xuất', 'Sign out'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
