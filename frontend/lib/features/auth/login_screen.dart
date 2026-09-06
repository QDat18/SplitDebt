import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_typography.dart';
import '../expenses/create_expense_screen.dart';
import 'register_screen.dart';

/// MÀN HÌNH ĐĂNG NHẬP (CÓ CHẾ ĐỘ BYPASS / DEMO TRẢI NGHIỆM GIAO DIỆN)
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  // Đăng nhập thật qua Supabase Auth
  Future<void> _signIn() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      // Nếu bỏ trống, hỗ trợ tự động dùng tài khoản Demo luôn
      _bypassAuthDemo();
      return;
    }

    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      _navigateToHome();
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Chức năng Bypass Đăng nhập (Chế độ Dùng thử / Dev Demo)
  void _bypassAuthDemo() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.bolt_rounded, color: Colors.amber, size: 20),
            SizedBox(width: AppDimensions.s8),
            Text('Đã kích hoạt Chế độ Dev Demo (Bỏ qua Đăng nhập)!'),
          ],
        ),
        backgroundColor: AppColors.p700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppDimensions.radius12),
      ),
    );
    _navigateToHome();
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const CreateExpenseScreen()),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.n50,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(AppDimensions.s24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppDimensions.s32),

              // LOGO ICON THƯƠNG HIỆU
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.all(AppDimensions.s16),
                  decoration: BoxDecoration(
                    color: AppColors.p50,
                    borderRadius: AppDimensions.radius20,
                    border: Border.all(color: AppColors.p200),
                  ),
                  child: const Icon(Icons.call_split_rounded, size: 36, color: AppColors.p500),
                ),
              ),

              const SizedBox(height: AppDimensions.s24),
              Text('Chào mừng trở lại!', style: AppTypography.h1.copyWith(fontSize: 26)),
              const SizedBox(height: AppDimensions.s8),
              Text('Đăng nhập để quản lý chi tiêu nhóm & chốt sổ sòng phẳng', style: AppTypography.bodyMedium),

              const SizedBox(height: AppDimensions.s32),

              // Ô NHẬP EMAIL & MẬT KHẨU
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'nguyenvandat@gmail.com',
                  prefixIcon: const Icon(Icons.email_outlined, color: AppColors.p500),
                  border: OutlineInputBorder(borderRadius: AppDimensions.radius16),
                ),
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: AppDimensions.s16),

              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu',
                  prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.p500),
                  border: OutlineInputBorder(borderRadius: AppDimensions.radius16),
                ),
                obscureText: true,
              ),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: Text('Quên mật khẩu?', style: AppTypography.label.copyWith(color: AppColors.p600)),
                ),
              ),

              const SizedBox(height: AppDimensions.s16),

              // NÚT ĐĂNG NHẬP CHÍNH THỨC
              ElevatedButton(
                onPressed: _isLoading ? null : _signIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.p500,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(borderRadius: AppDimensions.radius16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : Text('ĐĂNG NHẬP', style: AppTypography.title.copyWith(color: Colors.white, fontSize: 16)),
              ),

              const SizedBox(height: AppDimensions.s16),

              // 🚀 NÚT DÙNG THỬ KHÔNG CẦN ĐĂNG NHẬP (BYPASS / DEMO MODE)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.p50, AppColors.p100],
                  ),
                  borderRadius: AppDimensions.radius16,
                  border: Border.all(color: AppColors.p300),
                ),
                child: InkWell(
                  onTap: _bypassAuthDemo,
                  borderRadius: AppDimensions.radius16,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.rocket_launch_rounded, color: AppColors.p700, size: 20),
                        const SizedBox(width: AppDimensions.s8),
                        Text(
                          'Vào Thẳng App (Bỏ qua Đăng Nhập / Demo)',
                          style: AppTypography.label.copyWith(color: AppColors.p700, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppDimensions.s24),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Chưa có tài khoản? ', style: AppTypography.bodyMedium),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                    child: Text('Đăng ký ngay', style: AppTypography.label.copyWith(color: AppColors.p600)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}