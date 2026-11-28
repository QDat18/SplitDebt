// Trách nhiệm file: Màn hình tạo nhóm chi tiêu mới chuẩn Fintech, không dùng emoji, tương thích Light & Dark mode.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/state/app_sync.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/widgets/premium_shell.dart';
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
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isLoading || _formKey.currentState?.validate() != true) return;

    setState(() => _isLoading = true);
    try {
      await ref
          .read(userGroupsProvider.notifier)
          .createGroup(
            _nameController.text.trim(),
            _descriptionController.text.trim(),
          );
      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr(context, 'Đã tạo nhóm mới.', 'Group created.')),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(title: Text(tr(context, 'Tạo nhóm mới', 'New group'))),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Form(
              key: _formKey,
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.all(AppDimensions.s20),
                children: [
                  Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.subtleFillFor(context),
                        borderRadius: AppDimensions.radius16,
                        border: Border.all(
                          color: AppColors.hairlineFor(context),
                        ),
                      ),
                      child: Icon(
                        CupertinoIcons.person_2,
                        size: 30,
                        color: scheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.s24),
                  TextFormField(
                    controller: _nameController,
                    enabled: !_isLoading,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: tr(context, 'Tên nhóm', 'Group name'),
                      hintText: tr(
                        context,
                        'Ví dụ: Chuyến đi Đà Lạt',
                        'e.g. Weekend Trip',
                      ),
                    ),
                    validator: (v) {
                      final name = v?.trim() ?? '';
                      if (name.isEmpty) {
                        return tr(
                          context,
                          'Vui lòng nhập tên nhóm.',
                          'Please enter a group name.',
                        );
                      }
                      if (name.length > 150) {
                        return tr(
                          context,
                          'Tên nhóm tối đa 150 ký tự.',
                          'Maximum 150 characters.',
                        );
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppDimensions.s16),
                  TextFormField(
                    controller: _descriptionController,
                    enabled: !_isLoading,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: tr(
                        context,
                        'Mô tả (không bắt buộc)',
                        'Description (optional)',
                      ),
                      hintText: tr(
                        context,
                        'Ghi chú ngắn về mục đích chi tiêu của nhóm',
                        'Short note about this group',
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.s24),
                  Text(
                    tr(context, 'Thành viên ban đầu', 'Initial member'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppDimensions.s8),
                  PremiumSurface(
                    padding: EdgeInsets.zero,
                    radius: AppDimensions.r12,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: scheme.primary.withValues(alpha: 0.12),
                        child: Icon(
                          Icons.person_outline,
                          color: scheme.primary,
                        ),
                      ),
                      title: Text(
                        tr(context, 'Bạn', 'You'),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(tr(context, 'Trưởng nhóm', 'Owner')),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.s8),
                  Text(
                    tr(
                      context,
                      'Bạn có thể thêm thành viên bằng email ngay sau khi tạo nhóm.',
                      'You can add members by email after creating the group.',
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.s16),
            child: FilledButton(
              onPressed: _isLoading ? null : _submit,
              child: Text(
                _isLoading
                    ? tr(context, 'Đang tạo...', 'Creating...')
                    : tr(context, 'Tạo nhóm', 'Create group'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
