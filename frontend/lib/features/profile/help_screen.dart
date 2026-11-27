// Trách nhiệm file: Xây dựng màn hình trợ giúp (HelpScreen) theo chuẩn Apple HIG.

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/widgets/grouped_list.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.n100,
      appBar: AppBar(
        title: const Text('Trợ giúp'),
        backgroundColor: AppColors.n100,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.s24),
        children: const [
          GroupedSection(
            header: 'Quy trình sử dụng SplitDebt',
            footer:
                'Hệ thống tự động đồng bộ số liệu và cập nhật công nợ theo thời gian thực.',
            children: [
              GroupedTile(
                icon: Icons.group_add_outlined,
                title: '1. Tạo nhóm & mời bạn bè',
                subtitle:
                    'Tạo nhóm mới và thêm các thành viên bằng email họ đã đăng ký tài khoản.',
              ),
              GroupedTile(
                icon: Icons.receipt_long_outlined,
                title: '2. Ghi khoản chi tiêu',
                subtitle:
                    'Thêm hóa đơn, chọn người thanh toán và người tham gia chia tiền.',
              ),
              GroupedTile(
                icon: Icons.swap_horiz_rounded,
                title: '3. Cân bằng tiền sòng phẳng',
                subtitle:
                    'Gom các khoản nợ chéo để bạn chỉ cần chuyển tiền ít lần nhất.',
              ),
              GroupedTile(
                icon: Icons.verified_outlined,
                title: '4. Thanh toán & xác nhận',
                subtitle:
                    'Người nợ báo đã chuyển khoản; người nhận kiểm tra tài khoản và xác nhận.',
              ),
            ],
          ),
          SizedBox(height: AppDimensions.s24),
          GroupedSection(
            header: 'Câu hỏi thường gặp',
            children: [
              GroupedTile(
                icon: Icons.help_center_outlined,
                title: 'Làm sao để thanh toán?',
                subtitle:
                    'Vào tab Quyết toán > chọn khoản nợ của bạn > ấn Thanh toán và chọn phương thức.',
              ),
              GroupedTile(
                icon: Icons.sync_problem_outlined,
                title: 'Khi nào công nợ cập nhật?',
                subtitle:
                    'Công nợ chỉ giảm sau khi người nhận đã bấm Xác nhận đã nhận tiền.',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
