import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final email = _emailController.text.trim();

      await ref
          .read(userGroupsProvider.notifier)
          .addMember(widget.groupId, email, role: _selectedRole);

      ref.invalidate(groupMembersProvider(widget.groupId));

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Đã thêm thành viên vào nhóm!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.person_add_alt_1_rounded, color: Color(0xFF6750A4)),
          SizedBox(width: 10),
          Text(
            'Thêm Thành Viên',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email thành viên *',
                hintText: 'vi_du@email.com',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty)
                  return 'Vui lòng nhập email';
                if (!val.contains('@')) return 'Email không hợp lệ';
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedRole,
              decoration: const InputDecoration(
                labelText: 'Vai trò trong nhóm',
                prefixIcon: Icon(Icons.admin_panel_settings_outlined),
              ),
              items: const [
                DropdownMenuItem(value: 'MEMBER', child: Text('Thành viên')),
                DropdownMenuItem(
                  value: 'ADMIN',
                  child: Text('Quản trị viên (ADMIN)'),
                ),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _selectedRole = val);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text('Thêm thành viên'),
        ),
      ],
    );
  }
}
