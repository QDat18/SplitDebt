// Trách nhiệm file: Màn hình chặn yêu cầu người dùng đồng ý lại khi điều khoản hoặc chính sách đổi phiên bản.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/widgets/grouped_list.dart';
import '../../main_layout_screen.dart';
import '../auth/login_screen.dart';
import '../privacy/delete_account_flow.dart';
import 'legal_document_screen.dart';
import 'legal_texts.dart';

class ReconsentScreen extends ConsumerStatefulWidget {
  const ReconsentScreen({super.key});

  @override
  ConsumerState<ReconsentScreen> createState() => _ReconsentScreenState();
}

class _ReconsentScreenState extends ConsumerState<ReconsentScreen> {
  bool _termsAccepted = false;
  bool _privacyAccepted = false;
  bool _submitting = false;

  bool get _canSubmit => _termsAccepted && _privacyAccepted && !_submitting;

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() => _submitting = true);
    try {
      await ref.read(authRepositoryProvider).submitReconsent(
            termsVersion: kTermsVersion,
            privacyVersion: kPrivacyVersion,
          );
      DioClient.resetReconsentGuard();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainLayoutScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Future<void> _logout() async {
    await ref.read(authProvider.notifier).logout();
    DioClient.resetReconsentGuard();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _openDocument(LegalDocType doc) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LegalDocumentScreen(document: doc),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.n50,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: AppDimensions.s24),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.s16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chúng tôi đã cập nhật điều khoản',
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.n900,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.s8),
                    Text(
                      kLegalChangeSummary,
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.n600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.s20),
              GroupedSection(
                header: 'VĂN BẢN CẬP NHẬT',
                children: [
                  GroupedTile(
                    icon: Icons.description_outlined,
                    title: 'Điều khoản sử dụng',
                    subtitle: 'Phiên bản $kTermsVersion',
                    onTap: () => _openDocument(LegalDocType.terms),
                  ),
                  GroupedTile(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Chính sách quyền riêng tư',
                    subtitle: 'Phiên bản $kPrivacyVersion',
                    onTap: () => _openDocument(LegalDocType.privacy),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.s16),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.s16,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.n0,
                    borderRadius: AppDimensions.radius12,
                  ),
                  child: Column(
                    children: [
                      CheckboxListTile(
                        value: _termsAccepted,
                        onChanged: (v) =>
                            setState(() => _termsAccepted = v ?? false),
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Text(
                          'Tôi đã đọc và đồng ý Điều khoản sử dụng',
                          style: textTheme.bodyMedium,
                        ),
                      ),
                      const Divider(height: 0.5, color: AppColors.n200),
                      CheckboxListTile(
                        value: _privacyAccepted,
                        onChanged: (v) =>
                            setState(() => _privacyAccepted = v ?? false),
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Text(
                          'Tôi đã đọc và đồng ý Chính sách quyền riêng tư và cho phép xử lý dữ liệu cá nhân theo chính sách này',
                          style: textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.s24),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.s16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton(
                      onPressed: _canSubmit ? _submit : null,
                      child: Text(
                        _submitting
                            ? 'Đang xử lý...'
                            : 'Đồng ý và tiếp tục',
                      ),
                    ),
                    const SizedBox(height: AppDimensions.s12),
                    OutlinedButton(
                      onPressed: _submitting ? null : _logout,
                      child: const Text('Đăng xuất'),
                    ),
                    const SizedBox(height: AppDimensions.s8),
                    TextButton(
                      onPressed: _submitting
                          ? null
                          : () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const DeleteAccountFlowScreen(),
                                ),
                              );
                            },
                      child: Text(
                        'Xoá tài khoản',
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

