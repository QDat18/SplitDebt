// Trách nhiệm file: Xây dựng màn hình cài đặt ngôn ngữ (LanguageSettingsScreen) theo chuẩn Apple HIG.

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/widgets/grouped_list.dart';

class LanguageSettingsScreen extends StatelessWidget {
  const LanguageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.n100,
      appBar: AppBar(
        title: const Text('Ngôn ngữ'),
        backgroundColor: AppColors.n100,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.s24),
        children: const [
          GroupedSection(
            header: 'Ngôn ngữ hiển thị',
            footer: 'Giao diện ứng dụng được bản địa hoá đầy đủ sang Tiếng Việt.',
            children: [
              GroupedTile(
                icon: Icons.language,
                title: 'Tiếng Việt',
                value: 'Mặc định',
                trailing: Icon(Icons.check, color: AppColors.p500),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
