// Trách nhiệm file: Màn hình cài đặt nhóm chuẩn hóa, không dùng emoji, tương thích Light & Dark mode.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/state/app_sync.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../models/group_model.dart';
import '../providers/group_provider.dart';

class GroupSettingsScreen extends ConsumerStatefulWidget {
  final GroupModel group;

  const GroupSettingsScreen({super.key, required this.group});

  @override
  ConsumerState<GroupSettingsScreen> createState() =>
      _GroupSettingsScreenState();
}

class _GroupSettingsScreenState extends ConsumerState<GroupSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.group.name);
    _descController = TextEditingController(
      text: widget.group.description ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (_isSaving || _formKey.currentState?.validate() != true) return;
    setState(() => _isSaving = true);
    try {
      await ref
          .read(userGroupsProvider.notifier)
          .updateGroup(
            widget.group.id,
            _nameController.text.trim(),
            _descController.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr(
                context,
                'Đã cập nhật thông tin nhóm.',
                'Group information updated.',
              ),
            ),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteGroup() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr(ctx, 'Xác nhận xóa nhóm', 'Delete group')),
        content: Text(
          tr(
            ctx,
            'Bạn có chắc chắn muốn xóa nhóm này? Hành động này không thể hoàn tác.',
            'Are you sure you want to delete this group? This action cannot be undone.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr(ctx, 'Hủy', 'Cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.errorFor(ctx),
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr(ctx, 'Xóa nhóm', 'Delete')),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    try {
      await ref.read(userGroupsProvider.notifier).deleteGroup(widget.group.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr(context, 'Đã xóa nhóm.', 'Group deleted.')),
          ),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final errorColor = AppColors.errorFor(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context, 'Cài đặt nhóm', 'Group settings')),
        actions: [
          if (widget.group.isAdminOrOwner)
            TextButton(
              onPressed: _isSaving ? null : _saveChanges,
              child: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(tr(context, 'Lưu', 'Save')),
            ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.s20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    tr(context, 'Thông tin chung', 'General'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppDimensions.s12),
                  TextFormField(
                    controller: _nameController,
                    enabled: widget.group.isAdminOrOwner && !_isSaving,
                    decoration: InputDecoration(
                      labelText: tr(context, 'Tên nhóm', 'Group name'),
                      prefixIcon: const Icon(Icons.drive_file_rename_outline),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty
                        ? tr(
                            context,
                            'Tên nhóm không được để trống.',
                            'Group name is required.',
                          )
                        : null,
                  ),
                  const SizedBox(height: AppDimensions.s16),
                  TextFormField(
                    controller: _descController,
                    enabled: widget.group.isAdminOrOwner && !_isSaving,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: tr(context, 'Mô tả', 'Description'),
                      prefixIcon: const Icon(Icons.description_outlined),
                    ),
                  ),
                  if (widget.group.isAdminOrOwner) ...[
                    const SizedBox(height: AppDimensions.s32),
                    const Divider(),
                    const SizedBox(height: AppDimensions.s16),
                    Text(
                      tr(context, 'Vùng nguy hiểm', 'Danger zone'),
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(color: errorColor),
                    ),
                    const SizedBox(height: AppDimensions.s12),
                    OutlinedButton.icon(
                      onPressed: _isSaving ? null : _deleteGroup,
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        color: errorColor,
                      ),
                      label: Text(
                        tr(context, 'Xóa nhóm này', 'Delete this group'),
                        style: TextStyle(color: errorColor),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: errorColor),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
