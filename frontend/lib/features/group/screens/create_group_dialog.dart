import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
            content: Text('🎉 Tạo nhóm thành công!'),
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
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog.fullscreen(
          child: Scaffold(
        appBar: AppBar(title: const Text('Tạo nhóm mới')),
        body: Form(
            key: _formKey,
            child: ListView(padding: const EdgeInsets.all(20), children: [
              const SizedBox(height: 20),
              const Center(
                  child: CircleAvatar(
                      radius: 38,
                      backgroundColor: Color(0xFFF0EDFF),
                      child: Text('🌴', style: TextStyle(fontSize: 38)))),
              const SizedBox(height: 32),
              const Text('Tên nhóm',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(hintText: 'Hải Phòng Trip'),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Vui lòng nhập tên nhóm'
                      : v.trim().length > 150
                          ? 'Tên nhóm tối đa 150 ký tự'
                          : null),
              const SizedBox(height: 20),
              const Text('Mô tả (Không bắt buộc)',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                  controller: _descriptionController,
                  decoration:
                      const InputDecoration(hintText: 'Chuyến đi cuối tuần...'),
                  maxLines: 3),
              const SizedBox(height: 26),
              const Text('Thành viên',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              const Card(
                  child: ListTile(
                      leading: CircleAvatar(
                          backgroundColor: Color(0xFFF0EDFF),
                          child: Icon(Icons.person_outline,
                              color: Color(0xFF6C5CE7))),
                      title: Text('Bạn',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('Trưởng nhóm'))),
              const Text('Thêm thành viên bằng email sau khi tạo nhóm.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF778092))),
            ])),
        bottomNavigationBar: SafeArea(
            child: Padding(
                padding: const EdgeInsets.all(20),
                child: FilledButton(
                    onPressed: _isLoading ? null : _submit,
                    child: Text(_isLoading ? 'Đang tạo...' : 'Tạo nhóm')))),
      ));
}
