import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/api_response.dart';

class AuthRepository {
  final Dio _dio;

  AuthRepository({Dio? dio}) : _dio = dio ?? dioClient;

  Future<String> login(String email, String password) async {
    final response = await _dio.post(
      '/auth/login',
      data: {
        'email': email,
        'password': password,
      },
    );
    
    // ApiResponse<AuthResponse> wrapper
    final apiResponse = ApiResponse.fromJson(
      response.data, 
      (json) => (json as Map<String, dynamic>)['token'] as String
    );
    
    if (apiResponse.status == 200 && apiResponse.data != null) {
      return apiResponse.data!; // Return token
    } else {
      throw Exception(apiResponse.message);
    }
  }

  Future<String> register(String fullName, String email, String password) async {
    final response = await _dio.post(
      '/auth/register',
      data: {
        'fullName': fullName,
        'email': email,
        'password': password,
      },
    );
    
    // ApiResponse<AuthResponse> wrapper
    final apiResponse = ApiResponse.fromJson(
      response.data, 
      (json) => (json as Map<String, dynamic>)['token'] as String
    );

    if (apiResponse.status == 200 && apiResponse.data != null) {
      return apiResponse.data!; // Return token
    } else {
      throw Exception(apiResponse.message);
    }
  }
}
