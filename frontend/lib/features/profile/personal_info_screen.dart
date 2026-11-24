// Trách nhiệm file: Xây dựng màn hình thông tin cá nhân (PersonalInfoScreen) theo chuẩn Apple HIG.

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/widgets/grouped_list.dart';

class PersonalInfoScreen extends StatelessWidget {
  final String name;
  final String email;

  const PersonalInfoScreen({
    super.key,
    required this.name,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
            child: CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.p500,
              child: Text(
                name.isEmpty ? '?' : name.characters.first,
                style: theme.textTheme.headlineLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.s12),
          Text(
            name,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.n800,
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
                value: name,
              ),
              GroupedTile(
                icon: Icons.mail_outline,
                title: 'Email',
                value: email,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
