// Trách nhiệm file: Xây dựng màn hình thông tin cá nhân (PersonalInfoScreen) theo chuẩn Apple HIG, hỗ trợ đổi avatar, chỉnh sửa thông tin khi bấm nút và xem nhật ký hoạt động.

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/utils/permission_messages.dart';
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
  late String _currentName;
  late String _currentPhone;

  late TextEditingController _nameController;
  late TextEditingController _phoneController;

  bool _isEditing = false;
  bool _isUploading = false;
  bool _isSaving = false;
  bool _isLoadingLogs = true;
  List<Map<String, dynamic>> _logs = [];

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _avatarUrl = widget.avatarUrl;
    _currentName = widget.name;
    _currentPhone = widget.phone ?? '';

    _nameController = TextEditingController(text: _currentName);
    _phoneController = TextEditingController(text: _currentPhone);
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
        final fetchedPhone = profile['phone']?.toString() ?? '';
        final fetchedName = profile['fullName']?.toString() ?? '';
        setState(() {
          if (fetchedPhone.isNotEmpty) {
            _currentPhone = fetchedPhone;
            _phoneController.text = fetchedPhone;
          }
          if (fetchedName.isNotEmpty) {
            _currentName = fetchedName;
            _nameController.text = fetchedName;
          }
        });
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
          content: Text(
            permissionDeniedMessage(e) ??
                'Lỗi tải ảnh: ${e.toString().replaceAll('Exception: ', '')}',
          ),
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
        _isEditing = false;
        _currentName = updated['fullName']?.toString() ?? newName;
        _currentPhone = updated['phone']?.toString() ?? newPhone;
      });

      widget.onProfileUpdated?.call(_currentName, _currentPhone);
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

  void _cancelEditing() {
    setState(() {
      _nameController.text = _currentName;
      _phoneController.text = _currentPhone;
      _isEditing = false;
    });
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
        title: Text(
          _isEditing ? 'Chỉnh sửa hồ sơ' : 'Thông tin cá nhân',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.n100,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: _isEditing
            ? TextButton(
                onPressed: _cancelEditing,
                child: const Text(
                  'Huỷ',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.n700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
            : null,
        actions: [
          if (!_isEditing)
            TextButton.icon(
              onPressed: () => setState(() => _isEditing = true),
              icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.p500),
              label: const Text(
                'Sửa',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.p500,
                ),
              ),
            )
          else
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
                            _currentName.isEmpty
                                ? '?'
                                : _currentName.characters.first,
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

          // 2. Profile Details / Form (iOS Inset Grouped)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
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
              if (!_isEditing)
                GestureDetector(
                  onTap: () => setState(() => _isEditing = true),
                  child: const Padding(
                    padding: EdgeInsets.only(right: 4, bottom: 8),
                    child: Text(
                      'Chỉnh sửa',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.p500,
                      ),
                    ),
                  ),
                ),
            ],
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                        child: _isEditing
                            ? TextField(
                                controller: _nameController,
                                textAlign: TextAlign.end,
                                autofocus: true,
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
                              )
                            : Text(
                                _currentName.isEmpty ? 'Chưa đặt tên' : _currentName,
                                textAlign: TextAlign.end,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.n900,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, indent: 56, endIndent: 16, color: AppColors.n100),

                // Field 2: Số điện thoại
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                        child: _isEditing
                            ? TextField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                textAlign: TextAlign.end,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: AppColors.n900,
                                  fontWeight: FontWeight.w500,
                                ),
                                decoration: const InputDecoration(
                                  hintText: 'Nhập số điện thoại',
                                  hintStyle: TextStyle(color: AppColors.n400),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                              )
                            : Text(
                                _currentPhone.isNotEmpty ? _currentPhone : 'Chưa cập nhật',
                                textAlign: TextAlign.end,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: _currentPhone.isNotEmpty
                                      ? AppColors.n900
                                      : AppColors.n400,
                                  fontWeight: FontWeight.w500,
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
              'Email là thông tin định danh dùng để đăng nhập và không thể thay đổi.',
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
