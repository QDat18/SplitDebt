// Trách nhiệm file: Hộp thoại thêm thành viên vào nhóm bằng email, có dispose controller và hỗ trợ Dark Mode.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/state/app_sync.dart';
import '../../../core/theme/app_dimensions.dart';
import '../providers/group_provider.dart';

class AddMemberDialog extends ConsumerStatefulWidget {
  final String groupId;

  const AddMemberDialog({super.key, required this.groupId});

  @override
  ConsumerState<AddMemberDialog> createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends ConsumerState<AddMemberDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  String _selectedRole = 'MEMBER';
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isLoading || _formKey.currentState?.validate() != true) return;

    setState(() => _isLoading = true);
    try {
      await ref
          .read(userGroupsProvider.notifier)
          .addMember(
            widget.groupId,
            _emailController.text.trim(),
            role: _selectedRole,
          );
      ref.invalidate(groupMembersProvider(widget.groupId));
      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr(
                context,
                'Đã thêm thành viên vào nhóm.',
                'Member added to group.',
              ),
            ),
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
    return AlertDialog(
      title: Text(tr(context, 'Thêm thành viên', 'Add member')),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _emailController,
                enabled: !_isLoading,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: tr(context, 'Email thành viên', 'Member email'),
                  hintText: 'email@example.com',
                  prefixIcon: const Icon(Icons.mail_outline_rounded),
                ),
                validator: (val) {
                  final email = val?.trim() ?? '';
                  if (email.isEmpty) {
                    return tr(
                      context,
                      'Vui lòng nhập email.',
                      'Enter an email.',
                    );
                  }
                  if (!email.contains('@') || !email.contains('.')) {
                    return tr(context, 'Email không hợp lệ.', 'Invalid email.');
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppDimensions.s16),
              DropdownButtonFormField<String>(
                initialValue: _selectedRole,
                decoration: InputDecoration(
                  labelText: tr(context, 'Vai trò', 'Role'),
                  prefixIcon: const Icon(Icons.admin_panel_settings_outlined),
                ),
                items: [
                  DropdownMenuItem(
                    value: 'MEMBER',
                    child: Text(tr(context, 'Thành viên', 'Member')),
                  ),
                  DropdownMenuItem(
                    value: 'ADMIN',
                    child: Text(tr(context, 'Quản trị viên', 'Admin')),
                  ),
                ],
                onChanged: _isLoading
                    ? null
                    : (val) {
                        if (val != null) setState(() => _selectedRole = val);
                      },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: Text(tr(context, 'Hủy', 'Cancel')),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: scheme.onPrimary,
                    strokeWidth: 2,
                  ),
                )
              : Text(tr(context, 'Thêm', 'Add')),
        ),
      ],
    );
  }
}
