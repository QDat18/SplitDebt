// Trách nhiệm file: Luồng xoá tài khoản gồm giải thích, nhập mật khẩu, xác nhận và xử lý công nợ còn tồn đọng.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/network/dio_client.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/widgets/grouped_list.dart';
import '../auth/login_screen.dart';
import '../groups/models/group_model.dart';
import '../groups/screens/group_detail_screen.dart';
import 'privacy_repository.dart';

class DeleteAccountFlowScreen extends ConsumerStatefulWidget {
  const DeleteAccountFlowScreen({super.key});

  @override
  ConsumerState<DeleteAccountFlowScreen> createState() =>
      _DeleteAccountFlowScreenState();
}

class _DeleteAccountFlowScreenState
    extends ConsumerState<DeleteAccountFlowScreen> {
  final _passwordController = TextEditingController();
  final _repo = PrivacyRepository();
  bool _obscurePassword = true;
  bool _submitting = false;
  String? _errorMessage;
  List<OutstandingGroup> _outstandingGroups = const [];

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _confirmAndDelete() async {
    final password = _passwordController.text;
    if (password.isEmpty) {
      setState(() => _errorMessage = 'Vui lòng nhập mật khẩu hiện tại.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog.adaptive(
        title: const Text('Xoá tài khoản vĩnh viễn'),
        content: const Text(
          'Hành động này không thể hoàn tác. Thông tin cá nhân của bạn sẽ bị xoá hoặc ẩn danh ngay lập tức.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Huỷ'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Xoá vĩnh viễn',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _submitting = true;
      _errorMessage = null;
      _outstandingGroups = const [];
    });

    try {
      await _repo.deleteAccount(password);
      await ref.read(authProvider.notifier).logout();
      DioClient.resetReconsentGuard();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tài khoản đã được xoá.')),
      );
    } on WrongPasswordError catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.message);
    } on OutstandingBalanceError catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _outstandingGroups = e.groups;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final currencyFmt = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: AppColors.n50,
      appBar: AppBar(
        title: const Text('Xoá tài khoản'),
        backgroundColor: AppColors.n50,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.s16),
        children: [
          GroupedSection(
            header: 'ĐIỀU GÌ SẼ XẢY RA',
            children: [
              Padding(
                padding: const EdgeInsets.all(AppDimensions.s16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dữ liệu bị xoá hoặc ẩn danh ngay:',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.n900,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.s8),
                    Text(
                      'Họ tên, email, số điện thoại, ảnh đại diện, mã thông báo đẩy, cài đặt cá nhân, thông báo và nhật ký hoạt động sẽ bị xoá hoặc ẩn danh. Tin nhắn bạn đã gửi sẽ đổi thành "Tin nhắn đã bị xoá".',
                      style: textTheme.bodyMedium?.copyWith(color: AppColors.n700),
                    ),
                    const SizedBox(height: AppDimensions.s16),
                    Text(
                      'Dữ liệu được giữ lại dưới dạng ẩn danh:',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.n900,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.s8),
                    Text(
                      'Các khoản chi và thanh toán chung trong nhóm vẫn được giữ lại (ẩn danh) để sổ nợ của các thành viên khác không bị sai lệch. Việc xoá tài khoản không thể hoàn tác.',
                      style: textTheme.bodyMedium?.copyWith(color: AppColors.n700),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.s20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Nhập mật khẩu để xác nhận',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.n900,
                  ),
                ),
                const SizedBox(height: AppDimensions.s8),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Mật khẩu hiện tại',
                    filled: true,
                    fillColor: AppColors.n0,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: AppDimensions.s12),
                  Text(
                    _errorMessage!,
                    style: textTheme.bodyMedium?.copyWith(color: AppColors.error),
                  ),
                ],
                const SizedBox(height: AppDimensions.s16),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.error,
                  ),
                  onPressed: _submitting ? null : _confirmAndDelete,
                  child: Text(_submitting ? 'Đang xoá...' : 'Xoá tài khoản'),
                ),
              ],
            ),
          ),
          if (_outstandingGroups.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.s20),
            GroupedSection(
              header: 'NHÓM CÒN CÔNG NỢ',
              footer: 'Hãy thanh toán hết công nợ trong các nhóm trên trước khi xoá tài khoản.',
              children: [
                for (final g in _outstandingGroups)
                  GroupedTile(
                    icon: Icons.group_outlined,
                    title: g.name,
                    value: currencyFmt.format(g.balance),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => GroupDetailScreen(
                          group: GroupModel(
                            id: g.id.toString(),
                            name: g.name,
                            currentUserRole: 'MEMBER',
                            memberCount: 1,
                            userBalance: g.balance,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

