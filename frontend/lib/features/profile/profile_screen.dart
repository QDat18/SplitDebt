import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() =>
      _ProfileScreenState();
}

class _ProfileScreenState
    extends ConsumerState<ProfileScreen> {
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
      final response =
      await dioClient.get(
        '/users/me',
      );

      final data = response.data;

      if (data is Map<String, dynamic> &&
          mounted) {
        setState(() {
          _name =
              data['fullName']
                  ?.toString() ??
                  'Người dùng';

          _email =
              data['email']
                  ?.toString() ??
                  '';
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
    await ref
        .read(authProvider.notifier)
        .logout();

    if (!mounted) return;

    Navigator.of(context)
        .pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) =>
        const LoginScreen(),
      ),
          (route) => false,
    );
  }

  @override
  Widget build(
      BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Hồ sơ cá nhân',
        ),
        backgroundColor:
        Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: _loading
          ? const Center(
        child:
        CircularProgressIndicator(),
      )
          : SingleChildScrollView(
        padding:
        const EdgeInsets.all(
          24,
        ),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor:
              AppTheme
                  .primaryColor,
              child: Icon(
                Icons.person,
                size: 50,
                color:
                Colors.white,
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            Text(
              _name,
              style:
              Theme.of(context)
                  .textTheme
                  .headlineMedium,
            ),

            const SizedBox(
              height: 4,
            ),

            Text(
              _email,
              style:
              Theme.of(context)
                  .textTheme
                  .bodyMedium,
            ),

            const SizedBox(
              height: 32,
            ),

            const Card(
              child: ListTile(
                leading: Icon(
                  Icons
                      .check_circle_outline,
                ),
                title: Text(
                  'Đăng nhập backend thành công',
                ),
                subtitle: Text(
                  'JWT đã được lưu trên thiết bị',
                ),
              ),
            ),

            const SizedBox(
              height: 24,
            ),

            SizedBox(
              width:
              double.infinity,
              child:
              OutlinedButton(
                onPressed:
                _logout,
                style:
                OutlinedButton
                    .styleFrom(
                  foregroundColor:
                  AppTheme
                      .errorColor,
                  side:
                  const BorderSide(
                    color:
                    AppTheme
                        .errorColor,
                  ),
                ),
                child:
                const Text(
                  'Đăng xuất',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}