import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../core/constants/app_constants.dart';

class ApiFailure implements Exception {
  final String message;
  ApiFailure(this.message);
  @override String toString() => message;
}

class Session {
  Session._();
  static final authenticated = ValueNotifier<bool>(false);
  static String? _token;
  static int? userId;
  static String? email;
  static String? name;

  static GoogleSignIn? _google;

  static GoogleSignIn get _googleSignIn => _google ??= GoogleSignIn(
        scopes: const ['email', 'profile'],
        clientId: kIsWeb && AppConstants.googleSignInConfigured
            ? AppConstants.googleWebClientId
            : null,
        serverClientId: !kIsWeb &&
                defaultTargetPlatform == TargetPlatform.android &&
                AppConstants.googleSignInConfigured
            ? AppConstants.googleWebClientId
            : null,
      );

  static String? get token => _token;

  /// Restores the cached session without making a network request.
  ///
  /// Startup uses this path so the first frame and splash screen are never
  /// blocked by a remote `/me` round-trip. The first authenticated API call
  /// still validates the token; a 401 clears the cached session normally.
  static Future<void> restoreLocal() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    userId = prefs.getInt('auth_user_id');
    email = prefs.getString('auth_email');
    name = prefs.getString('auth_name');
    if (_token == null || _token!.isEmpty || userId == null) {
      _token = null;
      userId = null;
      email = null;
      name = null;
      authenticated.value = false;
      return;
    }
    authenticated.value = true;
  }

  static Future<void> initialize() async {
    await restoreLocal();
    if (!authenticated.value) return;
    try {
      final me = Map<String, dynamic>.from(await Api.call('/me') as Map);
      userId = asInt(me['id']);
      email = me['email']?.toString();
      name = me['name']?.toString();
      await _save();
      authenticated.value = true;
    } catch (_) {
      await clear();
    }
  }

  static Future<void> signIn(String emailValue, String password) async {
    final data = Map<String, dynamic>.from(await Api.publicCall('/auth/login', method: 'POST', body: {
      'email': emailValue.trim(),
      'password': password,
    }) as Map);
    await _acceptAuthResult(data);
  }

  static Future<bool> signInWithGoogle() async {
    if (!AppConstants.googleSignInConfigured) {
      throw ApiFailure(
        'Google Sign-In chưa được cấu hình. Hãy truyền GOOGLE_WEB_CLIENT_ID bằng --dart-define và cấu hình GOOGLE_CLIENT_ID ở Backend.',
      );
    }
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return false;
      final authentication = await account.authentication;
      final idToken = authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw ApiFailure('Google không trả về ID token. Hãy kiểm tra OAuth Client ID.');
      }
      final data = Map<String, dynamic>.from(
        await Api.publicCall('/auth/google', method: 'POST', body: {'idToken': idToken}) as Map,
      );
      await _acceptAuthResult(data);
      return true;
    } on ApiFailure {
      rethrow;
    } catch (e) {
      final message = e.toString();
      if (message.contains('popup_closed') || message.contains('sign_in_canceled')) return false;
      throw ApiFailure('Không thể đăng nhập bằng Google. Vui lòng thử lại hoặc dùng email và mật khẩu.');
    }
  }

  static Future<Map<String, dynamic>> requestPasswordReset(String emailValue) async =>
      Map<String, dynamic>.from(
        await Api.publicCall('/auth/forgot-password', method: 'POST', body: {
          'email': emailValue.trim(),
        }) as Map,
      );

  static Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    await Api.publicCall('/auth/reset-password', method: 'POST', body: {
      'email': email.trim(),
      'code': code.trim(),
      'newPassword': newPassword,
    });
  }

  static Future<void> _acceptAuthResult(Map<String, dynamic> data) async {
    final user = Map<String, dynamic>.from(data['user'] as Map);
    _token = data['token']?.toString();
    if (_token == null || _token!.isEmpty) {
      throw ApiFailure('Máy chủ không trả về token đăng nhập. Vui lòng thử lại.');
    }
    userId = asInt(user['id']);
    email = user['email']?.toString();
    name = user['name']?.toString();
    await _save();
    authenticated.value = true;
  }

  /// Creates an account and, when the backend returns an auth payload,
  /// immediately establishes the local session so registration flows straight
  /// into the app. The boolean return keeps compatibility with older backends
  /// that only returned an id/message pair.
  static Future<bool> register({
    required String fullName,
    required String email,
    required String password,
    String? phone,
    required bool acceptedTerms,
  }) async {
    final raw = await Api.publicCall('/auth/register', method: 'POST', body: {
      'fullName': fullName.trim(),
      'email': email.trim(),
      'phone': phone?.trim(),
      'password': password,
      'acceptedTerms': acceptedTerms,
    });
    if (raw is! Map) return false;
    final data = Map<String, dynamic>.from(raw);
    if (data['token'] == null || data['user'] is! Map) return false;
    await _acceptAuthResult(data);
    return true;
  }

  static Future<void> signOut() async {
    try {
      if (_google != null) await _google!.signOut();
    } catch (_) {}
    await clear();
  }

  static Future<void> clear() async {
    _token = null;
    userId = null;
    email = null;
    name = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('auth_user_id');
    await prefs.remove('auth_email');
    await prefs.remove('auth_name');
    authenticated.value = false;
  }

  static Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    if (_token != null) await prefs.setString('auth_token', _token!);
    if (userId != null) await prefs.setInt('auth_user_id', userId!);
    if (email != null) await prefs.setString('auth_email', email!);
    if (name != null) await prefs.setString('auth_name', name!);
  }
}

class Api {
  /// Test seams. Production code keeps using [http.Client] and [AppConstants.apiUrl].
  /// Tests can inject a MockClient and a local base URL without changing app behavior.
  @visibleForTesting
  static http.Client Function() clientFactory = http.Client.new;

  @visibleForTesting
  static String? baseUrlOverride;

  @visibleForTesting
  static Duration requestTimeout = const Duration(seconds: 12);

  @visibleForTesting
  static void resetTestOverrides() {
    clientFactory = http.Client.new;
    baseUrlOverride = null;
    requestTimeout = const Duration(seconds: 12);
  }

  static Future<dynamic> publicCall(String path, {String method = 'GET', Map<String, dynamic>? body}) =>
      _request(path, method: method, body: body, authenticated: false);

  static Future<dynamic> call(String path, {String method = 'GET', Map<String, dynamic>? body}) =>
      _request(path, method: method, body: body, authenticated: true);

  static Future<dynamic> _request(String path, {
    required String method,
    Map<String, dynamic>? body,
    required bool authenticated,
  }) async {
    if (authenticated && (Session.token == null || Session.token!.isEmpty)) {
      throw ApiFailure('Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.');
    }
    final client = clientFactory();
    try {
      final baseUrl = (baseUrlOverride ?? AppConstants.apiUrl).replaceAll(RegExp(r'/$'), '');
      final request = http.Request(method, Uri.parse('$baseUrl$path'));
      request.headers['Content-Type'] = 'application/json';
      if (authenticated) request.headers['Authorization'] = 'Bearer ${Session.token}';
      if (body != null) request.body = jsonEncode(body);
      final response = await client.send(request).then(http.Response.fromStream).timeout(requestTimeout);
      dynamic data;
      if (response.body.trim().isEmpty) {
        data = <String, dynamic>{};
      } else {
        try {
          data = jsonDecode(response.body);
        } catch (_) {
          throw ApiFailure('Máy chủ trả về dữ liệu không hợp lệ. Vui lòng thử lại.');
        }
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        if (response.statusCode == 401 && authenticated) await Session.clear();
        final message = data is Map ? data['message']?.toString() : null;
        throw ApiFailure(message?.isNotEmpty == true ? message! : 'Yêu cầu chưa được xử lý thành công.');
      }
      return data;
    } on TimeoutException {
      throw ApiFailure('Kết nối quá thời gian. Kiểm tra Backend hoặc Internet rồi thử lại.');
    } on http.ClientException {
      throw ApiFailure('Không thể kết nối máy chủ SplitDebt. Kiểm tra Backend và địa chỉ API.');
    } finally {
      client.close();
    }
  }
}

int asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.parse(value.toString());
}

String money(int amount, String currency) => NumberFormat.currency(
  name: currency,
  symbol: currency == 'USD' ? r'$' : currency == 'EUR' ? '€' : '₫',
  decimalDigits: currency == 'VND' ? 0 : 2,
).format(amount / (currency == 'VND' ? 1 : 100));

int? parseMoney(String input, String currency) {
  final text = input.trim().replaceAll(',', '');
  if (!RegExp(currency == 'VND' ? r'^\d{1,13}$' : r'^\d{1,11}(\.\d{1,2})?$').hasMatch(text)) return null;
  final parts = text.split('.');
  final value = int.parse(parts[0]) * (currency == 'VND' ? 1 : 100) +
      (parts.length == 2 ? int.parse(parts[1].padRight(2, '0')) : 0);
  return value > 0 && value <= 1000000000000 ? value : null;
}

String dateLabel(String? value) {
  if (value == null || value.isEmpty) return '—';
  return DateFormat('dd/MM/yyyy · HH:mm').format(DateTime.parse(value).toLocal());
}

List<Map<String, dynamic>> maps(dynamic value) =>
    value == null ? [] : (value as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
