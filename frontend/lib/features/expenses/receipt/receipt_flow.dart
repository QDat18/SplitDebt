// Trách nhiệm file: Điều phối luồng chọn ảnh, quét ML Kit, phân tích quy tắc, xem trước và xác nhận ghi đè vào form Tạo khoản chi.

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/permission_messages.dart';
import 'receipt_applier.dart';
import 'receipt_models.dart';
import 'receipt_preview_sheet.dart';
import 'receipt_scanner.dart';
import 'rule_based_receipt_parser.dart';

class ReceiptFlow {
  static Future<ImageSource?> _pickSourceSheet(BuildContext context) {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.n0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined, color: AppColors.p500),
              title: const Text('Chụp ảnh'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.p500),
              title: const Text('Chọn từ thư viện'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  static Future<bool> _confirmReplaceItems(BuildContext context) async {
    final result = await showAdaptiveDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog.adaptive(
        title: const Text('Thay danh sách món hiện tại bằng kết quả quét?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Huỷ'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Thay thế'),
          ),
        ],
      ),
    );
    return result == true;
  }

  static void _showError(BuildContext context, String msg) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  static Future<AppliedReceipt?> run(
    BuildContext context, {
    required bool hasExistingItems,
    required ValueChanged<bool> onScanningChanged,
    ReceiptScanner? scanner,
    ReceiptParser? parser,
  }) async {
    final activeScanner = scanner ?? ReceiptScanner();
    final activeParser = parser ?? RuleBasedReceiptParser();

    while (context.mounted) {
      final source = await _pickSourceSheet(context);
      if (source == null || !context.mounted) return null;

      onScanningChanged(true);
      List<String>? rows;
      try {
        rows = await activeScanner.scan(source);
      } catch (e) {
        onScanningChanged(false);
        if (context.mounted) {
          _showError(
            context,
            permissionDeniedMessage(e) ??
                'Không quét được hoá đơn. Vui lòng thử lại.',
          );
        }
        return null;
      }

      if (!context.mounted) {
        onScanningChanged(false);
        return null;
      }

      if (rows == null) {
        onScanningChanged(false);
        return null;
      }

      if (rows.isEmpty) {
        onScanningChanged(false);
        _showError(context, 'Không đọc được chữ trên ảnh. Hãy chụp rõ hơn.');
        return null;
      }

      ParsedReceipt parsed;
      try {
        parsed = activeParser.parse(rows);
      } on ReceiptUnreadable catch (e) {
        onScanningChanged(false);
        _showError(context, e.message);
        return null;
      } catch (_) {
        onScanningChanged(false);
        _showError(context, 'Không quét được hoá đơn. Vui lòng thử lại.');
        return null;
      }

      onScanningChanged(false);
      if (!context.mounted) return null;

      final action = await showModalBottomSheet<PreviewAction>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => ReceiptPreviewSheet(receipt: parsed),
      );

      if (!context.mounted || action == null) return null;
      if (action == PreviewAction.rescan) continue;

      if (hasExistingItems) {
        final confirmed = await _confirmReplaceItems(context);
        if (!confirmed || !context.mounted) return null;
      }

      if (action == PreviewAction.totalOnly) {
        return ReceiptApplier.applyTotalOnly(parsed, DateTime.now());
      }
      return ReceiptApplier.apply(parsed, DateTime.now());
    }
    return null;
  }
}
