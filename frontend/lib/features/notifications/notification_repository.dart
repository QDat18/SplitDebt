import 'package:dio/dio.dart';

import '../../core/network/dio_client.dart';

class NotificationRepository {
  final Dio _dio;

  NotificationRepository({
    Dio? dio,
  }) : _dio = dio ?? dioClient;

  // ===========================================================================
  // REGISTER FCM TOKEN
  // ===========================================================================
  Future<void> registerFcmToken({
    required int userId,
    required String token,
    required String platform,
  }) async {
    try {
      await _dio.post(
        '/notifications/fcm-token',
        data: {
          'userId': userId,
          'token': token,
          'platform': platform,
        },
      );
    } on DioException catch (e) {
      if (e.response?.data is Map) {
        final dynamic data = e.response?.data;

        throw Exception(
          data['message']?.toString() ?? 'Không thể đăng ký FCM token',
        );
      }

      throw Exception(
        e.message ?? 'Không thể đăng ký FCM token',
      );
    }
  }

  // ===========================================================================
  // REMOVE FCM TOKEN
  // ===========================================================================
  Future<void> removeFcmToken({
    required String token,
  }) async {
    try {
      await _dio.delete(
        '/notifications/fcm-token',
        data: {
          'token': token,
        },
      );
    } on DioException catch (e) {
      if (e.response?.data is Map) {
        final dynamic data = e.response?.data;

        throw Exception(
          data['message']?.toString() ?? 'Không thể xóa FCM token',
        );
      }

      throw Exception(
        e.message ?? 'Không thể xóa FCM token',
      );
    }
  }
}
