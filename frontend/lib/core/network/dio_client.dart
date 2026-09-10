import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../storage/token_storage.dart';

class DioClient{
  late final Dio _dio;
  DioClient(){
    _dio = Dio(
      BaseOptions(
        baseUrl: 'http://localhost:8081/api',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ));
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Skip appending token for auth endpoints (login/register)
        if (!options.path.contains('auth')) {
          final token = await tokenStorage.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }
        return handler.next(options);
      },
      onError: (DioException e, handler){
        if (e.response != null && e.response?.data is Map<String, dynamic>) {
          final data = e.response?.data as Map<String, dynamic>;
          if (data.containsKey('message')) {
             e = e.copyWith(message: data['message'] as String);
          }
        }
        return handler.next(e);
      },
    ));
  }
  Dio get dio => _dio;
}

final dioClient = DioClient().dio;
