// Trách nhiệm file: Hiển thị mã QR và đường dẫn mời tham gia nhóm theo chuẩn Apple HIG.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/invite_code_parser.dart';
import '../models/group_model.dart';

class GroupInviteDialog extends StatelessWidget {
  final GroupModel group;

  const GroupInviteDialog({super.key, required this.group});

  static Future<void> show(BuildContext context, GroupModel group) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.n100,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => GroupInviteDialog(group: group),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inviteCode = group.inviteCode ?? group.id;
    final inviteUrl = InviteCodeParser.buildInviteUrl(inviteCode);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // iOS drag indicator
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.n300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Mời vào nhóm',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.n900,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 22, color: AppColors.n600),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Group Name & Description
            Text(
              group.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.n900,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Quét mã QR hoặc gửi link để bạn bè tham gia nhóm',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.n500),
            ),
            const SizedBox(height: 18),

            // QR Code Container
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.n0,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppDimensions.shadowSm,
              ),
              child: QrImageView(
                data: inviteUrl,
                version: QrVersions.auto,
                size: 190.0,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: AppColors.p900,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: AppColors.p900,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Invite Code Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.n0,
                borderRadius: BorderRadius.circular(14),
                boxShadow: AppDimensions.shadowSm,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.p50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.tag_rounded, size: 18, color: AppColors.p500),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Mã nhóm',
                          style: TextStyle(fontSize: 11, color: AppColors.n500),
                        ),
                        const SizedBox(height: 2),
                        SelectableText(
                          inviteCode,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: AppColors.n900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: inviteCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đã sao chép mã nhóm!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded, size: 16, color: AppColors.p500),
                    label: const Text(
                      'Sao chép',
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.p500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Copy Link Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: inviteUrl));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã sao chép link mời vào bộ nhớ tạm!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.p500,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.link_rounded, size: 20),
                label: const Text(
                  'Sao chép link mời tham gia',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

