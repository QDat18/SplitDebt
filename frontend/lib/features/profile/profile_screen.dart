// Trách nhiệm file: Màn hình Cá nhân chuẩn iOS Settings / Apple ID, cập nhật hồ sơ trực tiếp lên backend DB (PATCH /users/me).

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/state/app_sync.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/motion_kit.dart';
import '../../core/widgets/premium_shell.dart';
import '../auth/login_screen.dart';
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
  String _name = 'Người dùng';
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
    _name = data['fullName']?.toString() ?? 'Người dùng';
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
        title: const Text('Cập nhật hồ sơ'),
        content: SizedBox(
          width: 420,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Họ và tên',
                    prefixIcon: Icon(CupertinoIcons.person),
                  ),
                  validator: (value) {
                    final name = value?.trim() ?? '';
                    if (name.length < 2) {
                      return 'Họ tên phải có ít nhất 2 ký tự.';
                    }
                    if (name.length > 100) return 'Họ tên tối đa 100 ký tự.';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Số điện thoại',
                    prefixIcon: Icon(CupertinoIcons.phone),
                  ),
                  validator: (value) {
                    final phone = value?.trim() ?? '';
                    if (phone.isEmpty) return null;
                    return RegExp(r'^[0-9+(). -]{8,20}$').hasMatch(phone)
                        ? null
                        : 'Số điện thoại không hợp lệ.';
                  },
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Email là tài khoản đăng nhập nên không thay đổi tại đây.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() == true) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: const Text('Lưu'),
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
      final response = await dioClient.patch('/users/me', data: {
        'fullName': nameController.text.trim(),
        'phone': phoneController.text.trim(),
      });
      final raw = response.data;
      final data = raw is Map && raw['data'] is Map ? raw['data'] : raw;
      if (data is Map && mounted) {
        final map = Map<String, dynamic>.from(data);
        _cachedProfile = map;
        setState(() => _applyProfile(map));
        notifyDataChanged();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã lưu hồ sơ vào hệ thống.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không cập nhật được hồ sơ: $error')),
        );
      }
    } finally {
      nameController.dispose();
      phoneController.dispose();
    }
  }

  Future<void> _logout() async {
    final confirm = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc muốn đăng xuất khỏi SplitDebt?'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    _cachedProfile = null;
    ref.read(themeModeProvider.notifier).state = ThemeMode.system;
    ref.read(localeProvider.notifier).state = const Locale('vi');
    await ref.read(authProvider.notifier).logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      fintechRoute(const LoginScreen()),
      (_) => false,
    );
  }

  void _info(String title, String body) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Text(
              body,
              style: const TextStyle(
                color: AppColors.n600,
                height: 1.5,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _iosRow(
    IconData icon,
    Color iconBg,
    String title,
    VoidCallback tap,
  ) =>
      ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(icon, color: Colors.white, size: 17),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
        trailing: const Icon(
          CupertinoIcons.chevron_forward,
          size: 16,
          color: AppColors.n400,
        ),
        onTap: tap,
      );

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: PremiumBackground(
        child: SafeArea(
          bottom: false,
          child: _loading
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      ShimmerBox(
                          width: double.infinity, height: 88, radius: 14),
                      SizedBox(height: 16),
                      ShimmerBox(
                          width: double.infinity, height: 210, radius: 14),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: AppColors.p500,
                  onRefresh: _loadProfile,
                  child: ListView(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                    children: [
                      PremiumHeader(
                          eyebrow: '',
                          title: tr(context, 'Cá nhân', 'Profile')),
                      const SizedBox(height: 16),
                      // Apple ID style Profile Row
                      ScaleTap(
                        onTap: _editProfile,
                        child: PremiumSurface(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: const Color(0xFF1C1C1E),
                                child: Text(
                                  _name.isEmpty
                                      ? '?'
                                      : _name.characters.first.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _phone.isNotEmpty
                                          ? '$_email • $_phone'
                                          : _email,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AppColors.n500,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                CupertinoIcons.chevron_forward,
                                size: 17,
                                color: AppColors.n400,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      PremiumSurface(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            _iosRow(
                              CupertinoIcons.bell_fill,
                              AppColors.error,
                              'Thông báo',
                              () => Navigator.push(
                                context,
                                fintechRoute(const NotificationScreen()),
                              ),
                            ),
                            const Divider(height: 1, indent: 56),
                            _iosRow(
                              CupertinoIcons.gear_alt_fill,
                              AppColors.n500,
                              tr(context, 'Cài đặt', 'Settings'),
                              () => Navigator.push(
                                context,
                                fintechRoute(const SettingsScreen()),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      PremiumSurface(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            _iosRow(
                              CupertinoIcons.question_circle_fill,
                              AppColors.p500,
                              'Hướng dẫn sử dụng',
                              () => _info(
                                'Hướng dẫn sử dụng',
                                'Tạo hoặc tham gia nhóm bằng mã mời, thêm khoản chi, chọn chế độ chia (đều, số tiền, %, trọng số hoặc theo món), sau đó dùng Xén nợ để tối ưu số lần chuyển khoản. Công nợ chỉ trừ khi người nhận xác nhận đã nhận tiền.',
                              ),
                            ),
                            const Divider(height: 1, indent: 56),
                            _iosRow(
                              CupertinoIcons.info_circle_fill,
                              AppColors.success,
                              'Giới thiệu SplitDebt',
                              () => _info(
                                'SplitDebt',
                                'Ứng dụng quản lý chi tiêu nhóm, tối ưu hóa công nợ và xác nhận thanh toán hai bước.',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      ScaleTap(
                        onTap: _logout,
                        child: const PremiumSurface(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: Center(
                            child: Text(
                              'Đăng xuất',
                              style: TextStyle(
                                color: AppColors.error,
                                fontWeight: FontWeight.w600,
                                fontSize: 15.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
