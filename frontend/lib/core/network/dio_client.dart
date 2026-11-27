// Trách nhiệm file: Cấu hình HTTP client dùng chung, gắn JWT và chuẩn hóa xử lý lỗi/phiên hết hạn.

import 'package:dio/dio.dart';

import '../app/app_keys.dart';
import '../constants/app_constants.dart';
import '../storage/token_storage.dart';
import 'network_error.dart';

class DioClient {
  late final Dio _dio;

  DioClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.apiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Login/register chưa có JWT nên không gắn token.
          if (!_isPublicAuth(options.uri.path)) {
            final token = await tokenStorage.getToken();

            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }

          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401 &&
              !_isPublicAuth(e.requestOptions.uri.path)) {
            await tokenStorage.deleteToken();
            sessionExpiredSignal.value = sessionExpiredSignal.value + 1;
          }
          return handler.next(e.copyWith(message: networkErrorMessage(e)));
        },
      ),
    );
  }

  static bool _isPublicAuth(String path) =>
      path.endsWith('/auth/login') || path.endsWith('/auth/register');

  Dio get dio => _dio;
}

final dioClient = DioClient().dio;
