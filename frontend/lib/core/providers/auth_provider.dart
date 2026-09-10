import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/token_storage.dart';

enum AuthState { loading, authenticated, unauthenticated }

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState.loading) {
    checkToken();
  }

  Future<void> checkToken() async {
    final token = await tokenStorage.getToken();
    if (token != null && token.isNotEmpty) {
      state = AuthState.authenticated;
    } else {
      state = AuthState.unauthenticated;
    }
  }

  Future<void> login(String token) async {
    await tokenStorage.saveToken(token);
    state = AuthState.authenticated;
  }

  Future<void> logout() async {
    await tokenStorage.deleteToken();
    state = AuthState.unauthenticated;
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
