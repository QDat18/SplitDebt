// Trách nhiệm file: Xây dựng màn hình register screen và điều phối tương tác người dùng với trạng thái nghiệp vụ.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_theme.dart';
import '../legal/legal_document_screen.dart';
import '../legal/legal_texts.dart';
import 'providers/auth_provider.dart';
import 'register_consent_state.dart';

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
  RegisterConsentState _consentState = const RegisterConsentState();
  late final TapGestureRecognizer _termsTapRecognizer = TapGestureRecognizer()
    ..onTap = () => _openLegalDoc(LegalDocType.terms);
  late final TapGestureRecognizer _privacyTapRecognizer = TapGestureRecognizer()
    ..onTap = () => _openLegalDoc(LegalDocType.privacy);

  void _openLegalDoc(LegalDocType doc) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => LegalDocumentScreen(document: doc)),
    );
  }

  @override
  void dispose() {
    _termsTapRecognizer.dispose();
    _privacyTapRecognizer.dispose();
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
          termsVersion: kTermsVersion,
          privacyVersion: kPrivacyVersion,
          ageConfirmed: _consentState.age,
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
        const SizedBox(height: AppDimensions.s20),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: _consentState.terms,
          onChanged: (v) => setState(
            () => _consentState = _consentState.copyWith(terms: v ?? false),
          ),
          title: Text.rich(
            TextSpan(
              style: Theme.of(context).textTheme.bodyMedium,
              children: [
                const TextSpan(text: 'Tôi đã đọc và đồng ý '),
                TextSpan(
                  text: 'Điều khoản sử dụng',
                  style: const TextStyle(
                    color: AppColors.primary,
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.w600,
                  ),
                  recognizer: _termsTapRecognizer,
                ),
              ],
            ),
          ),
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: _consentState.privacy,
          onChanged: (v) => setState(
            () => _consentState = _consentState.copyWith(privacy: v ?? false),
          ),
          title: Text.rich(
            TextSpan(
              style: Theme.of(context).textTheme.bodyMedium,
              children: [
                const TextSpan(text: 'Tôi đã đọc và đồng ý '),
                TextSpan(
                  text: 'Chính sách quyền riêng tư',
                  style: const TextStyle(
                    color: AppColors.primary,
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.w600,
                  ),
                  recognizer: _privacyTapRecognizer,
                ),
                const TextSpan(
                  text:
                      ' và cho phép xử lý dữ liệu cá nhân theo chính sách này',
                ),
              ],
            ),
          ),
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: _consentState.age,
          onChanged: (v) => setState(
            () => _consentState = _consentState.copyWith(age: v ?? false),
          ),
          title: Text(
            'Tôi xác nhận mình từ đủ 16 tuổi trở lên',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        const SizedBox(height: AppDimensions.s8),
        Text(
          'Dữ liệu được dùng để quản lý nhóm, khoản chi và công nợ của bạn.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 13,
                color: AppColors.n600,
              ),
        ),
      ])),
      bottomNavigationBar: SafeArea(
          child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton(
                        onPressed:
                            (loading || !_consentState.canSubmit) ? null : _register,
                        child: Text(loading ? 'Đang tạo...' : 'Tạo tài khoản')),
                    const SizedBox(height: 12),
                    Wrap(alignment: WrapAlignment.center, crossAxisAlignment: WrapCrossAlignment.center, children: [
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
