import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import 'providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  Future<void> _register() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Vui lòng nhập đầy đủ thông tin',
          ),
        ),
      );

      return;
    }

    if (!email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Email không hợp lệ',
          ),
        ),
      );

      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Mật khẩu phải có ít nhất 6 ký tự',
          ),
        ),
      );

      return;
    }

    final success = await ref.read(authProvider.notifier).register(
          name,
          email,
          password,
        );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Đăng ký thành công! Vui lòng đăng nhập.',
          ),
        ),
      );

      Navigator.pop(context);

      return;
    }

    final error = ref.read(authProvider).error;

    String errorMessage = 'Đăng ký thất bại';

    if (error != null) {
      errorMessage = error.toString().replaceFirst('Exception: ', '');
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMessage),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(authProvider).isLoading;
    return Scaffold(
      appBar: AppBar(title: const Text('Tạo tài khoản')),
      body: SafeArea(
          child: ListView(padding: const EdgeInsets.all(20), children: [
        const SizedBox(height: 20),
        const Text('Họ và tên', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
            controller: _nameController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(hintText: 'Nguyễn Văn A')),
        const SizedBox(height: 20),
        const Text('Email', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(hintText: 'email@example.com')),
        const SizedBox(height: 20),
        const Text('Mật khẩu', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            onSubmitted: (_) {
              if (!loading) _register();
            },
            decoration: InputDecoration(
                hintText: 'Tối thiểu 6 ký tự',
                suffixIcon: IconButton(
                    tooltip: _obscurePassword ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
                    icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppTheme.textSecondaryColor),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword)))),
      ])),
      bottomNavigationBar: SafeArea(
          child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton(
                        onPressed: loading ? null : _register,
                        child: Text(loading ? 'Đang tạo...' : 'Tạo tài khoản')),
                    const SizedBox(height: 12),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Text('Đã có tài khoản? ',
                          style: TextStyle(
                              color: AppTheme.textSecondaryColor,
                              fontSize: 13)),
                      TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Đăng nhập'))
                    ])
                  ]))),
    );
  }
}
