// Trách nhiệm file: Xây dựng màn hình giới thiệu (AboutScreen) theo chuẩn Apple HIG.

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/widgets/app_mark.dart';
import '../../core/widgets/grouped_list.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.n100,
      appBar: AppBar(
        title: const Text('Giới thiệu'),
        backgroundColor: AppColors.n100,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.s24),
        children: [
          const Center(child: AppMark(size: 72, elevated: false)),
          const SizedBox(height: AppDimensions.s16),
          Text(
            'Xén Nợ (SplitDebt)',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.n800,
            ),
          ),
          const SizedBox(height: AppDimensions.s4),
          Text(
            'Phiên bản 1.0.0',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.n600,
            ),
          ),
          const SizedBox(height: AppDimensions.s24),
          GroupedSection(
            header: 'Mô tả ứng dụng',
            children: [
              Padding(
                padding: const EdgeInsets.all(AppDimensions.s16),
                child: Text(
                  'SplitDebt là giải pháp quản lý chi tiêu nhóm thông minh, giúp tự động hoá việc tính toán và tối ưu hoá các khoản nợ chéo (Smart Settlement) giữa các thành viên. Chia tiền nhóm, hết lăn tăn!',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.n800,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.s24),
          const GroupedSection(
            header: 'Thông tin dự án',
            children: [
              GroupedTile(
                icon: Icons.school_outlined,
                title: 'Học phần',
                value: 'Lập trình di động',
              ),
              GroupedTile(
                icon: Icons.account_balance_outlined,
                title: 'Đơn vị',
                value: 'Học viện Ngân hàng',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
