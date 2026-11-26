import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:split_debt/features/privacy/privacy_repository.dart';

class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this.handler);

  final ResponseBody Function(RequestOptions options) handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _jsonBody(int statusCode, Map<String, dynamic>? body) {
  final text = body == null ? '' : jsonEncode(body);
  return ResponseBody.fromString(
    text,
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

void main() {
  test('deleteAccount maps 409 to OutstandingBalanceError with group list', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api'));
    dio.httpClientAdapter = _StubAdapter((_) {
      return _jsonBody(409, {
        'status': 409,
        'message': 'Bạn cần thanh toán hết công nợ trước khi xoá tài khoản.',
        'data': {
          'groups': [
            {'id': 7, 'name': 'Nhóm Du Lịch', 'balance': -150000},
          ],
        },
      });
    });
    final repo = PrivacyRepository(dio: dio);

    await expectLater(
      repo.deleteAccount('Password123!'),
      throwsA(
        isA<OutstandingBalanceError>()
            .having((e) => e.groups.length, 'groups.length', 1)
            .having((e) => e.groups.first.id, 'groups[0].id', 7)
            .having((e) => e.groups.first.name, 'groups[0].name', 'Nhóm Du Lịch'),
      ),
    );
  });

  test('deleteAccount maps 400 WRONG_PASSWORD to WrongPasswordError', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api'));
    dio.httpClientAdapter = _StubAdapter((_) {
      return _jsonBody(400, {
        'status': 400,
        'message': 'Mật khẩu không đúng',
        'data': {'code': 'WRONG_PASSWORD'},
      });
    });
    final repo = PrivacyRepository(dio: dio);

    await expectLater(
      repo.deleteAccount('WrongPass'),
      throwsA(isA<WrongPasswordError>()),
    );
  });

  test('deleteAccount 204 completes normally', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api'));
    dio.httpClientAdapter = _StubAdapter((_) => _jsonBody(204, null));
    final repo = PrivacyRepository(dio: dio);

    await expectLater(repo.deleteAccount('Password123!'), completes);
  });
}

