import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  static String? get token => _token;

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    userId = prefs.getInt('auth_user_id');
    email = prefs.getString('auth_email');
    name = prefs.getString('auth_name');
    if (_token == null || userId == null) {
      await clear();
      return;
    }
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
    final user = Map<String, dynamic>.from(data['user'] as Map);
    _token = data['token']?.toString();
    if (_token == null || _token!.isEmpty) throw ApiFailure('Máy chủ không trả về token đăng nhập. Vui lòng thử lại.');
    userId = asInt(user['id']);
    email = user['email']?.toString();
    name = user['name']?.toString();
    await _save();
    authenticated.value = true;
  }

  static Future<void> register({
    required String fullName,
    required String email,
    required String password,
    String? phone,
    required bool acceptedTerms,
  }) => Api.publicCall('/auth/register', method: 'POST', body: {
    'fullName': fullName.trim(),
    'email': email.trim(),
    'phone': phone?.trim(),
    'password': password,
    'acceptedTerms': acceptedTerms,
  }).then((_) {});

  static Future<void> signOut() => clear();

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
    final client = http.Client();
    try {
      final request = http.Request(method, Uri.parse('${AppConstants.apiUrl}$path'));
      request.headers['Content-Type'] = 'application/json';
      if (authenticated) request.headers['Authorization'] = 'Bearer ${Session.token}';
      if (body != null) request.body = jsonEncode(body);
      final response = await client.send(request).then(http.Response.fromStream).timeout(const Duration(seconds: 20));
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
