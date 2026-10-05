// Trách nhiệm file: Đóng gói truy cập dữ liệu auth repository, tách API và lưu trữ khỏi giao diện.

import 'package:dio/dio.dart';

import '../../core/network/api_response.dart';
import '../../core/network/dio_client.dart';
import '../../features/auth/google_sign_in_service.dart';

class AuthRepository {
  final Dio _dio;
  final GoogleSignInService _googleSignInService;

  static int? _cachedUserId;

  static void clearCache() {
    _cachedUserId = null;
  }

  static void setCachedUserId(int id) {
    _cachedUserId = id;
  }

  AuthRepository({
    Dio? dio,
    GoogleSignInService? googleSignInService,
  })  : _dio = dio ?? dioClient,
        _googleSignInService = googleSignInService ?? GoogleSignInService();

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

  // ===========================================================================
  // GOOGLE LOGIN
  // ===========================================================================
  Future<String> loginWithGoogle() async {
    final idToken = await _googleSignInService.getIdToken();

    try {
      final response = await _dio.post(
        '/auth/google',
        data: {'idToken': idToken},
      );
      final apiResponse = ApiResponse<String>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => (json as Map<String, dynamic>)['token'] as String,
      );

      if (apiResponse.status == 200 && apiResponse.data != null) {
        return apiResponse.data!;
      }
      throw Exception(apiResponse.message);
    } on DioException catch (error) {
      await _googleSignInService.signOut();
      final responseData = error.response?.data;
      if (responseData is Map) {
        throw Exception(
          responseData['message']?.toString() ?? 'Đăng nhập Google thất bại',
        );
      }
      throw Exception(
        error.message ?? 'Không thể kết nối đến máy chủ',
      );
    }
  }

  /// Xóa phiên Google cục bộ khi người dùng đăng xuất khỏi ứng dụng.
  Future<void> signOutGoogle() async {
    await _googleSignInService.signOut();
  }

  // ===========================================================================
  // REGISTER
  // ===========================================================================
  Future<String> register(
    String fullName,
    String email,
    String password,
  ) async {
    try {
      final response = await _dio.post(
        '/auth/register',
        data: {
          'fullName': fullName,
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
          data['message']?.toString() ?? 'Đăng ký thất bại',
        );
      }

      throw Exception(
        e.message ?? 'Không thể kết nối đến máy chủ',
      );
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
