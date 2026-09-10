import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/app_constants.dart';

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
          final session =
              Supabase.instance.client.auth.currentSession;

          if (session != null) {
            options.headers['Authorization'] =
            'Bearer ${session.accessToken}';
          }

          handler.next(options);
        },
        onError: (DioException e, handler) {
          handler.next(e);
        },
      ),
    );
  }

  Dio get dio => _dio;
}