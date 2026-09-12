import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app/app_keys.dart';
import '../../../core/storage/token_storage.dart';
import '../../notifications/notification_repository.dart';
import '../../notifications/push_notification_service.dart';
import '../data/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) {
    return AuthRepository();
  },
);

final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) {
    return NotificationRepository();
  },
);

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<void>>(
  (ref) {
    final authRepository = ref.watch(
      authRepositoryProvider,
    );

    final notificationRepository = ref.watch(
      notificationRepositoryProvider,
    );

    return AuthNotifier(
      authRepository,
      notificationRepository,
    );
  },
);

class AuthNotifier extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _authRepository;

  final NotificationRepository _notificationRepository;

  AuthNotifier(
    this._authRepository,
    this._notificationRepository,
  ) : super(
          const AsyncData(
            null,
          ),
        );

  // ===========================================================================
  // LOGIN
  // ===========================================================================
  Future<bool> login(
    String email,
    String password,
  ) async {
    state = const AsyncLoading();

    try {
      // -----------------------------------------------------------------------
      // 1. Login backend
      // -----------------------------------------------------------------------
      final String token = await _authRepository.login(
        email,
        password,
      );

      // -----------------------------------------------------------------------
      // 2. Lưu JWT
      // -----------------------------------------------------------------------
      await tokenStorage.saveToken(
        token,
      );

      // -----------------------------------------------------------------------
      // 3. Login đã thành công.
      //    FCM lỗi cũng KHÔNG làm login thất bại.
      // -----------------------------------------------------------------------
      try {
        // ---------------------------------------------------------------------
        // Web:
        // Sau khi user thao tác login thì Service Worker đã có thời gian active.
        //
        // Android:
        // initialize bình thường.
        // ---------------------------------------------------------------------
        await PushNotificationService.instance.initialize();

        // Messenger dùng để hiện notification foreground bằng SnackBar.
        PushNotificationService.instance.bindMessenger(
          scaffoldMessengerKey,
        );

        // ---------------------------------------------------------------------
        // 4. Lấy ID user thật từ backend
        // ---------------------------------------------------------------------
        final int userId = await _authRepository.getCurrentUserId();

        debugPrint(
          'Current backend userId: $userId',
        );

        // ---------------------------------------------------------------------
        // 5. Gắn FCM với user hiện tại
        // ---------------------------------------------------------------------
        await PushNotificationService.instance.subscribeToUser(
          userId,
        );
      } catch (fcmError, fcmStackTrace) {
        // ---------------------------------------------------------------------
        // FCM hỏng không được làm login hỏng.
        // ---------------------------------------------------------------------
        debugPrint(
          'Login thành công nhưng đăng ký FCM thất bại: '
          '$fcmError',
        );

        debugPrint(
          '$fcmStackTrace',
        );
      }

      state = const AsyncData(
        null,
      );

      return true;
    } catch (e, stackTrace) {
      state = AsyncError(
        e,
        stackTrace,
      );

      return false;
    }
  }

  // ===========================================================================
  // REGISTER
  // ===========================================================================
  Future<bool> register(
    String fullName,
    String email,
    String password,
  ) async {
    state = const AsyncLoading();

    try {
      await _authRepository.register(
        fullName,
        email,
        password,
      );

      state = const AsyncData(
        null,
      );

      return true;
    } catch (e, stackTrace) {
      state = AsyncError(
        e,
        stackTrace,
      );

      return false;
    }
  }

  // ===========================================================================
  // LOGOUT
  // ===========================================================================
  Future<void> logout() async {
    // -------------------------------------------------------------------------
    // Xóa FCM token khỏi backend trước khi xóa JWT.
    // -------------------------------------------------------------------------
    try {
      final String? fcmToken =
          await PushNotificationService.instance.getToken();

      if (fcmToken != null && fcmToken.isNotEmpty) {
        await _notificationRepository.removeFcmToken(
          token: fcmToken,
        );

        debugPrint(
          'Đã xóa FCM token khỏi backend.',
        );
      }
    } catch (e) {
      debugPrint(
        'Không xóa được FCM token backend: $e',
      );
    }

    // -------------------------------------------------------------------------
    // Android unsubscribe topic cũ.
    // Web chỉ reset current user.
    // -------------------------------------------------------------------------
    try {
      await PushNotificationService.instance.unsubscribeCurrentUser();
    } catch (e) {
      debugPrint(
        'Không unsubscribe được FCM: $e',
      );
    }

    // -------------------------------------------------------------------------
    // Cuối cùng mới xóa JWT.
    // -------------------------------------------------------------------------
    await tokenStorage.deleteToken();

    state = const AsyncData(
      null,
    );
  }
}
