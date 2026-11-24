// Trách nhiệm file: Xây dựng màn hình cài đặt nhóm theo chuẩn HIG với grouped list.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/widgets/grouped_list.dart';
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
  late TextEditingController _nameController;
  late TextEditingController _descController;
  bool _isSaving = false;

  bool get _isDirty =>
      _nameController.text.trim() != widget.group.name.trim() ||
      _descController.text.trim() != (widget.group.description ?? '').trim();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.group.name);
    _descController = TextEditingController(
      text: widget.group.description ?? '',
    );
    _nameController.addListener(_onTextChanged);
    _descController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _nameController.removeListener(_onTextChanged);
    _descController.removeListener(_onTextChanged);
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await ref.read(userGroupsProvider.notifier).updateGroup(
            widget.group.id,
            _nameController.text.trim(),
            _descController.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã lưu thay đổi.'),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Không lưu được: ${e.toString().replaceAll('Exception: ', '')}',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteGroup() async {
    final confirm = await showAdaptiveDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog.adaptive(
        title: const Text('Xoá nhóm này?'),
        content: const Text(
          'Toàn bộ khoản chi và lịch sử của nhóm sẽ bị xoá. Không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Huỷ'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Xoá',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref
            .read(userGroupsProvider.notifier)
            .deleteGroup(widget.group.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã xoá nhóm.'),
            ),
          );
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Không xoá được: ${e.toString().replaceAll('Exception: ', '')}',
              ),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAdminOrOwner = widget.group.isAdminOrOwner;

    return Scaffold(
      backgroundColor: AppColors.n100,
      appBar: AppBar(
        title: const Text('Cài đặt nhóm'),
        backgroundColor: AppColors.n100,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          if (isAdminOrOwner)
            TextButton(
              onPressed: (!_isDirty || _isSaving) ? null : _saveChanges,
              child: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                    )
                  : const Text(
                      'Lưu',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: AppDimensions.s24),
          children: [
            GroupedSection(
              header: 'Thông tin nhóm',
              footer: isAdminOrOwner
                  ? null
                  : 'Chỉ trưởng nhóm hoặc quản trị viên mới sửa được.',
              children: [
                if (isAdminOrOwner) ...[
                  GroupedTile(
                    title: 'Tên',
                    trailing: Expanded(
                      child: TextFormField(
                        controller: _nameController,
                        textAlign: TextAlign.end,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: AppColors.n800,
                        ),
                        decoration: InputDecoration.collapsed(
                          hintText: 'Bắt buộc',
                          hintStyle: theme.textTheme.bodyLarge?.copyWith(
                            color: AppColors.n400,
                          ),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty
                            ? 'Tên nhóm không được để trống'
                            : null,
                      ),
                    ),
                  ),
                  GroupedTile(
                    title: 'Mô tả',
                    trailing: Expanded(
                      child: TextFormField(
                        controller: _descController,
                        textAlign: TextAlign.end,
                        minLines: 1,
                        maxLines: 4,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: AppColors.n800,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          hintText: 'Không bắt buộc',
                          hintStyle: theme.textTheme.bodyLarge?.copyWith(
                            color: AppColors.n400,
                          ),
                          counterText:
                              '${_descController.text.trim().runes.length}/500',
                          counterStyle: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.n500,
                          ),
                        ),
                        validator: (val) =>
                            (val != null && val.trim().runes.length > 500)
                                ? 'Mô tả tối đa 500 ký tự'
                                : null,
                      ),
                    ),
                  ),
                ] else ...[
                  GroupedTile(
                    title: 'Tên',
                    value: widget.group.name,
                  ),
                  GroupedTile(
                    title: 'Mô tả',
                    subtitle: (widget.group.description?.trim().isEmpty != false)
                        ? 'Không có'
                        : widget.group.description!.trim(),
                  ),
                ],
              ],
            ),
            if (isAdminOrOwner) ...[
              const SizedBox(height: AppDimensions.s32),
              GroupedSection(
                children: [
                  GroupedTile(
                    title: 'Xoá nhóm',
                    destructive: true,
                    onTap: _deleteGroup,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
