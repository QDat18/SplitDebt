// Trách nhiệm file: Màn hình đăng ký tài khoản với validation trực tiếp, thông báo lỗi thân thiện và bảo vệ chống gửi trùng.

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/network_error.dart';
import '../../core/state/app_sync.dart';
import '../../core/theme/app_dimensions.dart';
import 'providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _formatError(Object? error) {
    if (error is DioException) return networkErrorMessage(error);
    final raw = error?.toString().replaceFirst('Exception: ', '').trim() ?? '';
    if (raw.isEmpty ||
        raw.contains('DioException') ||
        raw.contains('StackTrace')) {
      return tr(
        context,
        'Đăng ký thất bại. Vui lòng kiểm tra thông tin và thử lại.',
        'Registration failed. Please check your details and try again.',
      );
    }
    return raw;
  }

  Future<void> _register() async {
    if (_submitting) return;
    if (_formKey.currentState?.validate() != true) return;

    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);
    try {
      final success = await ref
          .read(authProvider.notifier)
          .register(
            _nameController.text.trim(),
            _emailController.text.trim(),
            _passwordController.text,
          );
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr(
                context,
                'Tạo tài khoản thành công. Vui lòng đăng nhập.',
                'Account created. Please sign in.',
              ),
            ),
          ),
        );
        Navigator.pop(context);
        return;
      }
      final msg = _formatError(ref.read(authProvider).error);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final loading = ref.watch(authProvider).isLoading || _submitting;

    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context, 'Tạo tài khoản', 'Create account')),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Form(
              key: _formKey,
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.all(AppDimensions.s24),
                children: [
                  Text(
                    tr(
                      context,
                      'Bắt đầu chia sẻ chi phí cùng nhóm của bạn.',
                      'Start splitting expenses with your group.',
                    ),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.s24),
                  TextFormField(
                    controller: _nameController,
                    enabled: !loading,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.name],
                    decoration: InputDecoration(
                      labelText: tr(context, 'Họ và tên', 'Full name'),
                      hintText: tr(context, 'Nguyễn Văn A', 'Alex Nguyen'),
                      prefixIcon: const Icon(Icons.person_outline_rounded),
                    ),
                    validator: (value) {
                      final name = value?.trim() ?? '';
                      if (name.length < 2) {
                        return tr(
                          context,
                          'Họ tên cần có ít nhất 2 ký tự.',
                          'Name must be at least 2 characters.',
                        );
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppDimensions.s16),
                  TextFormField(
                    controller: _emailController,
                    enabled: !loading,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    autofillHints: const [AutofillHints.email],
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText: 'email@example.com',
                      prefixIcon: Icon(Icons.mail_outline_rounded),
                    ),
                    validator: (value) {
                      final email = value?.trim() ?? '';
                      if (email.isEmpty) {
                        return tr(
                          context,
                          'Vui lòng nhập email.',
                          'Please enter your email.',
                        );
                      }
                      if (!email.contains('@') || !email.contains('.')) {
                        return tr(
                          context,
                          'Email không hợp lệ.',
                          'Invalid email address.',
                        );
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppDimensions.s16),
                  TextFormField(
                    controller: _passwordController,
                    enabled: !loading,
                    obscureText: _obscurePassword,
                    autofillHints: const [AutofillHints.newPassword],
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _register(),
                    decoration: InputDecoration(
                      labelText: tr(context, 'Mật khẩu', 'Password'),
                      hintText: tr(
                        context,
                        'Tối thiểu 6 ký tự',
                        'At least 6 characters',
                      ),
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        tooltip: _obscurePassword
                            ? tr(context, 'Hiện mật khẩu', 'Show password')
                            : tr(context, 'Ẩn mật khẩu', 'Hide password'),
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: scheme.onSurfaceVariant,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.length < 6) {
                        return tr(
                          context,
                          'Mật khẩu phải có ít nhất 6 ký tự.',
                          'Password must be at least 6 characters.',
                        );
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppDimensions.s24),
                  FilledButton(
                    onPressed: loading ? null : _register,
                    child: loading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: scheme.onPrimary,
                            ),
                          )
                        : Text(tr(context, 'Tạo tài khoản', 'Create account')),
                  ),
                  const SizedBox(height: AppDimensions.s16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        tr(
                          context,
                          'Đã có tài khoản?',
                          'Already have an account?',
                        ),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      TextButton(
                        onPressed: loading
                            ? null
                            : () => Navigator.pop(context),
                        child: Text(tr(context, 'Đăng nhập', 'Sign in')),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
