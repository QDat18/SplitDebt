// Trách nhiệm file: Đóng gói truy cập dữ liệu auth repository, tách API và lưu trữ khỏi giao diện.

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../core/constants/app_constants.dart';
import '../../core/network/api_response.dart';
import '../../core/network/dio_client.dart';
import '../../features/legal/consent_models.dart';
import '../../features/legal/legal_texts.dart';

class AuthRepository {
  final Dio _dio;

  static int? _cachedUserId;

  static void clearCache() {
    _cachedUserId = null;
  }

  static void setCachedUserId(int id) {
    _cachedUserId = id;
  }

  AuthRepository({
    Dio? dio,
  }) : _dio = dio ?? dioClient;

  // ===========================================================================
  // LOGIN
  // ===========================================================================
  Future<String> login(
    String email,
    String password,
  ) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      final apiResponse = ApiResponse<String>.fromJson(
        response.data as Map<String, dynamic>,
        (json) {
          final data = json as Map<String, dynamic>;

          return data['token'] as String;
        },
      );

      if (apiResponse.status == 200 && apiResponse.data != null) {
        return apiResponse.data!;
      }

      throw Exception(
        apiResponse.message,
      );
    } on DioException catch (e) {
      if (e.response?.data is Map) {
        final dynamic data = e.response?.data;

        throw Exception(
          data['message']?.toString() ?? 'Đăng nhập thất bại',
        );
      }

      throw Exception(
        e.message ?? 'Không thể kết nối đến máy chủ',
      );
    }
  }

  String _currentPlatform() {
    if (kIsWeb) return 'web';
    return defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
  }

  // ===========================================================================
  // REGISTER
  // ===========================================================================
  Future<String> register(
    String fullName,
    String email,
    String password, {
    String termsVersion = kTermsVersion,
    String privacyVersion = kPrivacyVersion,
    bool ageConfirmed = true,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/register',
        data: {
          'fullName': fullName,
          'email': email,
          'password': password,
          'consents': {
            'termsVersion': termsVersion,
            'privacyVersion': privacyVersion,
            'ageConfirmed': ageConfirmed,
          },
          'platform': _currentPlatform(),
          'appVersion': AppConstants.appVersion,
        },
      );

      final apiResponse = ApiResponse<String>.fromJson(
        response.data as Map<String, dynamic>,
        (json) {
          final data = json as Map<String, dynamic>;

          return data['token'] as String;
        },
      );

      if (apiResponse.status == 200 && apiResponse.data != null) {
        return apiResponse.data!;
      }

      throw Exception(
        apiResponse.message,
      );
    } on DioException catch (e) {
      if (e.response?.data is Map) {
        final dynamic data = e.response?.data;

        throw Exception(
          data['message']?.toString() ?? 'Đăng ký thất bại',
        );
      }

      throw Exception(
        e.message ?? 'Không thể kết nối đến máy chủ',
      );
    }
  }

  Future<ConsentStatus?> fetchConsentStatus() async {
    try {
      final response = await _dio.get('/users/me');
      final dynamic data = response.data;
      if (data is Map<String, dynamic>) {
        final dynamic consent = data['consent'] ??
            (data['data'] is Map ? (data['data'] as Map)['consent'] : null);
        if (consent is Map<String, dynamic>) {
          return ConsentStatus.fromJson(consent);
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<ConsentStatus> submitReconsent({
    required String termsVersion,
    required String privacyVersion,
  }) async {
    try {
      final response = await _dio.post(
        '/users/me/consents',
        data: {
          'items': [
            {
              'type': 'TERMS',
              'granted': true,
              'version': termsVersion,
            },
            {
              'type': 'PRIVACY',
              'granted': true,
              'version': privacyVersion,
            },
          ],
          'source': 'RECONSENT',
          'platform': _currentPlatform(),
          'appVersion': AppConstants.appVersion,
        },
      );
      final dynamic data = response.data;
      if (data is Map<String, dynamic>) {
        return ConsentStatus.fromJson(data);
      }
      throw Exception('Phản hồi không hợp lệ');
    } on DioException catch (e) {
      if (e.response?.data is Map) {
        final dynamic data = e.response?.data;
        throw Exception(
          data['message']?.toString() ?? 'Không thể cập nhật đồng ý',
        );
      }
      throw Exception(e.message ?? 'Không thể kết nối đến máy chủ');
    }
  }

  // ===========================================================================
  // CURRENT USER
  // ===========================================================================
  Future<int> getCurrentUserId({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedUserId != null) {
      return _cachedUserId!;
    }

    try {
      final response = await _dio.get(
        '/users/me',
      );

      final dynamic responseData = response.data;

      if (responseData is! Map) {
        throw Exception(
          'Response /users/me không hợp lệ',
        );
      }

      // -----------------------------------------------------------------------
      // Format:
      // {
      //   status: 200,
      //   data: {
      //     id: 1
      //   }
      // }
      // -----------------------------------------------------------------------
      final dynamic wrappedData = responseData['data'];

      if (wrappedData is Map) {
        final int? id = _extractIdFromMap(
          wrappedData,
        );

        if (id != null) {
          _cachedUserId = id;
          return id;
        }

        final dynamic user = wrappedData['user'];

        if (user is Map) {
          final int? nestedId = _extractIdFromMap(
            user,
          );

          if (nestedId != null) {
            _cachedUserId = nestedId;
            return nestedId;
          }
        }
      }

      // -----------------------------------------------------------------------
      // Format:
      // {
      //   id: 1
      // }
      // -----------------------------------------------------------------------
      final int? directId = _extractIdFromMap(
        responseData,
      );

      if (directId != null) {
        _cachedUserId = directId;
        return directId;
      }

      // -----------------------------------------------------------------------
      // Format:
      // {
      //   user: {
      //     id: 1
      //   }
      // }
      // -----------------------------------------------------------------------
      final dynamic directUser = responseData['user'];

      if (directUser is Map) {
        final int? nestedId = _extractIdFromMap(
          directUser,
        );

        if (nestedId != null) {
          _cachedUserId = nestedId;
          return nestedId;
        }
      }

      throw Exception(
        'Không lấy được thông tin người dùng',
      );
    } on DioException catch (e) {
      if (e.response?.data is Map) {
        final dynamic data = e.response?.data;

        throw Exception(
          data['message']?.toString() ?? 'Không lấy được thông tin người dùng',
        );
      }

      throw Exception(
        e.message ?? 'Không thể kết nối đến máy chủ',
      );
    }
  }

  // ===========================================================================
  // HELPERS
  // ===========================================================================
  int? _extractIdFromMap(
    Map map,
  ) {
    final dynamic rawId = map['id'];

    return _parseUserId(
      rawId,
    );
  }

  int? _parseUserId(
    dynamic rawId,
  ) {
    if (rawId == null) {
      return null;
    }

    if (rawId is int) {
      return rawId;
    }

    if (rawId is num) {
      return rawId.toInt();
    }

    return int.tryParse(
      rawId.toString(),
    );
  }
}
