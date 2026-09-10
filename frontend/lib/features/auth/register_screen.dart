import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/api.dart';
import '../../widgets/design.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController();
  final email = TextEditingController();
  final phone = TextEditingController();
  final password = TextEditingController();
  bool accepted = false;
  bool busy = false;
  bool hidden = true;

  @override void dispose() {
    name.dispose(); email.dispose(); phone.dispose(); password.dispose(); super.dispose();
  }

  Future<void> submit() async {
    if (!form.currentState!.validate()) return;
    if (!accepted) { showError(context, 'Bạn cần đồng ý Điều khoản dịch vụ và Chính sách bảo mật.'); return; }
    setState(() => busy = true);
    try {
      await Session.register(
        fullName: name.text,
        email: email.text,
        phone: phone.text,
        password: password.text,
        acceptedTerms: accepted,
      );
      if (!mounted) return;
      await showSuccessDialog(
        context,
        title: 'Tạo tài khoản thành công',
        message: 'Tài khoản của bạn đã sẵn sàng. Hãy đăng nhập để bắt đầu tạo nhóm và chia chi tiêu.',
        actionLabel: 'Đăng nhập ngay',
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Tạo tài khoản')),
    body: SafeArea(
      top: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 18, 28, 34),
            child: Form(
              key: form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 66,
                    height: 66,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Icon(Icons.person_add_alt_1_rounded, color: AppColors.primary, size: 30),
                  ),
                  const SizedBox(height: 22),
                  Text('Tạo tài khoản SplitDebt', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text('Chỉ mất một phút để bắt đầu chia chi phí rõ ràng hơn.', style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 28),
                  TextFormField(
                    controller: name,
                    maxLength: 100,
                    decoration: const InputDecoration(labelText: 'Họ và tên', prefixIcon: Icon(Icons.person_outline_rounded)),
                    validator: (v) => v == null || v.trim().length < 2 ? 'Nhập họ tên.' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.alternate_email_rounded)),
                    validator: (v) => v != null && RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())
                        ? null : 'Nhập email hợp lệ.',
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: phone,
                    keyboardType: TextInputType.phone,
                    maxLength: 20,
                    decoration: const InputDecoration(labelText: 'Số điện thoại (không bắt buộc)', prefixIcon: Icon(Icons.phone_outlined)),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: password,
                    obscureText: hidden,
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu',
                      helperText: 'Tối thiểu 8 ký tự.',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => hidden = !hidden),
                        icon: Icon(hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      ),
                    ),
                    validator: (v) => v != null && v.length >= 8 ? null : 'Mật khẩu cần ít nhất 8 ký tự.',
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: CheckboxListTile(
                      value: accepted,
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: busy ? null : (v) => setState(() => accepted = v ?? false),
                      title: const Text('Tôi đồng ý với Điều khoản dịch vụ và Chính sách bảo mật.'),
                    ),
                  ),
                  const SizedBox(height: 22),
                  BusyButton(busy: busy, label: 'Tạo tài khoản', onPressed: submit),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
