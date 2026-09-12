import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/navigation/smooth_page_route.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/premium_ui.dart';
import '../../data/api.dart';
import '../../widgets/design.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final form = GlobalKey<FormState>();
  final email = TextEditingController();
  final password = TextEditingController();
  bool busy = false;
  bool googleBusy = false;
  bool hidden = true;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!form.currentState!.validate()) return;
    setState(() => busy = true);
    try {
      await Session.signIn(email.text, password.text);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> googleSignIn() async {
    if (busy || googleBusy) return;
    setState(() => googleBusy = true);
    try {
      final completed = await Session.signInWithGoogle();
      if (!completed && mounted) {
        showInfo(context, 'Bạn đã đóng hoặc hủy cửa sổ đăng nhập Google.', title: 'Đăng nhập đã hủy');
      }
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => googleBusy = false);
    }
  }

  Future<void> openForgotPassword() async {
    if (busy || googleBusy) return;
    final recoveredEmail = await Navigator.push<String>(
      context,
      SmoothPageRoute<String>(
        builder: (_) => ForgotPasswordScreen(initialEmail: email.text),
      ),
    );
    if (!mounted || recoveredEmail == null || recoveredEmail.isEmpty) return;
    email.text = recoveredEmail;
    password.clear();
    showSuccess(context, 'Hãy đăng nhập bằng mật khẩu mới.', title: 'Sẵn sàng đăng nhập');
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
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                  child: Entrance(
                    child: GlassSurface(
                      padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
                      child: Form(
                        key: form,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Align(
                              alignment: Alignment.center,
                              child: SplitDebtBrandMark(size: 82),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              'Chào mừng trở lại',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 7),
                            Text(
                              'Quản lý chi tiêu nhóm và công nợ rõ ràng hơn.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceHigh,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: AppColors.glassBorder),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.surface,
                                        borderRadius: BorderRadius.circular(999),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: .28),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: TextButton(
                                        onPressed: null,
                                        child: const Text(
                                          'Đăng nhập',
                                          style: TextStyle(color: AppColors.textPrimary),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: TextButton(
                                      onPressed: busy || googleBusy
                                          ? null
                                          : () => Navigator.push(
                                                context,
                                                SmoothPageRoute<void>(builder: (_) => const RegisterScreen()),
                                              ),
                                      child: const Text(
                                        'Đăng ký',
                                        style: TextStyle(color: AppColors.textSecondary),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 22),
                            TextFormField(
                              controller: email,
                              keyboardType: TextInputType.emailAddress,
                              autofillHints: const [AutofillHints.email],
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                hintText: 'you@example.com',
                                prefixIcon: Icon(Icons.alternate_email_rounded),
                              ),
                              validator: (value) => value != null &&
                                      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim())
                                  ? null
                                  : 'Nhập email hợp lệ.',
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: password,
                              obscureText: hidden,
                              autofillHints: const [AutofillHints.password],
                              decoration: InputDecoration(
                                labelText: 'Mật khẩu',
                                prefixIcon: const Icon(Icons.lock_outline_rounded),
                                suffixIcon: IconButton(
                                  onPressed: () => setState(() => hidden = !hidden),
                                  icon: Icon(hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                                ),
                              ),
                              validator: (value) => value != null && value.isNotEmpty ? null : 'Nhập mật khẩu.',
                              onFieldSubmitted: (_) {
                                if (!busy && !googleBusy) submit();
                              },
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: openForgotPassword,
                                style: TextButton.styleFrom(foregroundColor: AppColors.tertiary),
                                child: const Text('Quên mật khẩu?'),
                              ),
                            ),
                            const SizedBox(height: 8),
                            BusyButton(busy: busy, label: 'Đăng nhập', onPressed: submit),
                            const SizedBox(height: 22),
                            Row(
                              children: [
                                Expanded(child: Divider(color: Theme.of(context).dividerColor)),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 12),
                                  child: Text('HOẶC TIẾP TỤC VỚI', style: TextStyle(fontFamily: 'Geist', fontSize: 9, color: AppColors.textSecondary, letterSpacing: .6)),
                                ),
                                Expanded(child: Divider(color: Theme.of(context).dividerColor)),
                              ],
                            ),
                            const SizedBox(height: 18),
                            _GoogleButton(
                              busy: googleBusy,
                              configured: AppConstants.googleSignInConfigured,
                              onPressed: googleSignIn,
                            ),
                            const SizedBox(height: 12),
                            AnimatedOpacity(
                              opacity: AppConstants.googleSignInConfigured ? 0 : 1,
                              duration: const Duration(milliseconds: 220),
                              child: AppConstants.googleSignInConfigured
                                  ? const SizedBox.shrink()
                                  : Text(
                                      'Google Sign-In sẽ hoạt động sau khi cấu hình GOOGLE_WEB_CLIENT_ID.',
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                            ),
                            const SizedBox(height: 4),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

class _GoogleButton extends StatefulWidget {
  const _GoogleButton({
    required this.busy,
    required this.configured,
    required this.onPressed,
  });

  final bool busy;
  final bool configured;
  final VoidCallback onPressed;

  @override
  State<_GoogleButton> createState() => _GoogleButtonState();
}

class _GoogleButtonState extends State<_GoogleButton> {
  bool hovered = false;
  bool pressed = false;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return MouseRegion(
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      child: Listener(
        onPointerDown: (_) => setState(() => pressed = true),
        onPointerUp: (_) => setState(() => pressed = false),
        onPointerCancel: (_) => setState(() => pressed = false),
        child: AnimatedScale(
          scale: pressed ? .985 : hovered && !reduceMotion ? 1.008 : 1,
          duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 120),
          child: AnimatedContainer(
            duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 180),
            transform: Matrix4.translationValues(0, hovered && !reduceMotion ? -1 : 0, 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: hovered
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .28),
                        blurRadius: 18,
                        offset: const Offset(0, 7),
                      ),
                    ]
                  : const [],
            ),
            child: OutlinedButton(
              onPressed: widget.busy ? null : widget.onPressed,
              child: SizedBox(
                height: 28,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.busy)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      Container(
                        width: 26,
                        height: 26,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: const Text(
                          'G',
                          style: TextStyle(
                            color: Color(0xFF4285F4),
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    const SizedBox(width: 11),
                    Text(widget.busy ? 'Đang kết nối Google...' : 'Tiếp tục với Google'),
                    if (!widget.configured && !widget.busy) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.settings_outlined, size: 16),
                    ],
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
