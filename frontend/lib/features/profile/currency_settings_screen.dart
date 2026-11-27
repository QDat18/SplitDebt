// Trách nhiệm file: Xây dựng màn hình cài đặt tiền tệ (CurrencySettingsScreen) theo chuẩn Apple HIG.

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/widgets/grouped_list.dart';

class CurrencySettingsScreen extends StatelessWidget {
  const CurrencySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.n100,
      appBar: AppBar(
        title: const Text('Tiền tệ'),
        backgroundColor: AppColors.n100,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.s24),
        children: const [
          GroupedSection(
            header: 'Đơn vị tiền tệ chính',
            footer: 'Hiện tại hệ thống hỗ trợ đơn vị tiền tệ mặc định là Việt Nam Đồng (₫).',
            children: [
              GroupedTile(
                icon: Icons.attach_money,
                title: 'Việt Nam Đồng (VND)',
                value: '₫',
                trailing: Icon(Icons.check, color: AppColors.p500),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
