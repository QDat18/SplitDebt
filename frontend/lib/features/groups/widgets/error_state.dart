// Trách nhiệm file: Cung cấp widget trạng thái lỗi chuẩn hóa dùng thống nhất.

import 'package:flutter/material.dart';

import '../../../core/state/app_sync.dart';
import '../../../core/widgets/fintech_components.dart';

class ErrorStateWidget extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onRetry;

  const ErrorStateWidget({
    super.key,
    required this.errorMessage,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: AppErrorState(
          title: tr(context, 'Không tải được dữ liệu', 'Could not load data'),
          message: errorMessage,
          onRetry: onRetry,
        ),
      ),
    );
  }
}
