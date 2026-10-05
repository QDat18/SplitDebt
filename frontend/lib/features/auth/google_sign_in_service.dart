// Trách nhiệm file: Khởi tạo Google Sign-In và lấy ID token để backend xác minh.

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/constants/app_constants.dart';

class GoogleSignInService {
  GoogleSignInService({GoogleSignIn? googleSignIn})
      : _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final GoogleSignIn _googleSignIn;
  bool _initialized = false;

  /// Trả ID token có audience là OAuth Web client ID dùng chung với backend.
  Future<String> getIdToken() async {
    final clientId = AppConstants.googleWebClientId;
    if (clientId.isEmpty || clientId.startsWith('YOUR_')) {
      throw StateError(
        'Google Sign-In chưa được cấu hình. Hãy đặt GOOGLE_WEB_CLIENT_ID trong .env.',
      );
    }

    if (!_initialized) {
      await _googleSignIn.initialize(
        clientId: kIsWeb ? clientId : null,
        serverClientId: kIsWeb ? null : clientId,
      );
      _initialized = true;
    }

    try {
      final account = await _googleSignIn.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw StateError('Google không trả về ID token hợp lệ.');
      }
      return idToken;
    } on GoogleSignInException catch (error) {
      switch (error.code) {
        case GoogleSignInExceptionCode.canceled:
          throw Exception('Bạn đã hủy đăng nhập Google.');
        case GoogleSignInExceptionCode.clientConfigurationError:
        case GoogleSignInExceptionCode.providerConfigurationError:
          throw StateError(
            'Google OAuth chưa đúng. Hãy kiểm tra client ID, package name và SHA fingerprint.',
          );
        default:
          throw Exception(
            error.description ?? 'Không thể đăng nhập Google lúc này.',
          );
      }
    }
  }

  /// Xóa phiên Google cục bộ khi người dùng đăng xuất khỏi ứng dụng.
  Future<void> signOut() async {
    if (!_initialized) {
      final clientId = AppConstants.googleWebClientId;
      if (clientId.isEmpty || clientId.startsWith('YOUR_')) {
        return;
      }
      await _googleSignIn.initialize(
        clientId: kIsWeb ? clientId : null,
        serverClientId: kIsWeb ? null : clientId,
      );
      _initialized = true;
    }
    await _googleSignIn.signOut();
  }
}
