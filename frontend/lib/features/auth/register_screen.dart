import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/premium_ui.dart';
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
      final signedIn = await Session.register(
        fullName: name.text,
        email: email.text,
        phone: phone.text,
        password: password.text,
        acceptedTerms: accepted,
      );
      if (!mounted) return;
      if (signedIn) {
        // SessionGate bên dưới tự chuyển sang HomeScreen ngay khi
        // Session.authenticated=true. Chỉ cần đóng route đăng ký.
        Navigator.of(context).pop();
        return;
      }
      // Fallback cho backend cũ chỉ trả id/message, tránh khóa người dùng.
      await showSuccessDialog(
        context,
        title: 'Tạo tài khoản thành công',
        message: 'Tài khoản đã được tạo. Backend hiện tại chưa trả phiên đăng nhập tự động.',
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
                            Row(
                              children: [
                                IconButton(
                                  tooltip: 'Quay lại đăng nhập',
                                  onPressed: busy ? null : () => Navigator.pop(context),
                                  style: IconButton.styleFrom(backgroundColor: Colors.transparent),
                                  icon: const Icon(Icons.arrow_back_rounded),
                                ),
                                const Spacer(),
                              ],
                            ),
                            const Align(
                              alignment: Alignment.center,
                              child: SplitDebtBrandMark(size: 78),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Tạo tài khoản',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 7),
                            Text(
                              'Bắt đầu chia chi phí cùng nhóm của bạn.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 18),
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
                                    child: TextButton(
                                      onPressed: busy ? null : () => Navigator.pop(context),
                                      child: const Text(
                                        'Đăng nhập',
                                        style: TextStyle(color: AppColors.textSecondary),
                                      ),
                                    ),
                                  ),
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
                                      child: const TextButton(
                                        onPressed: null,
                                        child: Text(
                                          'Đăng ký',
                                          style: TextStyle(color: AppColors.textPrimary),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 22),
                            TextFormField(
                              controller: name,
                              maxLength: 100,
                              decoration: const InputDecoration(
                                labelText: 'Họ và tên',
                                prefixIcon: Icon(Icons.person_outline_rounded),
                              ),
                              validator: (v) => v == null || v.trim().length < 2 ? 'Nhập họ tên.' : null,
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: email,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.alternate_email_rounded),
                              ),
                              validator: (v) => v != null && RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())
                                  ? null
                                  : 'Nhập email hợp lệ.',
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: phone,
                              keyboardType: TextInputType.phone,
                              maxLength: 20,
                              decoration: const InputDecoration(
                                labelText: 'Số điện thoại (không bắt buộc)',
                                prefixIcon: Icon(Icons.phone_outlined),
                              ),
                            ),
                            const SizedBox(height: 6),
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
                            const SizedBox(height: 8),
                            Material(
                              color: AppColors.surfaceLow.withValues(alpha: .82),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(color: AppColors.glassBorder),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: CheckboxListTile(
                                value: accepted,
                                controlAffinity: ListTileControlAffinity.leading,
                                onChanged: busy ? null : (v) => setState(() => accepted = v ?? false),
                                title: const Text(
                                  'Tôi đồng ý với Điều khoản dịch vụ và Chính sách bảo mật.',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            BusyButton(busy: busy, label: 'Tạo tài khoản', onPressed: submit),
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
