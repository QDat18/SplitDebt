import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/app_keys.dart';
import '../storage/token_storage.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/notifications/push_notification_service.dart';

enum AuthState { loading, authenticated, unauthenticated }

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

class AuthNotifier extends StateNotifier<AsyncValue<AuthState>> {
  final AuthRepository _authRepository;

  AuthNotifier(this._authRepository)
      : super(const AsyncValue.data(AuthState.loading)) {
    checkToken();
  }

  /// Kiểm tra token đã lưu trong máy
  Future<bool> checkToken() async {
    final token = await tokenStorage.getToken();
    if (token != null && token.isNotEmpty) {
      state = const AsyncValue.data(AuthState.authenticated);
      return true;
    } else {
      state = const AsyncValue.data(AuthState.unauthenticated);
      return false;
    }
  }

  /// Đăng nhập: Lưu JWT và nhảy màn hình ngay lập tức, FCM chạy ngầm
  Future<bool> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final token = await _authRepository.login(email, password);
      await tokenStorage.saveToken(token);
      state = const AsyncValue.data(AuthState.authenticated);

      // Kích hoạt FCM chạy ngầm ở background, không block UI
      unawaited(_initFcmInBackground());

      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Khởi tạo FCM và đăng ký nhận tin ở background (không chặn đăng nhập)
  Future<void> _initFcmInBackground() async {
    try {
      await PushNotificationService.instance.initialize();
      PushNotificationService.instance.bindMessenger(scaffoldMessengerKey);
      final int userId = await _authRepository.getCurrentUserId();
      await PushNotificationService.instance.subscribeToUser(userId);
      debugPrint('FCM background init & subscribe successful for user: $userId');
    } catch (fcmError) {
      debugPrint('FCM background init warning (non-fatal): $fcmError');
    }
  }

  /// Đăng ký tài khoản
  Future<bool> register(
    String fullName,
    String email,
    String password,
  ) async {
    state = const AsyncValue.loading();
    try {
      await _authRepository.register(fullName, email, password);
      state = const AsyncValue.data(AuthState.unauthenticated);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Đăng xuất
  Future<void> logout() async {
    try {
      await PushNotificationService.instance.unsubscribeCurrentUser();
    } catch (_) {
      // Bỏ qua nếu FCM cleanup lỗi
    }
    await tokenStorage.deleteToken();
    AuthRepository.clearCache();
    state = const AsyncValue.data(AuthState.unauthenticated);
  }
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<AuthState>>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return AuthNotifier(authRepository);
});
