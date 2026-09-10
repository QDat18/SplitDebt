import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/api.dart';
import '../../widgets/design.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final form = GlobalKey<FormState>();
  final email = TextEditingController();
  final password = TextEditingController();
  bool busy = false;
  bool hidden = true;

  @override void dispose() { email.dispose(); password.dispose(); super.dispose(); }

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

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 34, 28, 34),
            child: Form(
              key: form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(Icons.content_cut_rounded, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text('Chào mừng trở lại', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  Text(
                    'Đăng nhập để tiếp tục quản lý chi tiêu nhóm của bạn.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 34),
                  TextFormField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText: 'you@example.com',
                      prefixIcon: Icon(Icons.alternate_email_rounded),
                    ),
                    validator: (v) => v != null && RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())
                        ? null : 'Nhập email hợp lệ.',
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
                    validator: (v) => v != null && v.isNotEmpty ? null : 'Nhập mật khẩu.',
                    onFieldSubmitted: (_) { if (!busy) submit(); },
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(onPressed: null, child: const Text('Quên mật khẩu?')),
                  ),
                  const SizedBox(height: 12),
                  BusyButton(busy: busy, label: 'Đăng nhập', onPressed: submit),
                  const SizedBox(height: 22),
                  Row(children: [
                    Expanded(child: Divider(color: Theme.of(context).dividerColor)),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('hoặc'),
                    ),
                    Expanded(child: Divider(color: Theme.of(context).dividerColor)),
                  ]),
                  const SizedBox(height: 18),
                  OutlinedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
                    label: const Text('Tiếp tục với Google'),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Chưa có tài khoản?'),
                      TextButton(
                        onPressed: busy ? null : () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const RegisterScreen()),
                        ),
                        child: const Text('Đăng ký'),
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
