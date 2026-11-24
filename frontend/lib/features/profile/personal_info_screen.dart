// Trách nhiệm file: Xây dựng màn hình thông tin cá nhân (PersonalInfoScreen) theo chuẩn Apple HIG, hỗ trợ đổi ảnh đại diện lưu trên Supabase Storage.

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/widgets/grouped_list.dart';
import '../../data/repositories/user_repository.dart';

class PersonalInfoScreen extends StatefulWidget {
  final String name;
  final String email;
  final String? avatarUrl;
  final ValueChanged<String>? onAvatarChanged;

  const PersonalInfoScreen({
    super.key,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.onAvatarChanged,
  });

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  late String? _avatarUrl;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _avatarUrl = widget.avatarUrl;
  }

  Future<void> _selectAndUploadImage(ImageSource source) async {
    Navigator.of(context).pop(); // Đóng modal bottom sheet

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasAvatar = _avatarUrl != null && _avatarUrl!.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.n100,
      appBar: AppBar(
        title: const Text('Thông tin cá nhân'),
        backgroundColor: AppColors.n100,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.s24),
        children: [
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
                            widget.name.isEmpty ? '?' : widget.name.characters.first,
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
          const SizedBox(height: AppDimensions.s12),
          Text(
            widget.name,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.n800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Nhấn vào ảnh để thay đổi',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.n500,
            ),
          ),
          const SizedBox(height: AppDimensions.s24),
          GroupedSection(
            header: 'Hồ sơ người dùng',
            footer:
                'Thông tin này được dùng để các thành viên nhận diện bạn trong nhóm.',
            children: [
              GroupedTile(
                icon: Icons.badge_outlined,
                title: 'Họ và tên',
                value: widget.name,
              ),
              GroupedTile(
                icon: Icons.mail_outline,
                title: 'Email',
                value: widget.email,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
