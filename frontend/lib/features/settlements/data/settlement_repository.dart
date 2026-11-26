// Trách nhiệm file: Đóng gói truy cập dữ liệu settlement repository, tách API và lưu trữ khỏi giao diện.

import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';

class SettlementRepository {
  final Dio _dio;

  SettlementRepository({Dio? dio}) : _dio = dio ?? dioClient;

  /// Bước 1: Người trả bấm "Tôi đã chuyển khoản"
  /// POST /api/groups/{groupId}/settlements/{settlementId}/pay
  Future<void> markPaid({
    required int groupId,
    required int settlementId,
    String paymentMethod = 'BANK_TRANSFER',
  }) async {
    try {
      await _dio.post(
        '/groups/$groupId/settlements/$settlementId/pay',
        data: {
          'paymentMethod': paymentMethod,
        },
      );
    } on DioException catch (e) {
      final dynamic d = e.response?.data;
      throw Exception(
        (d is Map ? d['message']?.toString() : null) ??
            e.message ??
            'Không thể ghi nhận thanh toán',
      );
    }
  }

  /// Bước 2: Người nhận bấm "Đã nhận tiền"
  /// POST /api/groups/{groupId}/settlements/{settlementId}/confirm
  /// → Backend gửi FCM cho người trả (SETTLEMENT_CONFIRMED)
  Future<void> confirmPaid({
    required int groupId,
    required int settlementId,
  }) async {
    try {
      await _dio.post(
        '/groups/$groupId/settlements/$settlementId/confirm',
        data: const <String, dynamic>{},
      );
    } on DioException catch (e) {
      final dynamic d = e.response?.data;
      throw Exception(
        (d is Map ? d['message']?.toString() : null) ??
            e.message ??
            'Không thể xác nhận thanh toán',
      );
    }
  }
}
