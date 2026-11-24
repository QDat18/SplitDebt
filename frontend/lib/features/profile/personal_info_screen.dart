// Trách nhiệm file: Xây dựng màn hình thông tin cá nhân (PersonalInfoScreen) theo chuẩn Apple HIG, hỗ trợ đổi avatar, cập nhật thông tin và xem nhật ký hoạt động.

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_typography.dart';
import '../../data/repositories/user_repository.dart';

class PersonalInfoScreen extends StatefulWidget {
  final String name;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final ValueChanged<String>? onAvatarChanged;
  final void Function(String name, String? phone)? onProfileUpdated;

  const PersonalInfoScreen({
    super.key,
    required this.name,
    required this.email,
    this.phone,
    this.avatarUrl,
    this.onAvatarChanged,
    this.onProfileUpdated,
  });

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  late String? _avatarUrl;
  late TextEditingController _nameController;
  late TextEditingController _phoneController;

  bool _isUploading = false;
  bool _isSaving = false;
  bool _isLoadingLogs = true;
  List<Map<String, dynamic>> _logs = [];

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _avatarUrl = widget.avatarUrl;
    _nameController = TextEditingController(text: widget.name);
    _phoneController = TextEditingController(text: widget.phone ?? '');
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final profile = await userRepository.getProfile();
      if (mounted) {
        if (_phoneController.text.isEmpty && profile['phone'] != null) {
          _phoneController.text = profile['phone'].toString();
        }
        if (_nameController.text.isEmpty && profile['fullName'] != null) {
          _nameController.text = profile['fullName'].toString();
        }
      }
    } catch (_) {}

    await _loadLogs();
  }

  Future<void> _loadLogs() async {
    try {
      final logs = await userRepository.getUserLogs();
      if (mounted) {
        setState(() {
          _logs = logs;
          _isLoadingLogs = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingLogs = false;
        });
      }
    }
  }

  Future<void> _selectAndUploadImage(ImageSource source) async {
    Navigator.of(context).pop();

    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() {
        _isUploading = true;
      });

      final newAvatarUrl = await userRepository.uploadAvatar(image.path);

      if (!mounted) return;

      setState(() {
        _avatarUrl = newAvatarUrl;
        _isUploading = false;
      });

      widget.onAvatarChanged?.call(newAvatarUrl);
      _loadLogs();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đổi ảnh đại diện thành công!'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isUploading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi tải ảnh: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showImageSourcePicker() {
    if (_isUploading) return;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.n0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.n300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Text(
                  'Chọn ảnh đại diện',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.n800,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: AppColors.p500),
                title: const Text('Chụp ảnh mới'),
                onTap: () => _selectAndUploadImage(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.p500),
                title: const Text('Chọn từ thư viện'),
                onTap: () => _selectAndUploadImage(ImageSource.gallery),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    final newName = _nameController.text.trim();
    final newPhone = _phoneController.text.trim();

    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Họ và tên không được để trống'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final updated = await userRepository.updateProfile(
        fullName: newName,
        phone: newPhone.isEmpty ? null : newPhone,
      );

      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      widget.onProfileUpdated?.call(
        updated['fullName']?.toString() ?? newName,
        updated['phone']?.toString() ?? newPhone,
      );

      _loadLogs();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã cập nhật thông tin thành công!'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi cập nhật: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  String _formatDate(dynamic value) {
    if (value == null) return '';
    final str = value.toString();
    final date = DateTime.tryParse(str);
    if (date != null) {
      final local = date.toLocal();
      return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    }
    return str.replaceAll('T', ' ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasAvatar = _avatarUrl != null && _avatarUrl!.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.n100,
      appBar: AppBar(
        title: const Text(
          'Thông tin cá nhân',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.n100,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Lưu',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.p500,
                    ),
                  ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          // 1. Avatar Card
          Center(
            child: GestureDetector(
              onTap: _showImageSourcePicker,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 46,
                    backgroundColor: AppColors.p500,
                    backgroundImage: hasAvatar ? NetworkImage(_avatarUrl!) : null,
                    onBackgroundImageError: hasAvatar ? (_, __) {} : null,
                    child: hasAvatar
                        ? null
                        : Text(
                            _nameController.text.isEmpty
                                ? '?'
                                : _nameController.text.characters.first,
                            style: theme.textTheme.headlineLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  if (_isUploading)
                    Container(
                      width: 92,
                      height: 92,
                      decoration: const BoxDecoration(
                        color: Colors.black45,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.p500,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.n100, width: 2.5),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        size: 15,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Nhấn vào ảnh để thay đổi',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.n500,
            ),
          ),
          const SizedBox(height: 24),

          // 2. Profile Edit Form (iOS Inset Grouped)
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'Hồ sơ người dùng',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.n600,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.n0,
              borderRadius: BorderRadius.circular(14),
              boxShadow: AppDimensions.shadowSm,
            ),
            child: Column(
              children: [
                // Field 1: Họ và tên
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.p50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.person_rounded, size: 18, color: AppColors.p500),
                      ),
                      const SizedBox(width: 14),
                      const Text(
                        'Họ và tên',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.n800,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _nameController,
                          textAlign: TextAlign.end,
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppColors.n900,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Nhập họ tên',
                            hintStyle: TextStyle(color: AppColors.n400),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, indent: 56, endIndent: 16, color: AppColors.n100),

                // Field 2: Số điện thoại
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.p50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.phone_rounded, size: 18, color: AppColors.p500),
                      ),
                      const SizedBox(width: 14),
                      const Text(
                        'Điện thoại',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.n800,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          textAlign: TextAlign.end,
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppColors.n900,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Chưa cập nhật',
                            hintStyle: TextStyle(color: AppColors.n400),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, indent: 56, endIndent: 16, color: AppColors.n100),

                // Field 3: Email (chỉ đọc)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.n100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.mail_outline_rounded, size: 18, color: AppColors.n600),
                      ),
                      const SizedBox(width: 14),
                      const Text(
                        'Email',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.n800,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          widget.email,
                          textAlign: TextAlign.end,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.n500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Email là thông tin định danh dùng để đăng nhập và không thể sửa.',
              style: TextStyle(fontSize: 12, color: AppColors.n500),
            ),
          ),
          const SizedBox(height: 28),

          // 3. User Activity Log Section (Nhật ký tài khoản)
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'Nhật ký tài khoản',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.n600,
              ),
            ),
          ),
          if (_isLoadingLogs)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_logs.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.n0,
                borderRadius: BorderRadius.circular(14),
                boxShadow: AppDimensions.shadowSm,
              ),
              child: const Column(
                children: [
                  Icon(Icons.history_toggle_off_rounded, size: 36, color: AppColors.n400),
                  SizedBox(height: 8),
                  Text(
                    'Chưa có nhật ký hoạt động nào',
                    style: TextStyle(fontSize: 14, color: AppColors.n600),
                  ),
                ],
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: AppColors.n0,
                borderRadius: BorderRadius.circular(14),
                boxShadow: AppDimensions.shadowSm,
              ),
              child: Column(
                children: [
                  for (int i = 0; i < _logs.length; i++) ...[
                    if (i > 0)
                      const Divider(height: 1, indent: 56, endIndent: 16, color: AppColors.n100),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: _logs[i]['action'] == 'UPDATE_AVATAR'
                                  ? AppColors.success.withValues(alpha: 0.1)
                                  : AppColors.p50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              _logs[i]['action'] == 'UPDATE_AVATAR'
                                  ? Icons.account_circle_outlined
                                  : Icons.edit_note_rounded,
                              size: 18,
                              color: _logs[i]['action'] == 'UPDATE_AVATAR'
                                  ? AppColors.success
                                  : AppColors.p500,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _logs[i]['description']?.toString() ?? 'Cập nhật tài khoản',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.n800,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  _formatDate(_logs[i]['createdAt']),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.n500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
