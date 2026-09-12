import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/premium_ui.dart';
import '../../data/api.dart';
import '../../widgets/design.dart';

enum _ForgotStep { request, reset, success }

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialEmail = ''});

  final String initialEmail;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final requestForm = GlobalKey<FormState>();
  final resetForm = GlobalKey<FormState>();
  late final TextEditingController email;
  final code = TextEditingController();
  final password = TextEditingController();
  final confirmPassword = TextEditingController();

  _ForgotStep step = _ForgotStep.request;
  bool busy = false;
  bool hidden = true;
  bool hiddenConfirm = true;
  String? devCode;
  int expiresInMinutes = 10;

  @override
  void initState() {
    super.initState();
    email = TextEditingController(text: widget.initialEmail.trim());
  }

  @override
  void dispose() {
    email.dispose();
    code.dispose();
    password.dispose();
    confirmPassword.dispose();
    super.dispose();
  }

  bool _validEmail(String? value) => value != null &&
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim());

  Future<void> requestCode() async {
    if (!requestForm.currentState!.validate()) return;
    setState(() => busy = true);
    try {
      final result = await Session.requestPasswordReset(email.text);
      if (!mounted) return;
      devCode = result['devCode']?.toString();
      expiresInMinutes = asInt(result['expiresInMinutes'] ?? 10);
      if (devCode != null && devCode!.isNotEmpty) code.text = devCode!;
      setState(() => step = _ForgotStep.reset);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> resend() async {
    if (busy) return;
    setState(() => busy = true);
    try {
      final result = await Session.requestPasswordReset(email.text);
      if (!mounted) return;
      devCode = result['devCode']?.toString();
      expiresInMinutes = asInt(result['expiresInMinutes'] ?? 10);
      if (devCode != null && devCode!.isNotEmpty) code.text = devCode!;
      showSuccess(context, 'Mã xác minh mới đã được tạo.', title: 'Đã gửi lại mã');
      setState(() {});
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> resetPassword() async {
    if (!resetForm.currentState!.validate()) return;
    setState(() => busy = true);
    try {
      await Session.resetPassword(
        email: email.text,
        code: code.text,
        newPassword: password.text,
      );
      if (!mounted) return;
      setState(() => step = _ForgotStep.success);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.transparent,
        body: PremiumBackground(
          animate: true,
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 18, 24, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton.filledTonal(
                          tooltip: 'Quay lại',
                          onPressed: busy ? null : () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                      ),
                      const SizedBox(height: 18),
                      AnimatedSwitcher(
                        duration: MediaQuery.disableAnimationsOf(context)
                            ? Duration.zero
                            : const Duration(milliseconds: 320),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, animation) {
                          final slide = Tween<Offset>(
                            begin: const Offset(.06, .02),
                            end: Offset.zero,
                          ).animate(animation);
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(position: slide, child: child),
                          );
                        },
                        child: switch (step) {
                          _ForgotStep.request => _requestCard(context),
                          _ForgotStep.reset => _resetCard(context),
                          _ForgotStep.success => _successCard(context),
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

  Widget _requestCard(BuildContext context) => GlassSurface(
        key: const ValueKey('forgot-request'),
        padding: const EdgeInsets.all(26),
        child: Form(
          key: requestForm,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: SplitDebtBrandMark(size: 62),
              ),
              const SizedBox(height: 26),
              Text('Quên mật khẩu?', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(
                'Nhập email đã đăng ký. SplitDebt sẽ gửi mã xác minh để bạn tạo mật khẩu mới.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 26),
              TextFormField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'you@example.com',
                  prefixIcon: Icon(Icons.alternate_email_rounded),
                ),
                validator: (value) => _validEmail(value) ? null : 'Nhập email hợp lệ.',
                onFieldSubmitted: (_) {
                  if (!busy) requestCode();
                },
              ),
              const SizedBox(height: 22),
              BusyButton(busy: busy, label: 'Gửi mã xác minh', onPressed: requestCode),
              const SizedBox(height: 14),
              Text(
                'Vì lý do bảo mật, SplitDebt luôn trả về cùng một thông báo dù email có tồn tại hay không.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      );

  Widget _resetCard(BuildContext context) => GlassSurface(
        key: const ValueKey('forgot-reset'),
        padding: const EdgeInsets.all(26),
        child: Form(
          key: resetForm,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.mark_email_read_rounded, color: AppColors.success),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Kiểm tra mã xác minh', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 3),
                        Text(email.text.trim(), style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Nhập mã 6 chữ số. Mã hết hạn sau $expiresInMinutes phút.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (devCode != null && devCode!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: .10),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.warning.withValues(alpha: .25)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.developer_mode_rounded, color: AppColors.warning),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'DEV mode: mã đã được điền tự động. Tắt PASSWORD_RESET_DEV_RETURN_CODE khi deploy.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 22),
              TextFormField(
                controller: code,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 10),
                decoration: const InputDecoration(
                  labelText: 'Mã xác minh',
                  hintText: '000000',
                  counterText: '',
                  prefixIcon: Icon(Icons.password_rounded),
                ),
                validator: (value) => value != null && RegExp(r'^\d{6}$').hasMatch(value.trim())
                    ? null
                    : 'Mã xác minh gồm 6 chữ số.',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: password,
                obscureText: hidden,
                autofillHints: const [AutofillHints.newPassword],
                decoration: InputDecoration(
                  labelText: 'Mật khẩu mới',
                  helperText: 'Tối thiểu 8 ký tự.',
                  prefixIcon: const Icon(Icons.lock_reset_rounded),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => hidden = !hidden),
                    icon: Icon(hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  ),
                ),
                validator: (value) => value != null && value.length >= 8
                    ? null
                    : 'Mật khẩu cần ít nhất 8 ký tự.',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: confirmPassword,
                obscureText: hiddenConfirm,
                decoration: InputDecoration(
                  labelText: 'Nhập lại mật khẩu',
                  prefixIcon: const Icon(Icons.verified_user_outlined),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => hiddenConfirm = !hiddenConfirm),
                    icon: Icon(hiddenConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  ),
                ),
                validator: (value) => value == password.text ? null : 'Mật khẩu nhập lại chưa khớp.',
                onFieldSubmitted: (_) {
                  if (!busy) resetPassword();
                },
              ),
              const SizedBox(height: 22),
              BusyButton(busy: busy, label: 'Đặt mật khẩu mới', onPressed: resetPassword),
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: busy ? null : resend,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Gửi lại mã'),
              ),
            ],
          ),
        ),
      );

  Widget _successCard(BuildContext context) => GlassSurface(
        key: const ValueKey('forgot-success'),
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: .55, end: 1),
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 520),
              curve: Curves.easeOutBack,
              builder: (context, value, child) => Transform.scale(scale: value, child: child),
              child: Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: .12),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.success.withValues(alpha: .20),
                      blurRadius: 34,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: const Icon(Icons.check_rounded, size: 48, color: AppColors.success),
              ),
            ),
            const SizedBox(height: 24),
            Text('Đổi mật khẩu thành công', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 10),
            Text(
              'Mật khẩu mới đã được lưu. Bạn có thể quay lại và đăng nhập ngay.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 26),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Navigator.pop(context, email.text.trim()),
                icon: const Icon(Icons.login_rounded),
                label: const Text('Quay lại đăng nhập'),
              ),
            ),
          ],
        ),
      );
}
