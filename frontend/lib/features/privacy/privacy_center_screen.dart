// Trách nhiệm file: Màn hình Trung tâm Quyền riêng tư trong tab Cá nhân.

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/widgets/grouped_list.dart';
import '../../data/repositories/auth_repository.dart';
import '../legal/legal_document_screen.dart';
import '../legal/legal_texts.dart';
import '../notifications/push_notification_service.dart';
import 'data_export_screen.dart';
import 'delete_account_flow.dart';

class PrivacyCenterScreen extends StatefulWidget {
  const PrivacyCenterScreen({super.key});

  @override
  State<PrivacyCenterScreen> createState() => _PrivacyCenterScreenState();
}

class _PrivacyCenterScreenState extends State<PrivacyCenterScreen> {
  String _notifStatusLabel = 'Đang kiểm tra';
  DateTime? _acceptedAt;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final status = await PushNotificationService.instance.currentStatus();
    final consent = await AuthRepository().fetchConsentStatus();
    if (!mounted) return;
    setState(() {
      _notifStatusLabel = status == AuthorizationStatus.authorized ||
              status == AuthorizationStatus.provisional
          ? 'Đang bật'
          : 'Đang tắt';
      _acceptedAt = consent?.acceptedAt;
    });
  }

  String _documentsFooter() {
    if (_acceptedAt == null) {
      return 'Phiên bản 26/11/2026.';
    }
    final formatted = DateFormat('dd/MM/yyyy').format(_acceptedAt!.toLocal());
    return 'Phiên bản 26/11/2026. Bạn đã đồng ý ngày $formatted.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.n50,
      appBar: AppBar(
        title: const Text('Quyền riêng tư'),
        backgroundColor: AppColors.n50,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.s16),
        children: [
          GroupedSection(
            header: 'VĂN BẢN',
            footer: _documentsFooter(),
            children: [
              GroupedTile(
                title: 'Chính sách quyền riêng tư',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const LegalDocumentScreen(
                      document: LegalDocType.privacy,
                    ),
                  ),
                ),
              ),
              GroupedTile(
                title: 'Điều khoản sử dụng',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const LegalDocumentScreen(
                      document: LegalDocType.terms,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.s24),
          GroupedSection(
            header: 'QUYỀN CỦA ỨNG DỤNG',
            footer:
                'Thay đổi trong Cài đặt của điện thoại. Ảnh hoá đơn được đọc ngay trên máy và không được gửi đi.',
            children: [
              GroupedTile(
                title: 'Thông báo',
                value: _notifStatusLabel,
              ),
              const GroupedTile(
                title: 'Camera, Ảnh',
                value: 'Hỏi khi dùng',
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.s24),
          GroupedSection(
            header: 'DỮ LIỆU CỦA BẠN',
            children: [
              GroupedTile(
                title: 'Xem dữ liệu của tôi',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const DataExportScreen(),
                  ),
                ),
              ),
              GroupedTile(
                title: 'Xoá tài khoản',
                destructive: true,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const DeleteAccountFlowScreen(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

