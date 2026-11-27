import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

const kServerWarmingUpMessage =
    'Máy chủ đang khởi động, vui lòng thử lại sau ít giây.';

String? dioTimeoutMessage(DioException e) {
  if (e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.receiveTimeout) {
    return kServerWarmingUpMessage;
  }
  return null;
}

Future<void> warmUpServer(Dio dio) async {
  try {
    await dio.get<dynamic>(
      '/health',
      options: Options(
        connectTimeout: const Duration(seconds: 90),
        receiveTimeout: const Duration(seconds: 90),
      ),
    );
  } catch (e) {
    debugPrint('Server warm-up skipped: $e');
  }
}
