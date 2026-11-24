// Trách nhiệm file: Xây dựng màn hình tạo nhóm mới (CreateGroupDialog) theo chuẩn Apple HIG / iOS Modal Form.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../providers/group_provider.dart';

class CreateGroupDialog extends ConsumerStatefulWidget {
  const CreateGroupDialog({super.key});

  @override
  ConsumerState<CreateGroupDialog> createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends ConsumerState<CreateGroupDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _descriptionController.addListener(_onDescChanged);
  }

  void _onDescChanged() {
    setState(() {});
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final name = _nameController.text.trim();
      final desc = _descriptionController.text.trim();

      await ref.read(userGroupsProvider.notifier).createGroup(name, desc);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tạo nhóm thành công!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _descriptionController.removeListener(_onDescChanged);
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        backgroundColor: AppColors.n100,
        appBar: AppBar(
          backgroundColor: AppColors.n100,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Huỷ',
              style: TextStyle(
                color: AppColors.n600,
                fontSize: 16,
              ),
            ),
          ),
          leadingWidth: 70,
          title: const Text(
            'Tạo nhóm mới',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.n800,
            ),
          ),
          centerTitle: true,
          actions: [
            TextButton(
              onPressed: _isLoading ? null : _submit,
              child: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.p500),
                      ),
                    )
                  : const Text(
                      'Tạo',
                      style: TextStyle(
                        color: AppColors.p500,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            children: [
              // Icon đại diện nhóm phong cách iOS
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.p50,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppDimensions.shadowSm,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.groups_rounded,
                      size: 38,
                      color: AppColors.p500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Section 1: Thông tin nhóm
              const Padding(
                padding: EdgeInsets.only(left: 16, bottom: 8),
                child: Text(
                  'THÔNG TIN NHÓM',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.n600,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.n0,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: AppDimensions.shadowSm,
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: TextFormField(
                        controller: _nameController,
                        style: const TextStyle(fontSize: 16, color: AppColors.n800),
                        decoration: const InputDecoration(
                          hintText: 'Tên nhóm (ví dụ: Chuyến đi Đà Lạt)',
                          hintStyle: TextStyle(color: AppColors.n400, fontSize: 15),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Vui lòng nhập tên nhóm'
                            : v.trim().length > 150
                                ? 'Tên nhóm tối đa 150 ký tự'
                                : null,
                      ),
                    ),
                    const Divider(
                      height: 1,
                      indent: 16,
                      color: AppColors.n200,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: TextFormField(
                        controller: _descriptionController,
                        maxLines: 3,
                        style: const TextStyle(fontSize: 15, color: AppColors.n800),
                        decoration: InputDecoration(
                          hintText: 'Mô tả (không bắt buộc)',
                          hintStyle: const TextStyle(color: AppColors.n400, fontSize: 15),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          counterText:
                              '${_descriptionController.text.trim().runes.length}/500',
                          counterStyle: const TextStyle(fontSize: 11, color: AppColors.n500),
                        ),
                        validator: (val) =>
                            (val != null && val.trim().runes.length > 500)
                                ? 'Mô tả tối đa 500 ký tự'
                                : null,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Section 2: Thành viên ban đầu
              const Padding(
                padding: EdgeInsets.only(left: 16, bottom: 8),
                child: Text(
                  'THÀNH VIÊN BAN ĐẦU',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.n600,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.n0,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: AppDimensions.shadowSm,
                ),
                child: const ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.p50,
                    child: Icon(
                      Icons.person_outline,
                      color: AppColors.p500,
                    ),
                  ),
                  title: Text(
                    'Bạn',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: AppColors.n800,
                    ),
                  ),
                  trailing: Text(
                    'Trưởng nhóm',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.n500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Bạn có thể mời thêm các thành viên khác bằng email sau khi tạo nhóm thành công.',
                  style: TextStyle(fontSize: 13, color: AppColors.n600, height: 1.3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
