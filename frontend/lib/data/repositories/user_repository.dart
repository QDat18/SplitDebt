// Trách nhiệm file: Đóng gói các API liên quan đến thông tin người dùng và tải lên avatar.

import 'package:dio/dio.dart';

import '../../core/network/dio_client.dart';

class UserRepository {
  final Dio _dio;

  UserRepository({Dio? dio}) : _dio = dio ?? dioClient;

  Future<Map<String, dynamic>> getProfile() async {
    final response = await _dio.get('/users/me');
    final raw = response.data;
    if (raw is Map && raw['data'] is Map) {
      return Map<String, dynamic>.from(raw['data'] as Map);
    }
    if (raw is Map<String, dynamic>) {
      return raw;
    }
    throw Exception('Dữ liệu hồ sơ không hợp lệ');
  }

  Future<String> uploadAvatar(String filePath) async {
    final fileName = filePath.split(RegExp(r'[/\\]')).last;
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        filePath,
        filename: fileName,
      ),
    });

    final response = await _dio.post(
      '/users/me/avatar',
      data: formData,
    );

    final raw = response.data;
    final data = raw is Map && raw['data'] is Map ? raw['data'] : raw;
    if (data is Map && data['avatarUrl'] != null) {
      return data['avatarUrl'].toString();
    }
    throw Exception('Không nhận được URL ảnh đại diện sau khi tải lên');
  }
}

final userRepository = UserRepository();
