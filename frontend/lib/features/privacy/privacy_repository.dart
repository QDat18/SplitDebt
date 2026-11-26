// Trách nhiệm file: Giao tiếp API xuất dữ liệu cá nhân và xoá tài khoản cho tính năng Quyền riêng tư.

import 'package:dio/dio.dart';

import '../../core/network/dio_client.dart';

class OutstandingGroup {
  final int id;
  final String name;
  final double balance;

  const OutstandingGroup({
    required this.id,
    required this.name,
    required this.balance,
  });

  factory OutstandingGroup.fromJson(Map<String, dynamic> json) {
    return OutstandingGroup(
      id: (json['id'] as num).toInt(),
      name: json['name']?.toString() ?? '',
      balance: (json['balance'] as num?)?.toDouble() ?? 0,
    );
  }
}

class OutstandingBalanceError implements Exception {
  final List<OutstandingGroup> groups;
  final String message;

  const OutstandingBalanceError(
    this.groups, [
    this.message = 'Bạn cần thanh toán hết công nợ trước khi xoá tài khoản.',
  ]);

  @override
  String toString() => message;
}

class WrongPasswordError implements Exception {
  final String message;

  const WrongPasswordError([this.message = 'Mật khẩu không đúng']);

  @override
  String toString() => message;
}

class PrivacyRepository {
  PrivacyRepository({Dio? dio}) : _dio = dio ?? dioClient;

  final Dio _dio;

  Future<Map<String, dynamic>> exportData() async {
    final response = await _dio.get('/users/me/data-export');
    final body = response.data;
    if (body is Map<String, dynamic>) {
      final inner = body['data'];
      if (inner is Map<String, dynamic>) {
        return inner;
      }
      return body;
    }
    throw Exception('Phản hồi dữ liệu không hợp lệ');
  }

  Future<void> deleteAccount(String password) async {
    try {
      await _dio.post(
        '/users/me/deletion',
        data: {'password': password},
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final body = e.response?.data;
      if (status == 409 && body is Map<String, dynamic>) {
        final data = body['data'];
        final rawGroups = data is Map ? data['groups'] : null;
        final groups = rawGroups is List
            ? rawGroups
                .whereType<Map>()
                .map((g) => OutstandingGroup.fromJson(Map<String, dynamic>.from(g)))
                .toList()
            : <OutstandingGroup>[];
        throw OutstandingBalanceError(
          groups,
          body['message']?.toString() ??
              'Bạn cần thanh toán hết công nợ trước khi xoá tài khoản.',
        );
      }
      if (status == 400 && body is Map<String, dynamic>) {
        final data = body['data'];
        if (data is Map && data['code'] == 'WRONG_PASSWORD') {
          throw WrongPasswordError(
            body['message']?.toString() ?? 'Mật khẩu không đúng',
          );
        }
      }
      if (body is Map && body['message'] != null) {
        throw Exception(body['message'].toString());
      }
      throw Exception(e.message ?? 'Không thể xoá tài khoản');
    }
  }
}

