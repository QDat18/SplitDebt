import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../auth/login_screen.dart';
import '../notifications/notification_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _loading = true;

  String _name = 'Người dùng';
  String _email = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final response = await dioClient.get(
        '/users/me',
      );

      final raw = response.data;
      final data = raw is Map && raw['data'] is Map ? raw['data'] : raw;

      if (data is Map<String, dynamic> && mounted) {
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
    await ref.read(authProvider.notifier).logout();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  void _info(String title, String body) {
    showModalBottomSheet(
        context: context,
        showDragHandle: true,
        builder: (_) => Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Text(body),
                  const SizedBox(height: 24)
                ])));
  }

  Widget _row(IconData icon, String title, VoidCallback tap) => ListTile(
        leading: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
                color: const Color(0xFFF0EDFF),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: AppTheme.primaryColor, size: 20)),
        title: Text(title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
        onTap: tap,
      );
  @override
  Widget build(BuildContext context) => Scaffold(
      body: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(padding: const EdgeInsets.all(20), children: [
                  const SizedBox(height: 24),
                  Center(
                      child: CircleAvatar(
                          radius: 34,
                          backgroundColor: AppTheme.primaryColor,
                          child: Text(
                              _name.isEmpty ? '?' : _name.characters.first,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold)))),
                  const SizedBox(height: 14),
                  Text(_name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(_email,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Color(0xFF778092), fontSize: 13)),
                  const SizedBox(height: 26),
                  Card(
                      child: Column(children: [
                    _row(Icons.person_outline, 'Thông tin cá nhân',
                        () => _info('Thông tin cá nhân', '$_name\n$_email')),
                    const Divider(height: 1),
                    _row(
                        Icons.notifications_none,
                        'Thông báo',
                        () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const NotificationScreen()))),
                    const Divider(height: 1),
                    _row(
                        Icons.payments_outlined,
                        'Tiền tệ',
                        () => _info('Tiền tệ',
                            'Các khoản chi và thanh toán của ứng dụng được ghi nhận bằng Việt Nam Đồng (VND).')),
                    const Divider(height: 1),
                    _row(Icons.language, 'Ngôn ngữ',
                        () => _info('Ngôn ngữ', 'Tiếng Việt')),
                    const Divider(height: 1),
                    _row(
                        Icons.shield_outlined,
                        'Bảo mật',
                        () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const SettingsScreen()))),
                    const Divider(height: 1),
                    _row(
                        Icons.help_outline,
                        'Trợ giúp',
                        () => _info('Trợ giúp',
                            'Tạo nhóm, thêm thành viên bằng email đã đăng ký rồi ghi khoản chi. Người trả báo đã thanh toán, người nhận xác nhận để cập nhật công nợ.')),
                    const Divider(height: 1),
                    _row(
                        Icons.info_outline,
                        'Giới thiệu',
                        () => _info('XÉN NỢ',
                            'Chia tiền nhóm, hết lăn tăn. Quản lý khoản chi, tối ưu công nợ và xác nhận thanh toán hai chiều.')),
                  ])),
                  const SizedBox(height: 8),
                  Card(
                      child: ListTile(
                          onTap: _logout,
                          leading: const Icon(Icons.logout,
                              color: Color(0xFFFF5261)),
                          title: const Text('Đăng xuất',
                              style: TextStyle(
                                  color: Color(0xFFFF5261),
                                  fontWeight: FontWeight.w700)))),
                ])));
}
