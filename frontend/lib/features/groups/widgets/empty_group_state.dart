// Trách nhiệm file: Cung cấp widget trạng thái chưa có nhóm thống nhất với Design System.

import 'package:flutter/cupertino.dart';

import '../../../core/state/app_sync.dart';
import '../../../core/widgets/fintech_components.dart';

class EmptyGroupState extends StatelessWidget {
  final VoidCallback onCreateGroup;

  const EmptyGroupState({super.key, required this.onCreateGroup});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: AppEmptyState(
          icon: CupertinoIcons.person_2,
          title: tr(context, 'Chưa có nhóm chi tiêu', 'No expense groups yet'),
          message: tr(
            context,
            'Tạo nhóm mới hoặc nhờ bạn bè thêm bạn vào nhóm để bắt đầu chia chi phí.',
            'Create a new group or ask friends to add you to start splitting expenses.',
          ),
          actionLabel: tr(context, 'Tạo nhóm mới', 'Create group'),
          onAction: onCreateGroup,
        ),
      ),
    );
  }
}
