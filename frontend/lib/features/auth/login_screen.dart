// Trách nhiệm file: Màn hình đăng nhập tập trung vào biểu mẫu, validation trực tiếp, thông báo lỗi thân thiện, không có nút giả lập.

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/network_error.dart';
import '../../core/state/app_sync.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/widgets/motion_kit.dart';
import '../../core/widgets/premium_shell.dart';
import '../../main_layout_screen.dart';
import 'providers/auth_provider.dart';
import 'register_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _submitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _formatAuthError(Object? error) {
    if (error is DioException) return networkErrorMessage(error);
    final raw = error?.toString().replaceFirst('Exception: ', '').trim() ?? '';
    if (raw.isEmpty ||
        raw.contains('DioException') ||
        raw.contains('StackTrace') ||
        raw.contains('SocketException')) {
      return tr(
        context,
        'Không thể đăng nhập. Kiểm tra email, mật khẩu và kết nối mạng.',
        'Sign in failed. Please check your credentials and connection.',
      );
    }
    return raw;
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (_formKey.currentState?.validate() != true) return;

    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      final success = await ref
          .read(authProvider.notifier)
          .login(email, password);
      if (!mounted) return;
      if (success) {
        Navigator.of(
          context,
        ).pushReplacement(fintechRoute(const MainLayoutScreen()));
      } else {
        final msg = _formatAuthError(ref.read(authProvider).error);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final authLoading = ref.watch(authProvider).isLoading || _submitting;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.s24,
                vertical: AppDimensions.s24,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppDimensions.s16),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: SplitDebtMark(size: 52),
                    ),
                    const SizedBox(height: AppDimensions.s24),
                    Text(
                      tr(context, 'Đăng nhập', 'Sign in'),
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: AppDimensions.s8),
                    Text(
                      tr(
                        context,
                        'Quản lý chi tiêu nhóm và theo dõi công nợ rõ ràng.',
                        'Track shared expenses and settle group balances.',
                      ),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.s32),
                    TextFormField(
                      controller: _emailController,
                      enabled: !authLoading,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      autofillHints: const [AutofillHints.email],
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        hintText: 'email@example.com',
                        prefixIcon: const Icon(Icons.mail_outline_rounded),
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
                            'Định dạng email chưa hợp lệ.',
                            'Please enter a valid email address.',
                          );
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppDimensions.s16),
                    TextFormField(
                      controller: _passwordController,
                      enabled: !authLoading,
                      obscureText: _obscurePassword,
                      autofillHints: const [AutofillHints.password],
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        labelText: tr(context, 'Mật khẩu', 'Password'),
                        hintText: tr(
                          context,
                          'Nhập mật khẩu',
                          'Enter password',
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
                        if (value == null || value.isEmpty) {
                          return tr(
                            context,
                            'Vui lòng nhập mật khẩu.',
                            'Please enter your password.',
                          );
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppDimensions.s24),
                    FilledButton(
                      onPressed: authLoading ? null : _submit,
                      child: authLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: scheme.onPrimary,
                              ),
                            )
                          : Text(tr(context, 'Đăng nhập', 'Sign in')),
                    ),
                    const SizedBox(height: AppDimensions.s24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          tr(context, 'Chưa có tài khoản?', 'No account yet?'),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                        TextButton(
                          onPressed: authLoading
                              ? null
                              : () => Navigator.push(
                                  context,
                                  fintechRoute(const RegisterScreen()),
                                ),
                          child: Text(tr(context, 'Đăng ký', 'Create account')),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
