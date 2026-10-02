import 'package:dio/dio.dart';
import '../../core/network/dio_client.dart';
import '../../core/constants/app_constants.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

class AuthRepository {
  final Dio _dio;

  AuthRepository({Dio? dio}) : _dio = dio ?? dioClient;

  /// Đăng nhập với email và mật khẩu
  Future<String> login(String email, String password) async {
    try {
      final response = await _dio.post(
        'auth/login',
        data: {
          'email': email.trim(),
          'password': password,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'];
        if (data != null && data['token'] != null) {
          return data['token'] as String;
        }
      }
      throw AuthException('Đăng nhập không thành công: Phản hồi không hợp lệ');
    } on DioException catch (e) {
      if (e.response != null && e.response?.data is Map<String, dynamic>) {
        final resData = e.response!.data as Map<String, dynamic>;
        final msg = resData['message'] as String? ?? 'Sai email hoặc mật khẩu';
        throw AuthException(msg.replaceFirst('Loi tham so: ', '').replaceFirst('Loi he thong: ', ''));
      }
      throw AuthException('Không thể kết nối đến máy chủ (${AppConstants.apiBaseUrl}). Lỗi: ${e.message ?? e.type.name}');
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(e.toString());
    }
  }

  /// Đăng ký tài khoản mới
  Future<String> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        'auth/register',
        data: {
          'fullName': fullName.trim(),
          'email': email.trim(),
          'password': password,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'];
        if (data != null && data['token'] != null) {
          return data['token'] as String;
        }
      }
      throw AuthException('Đăng ký không thành công: Phản hồi không hợp lệ');
    } on DioException catch (e) {
      if (e.response != null && e.response?.data is Map<String, dynamic>) {
        final resData = e.response!.data as Map<String, dynamic>;
        final msg = resData['message'] as String? ?? 'Đăng ký thất bại';
        throw AuthException(msg.replaceFirst('Loi tham so: ', '').replaceFirst('Loi he thong: ', ''));
      }
      throw AuthException('Không thể kết nối đến máy chủ (${AppConstants.apiBaseUrl}). Lỗi: ${e.message ?? e.type.name}');
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(e.toString());
    }
  }
}

final authRepository = AuthRepository();
