import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:split_debt/core/network/dio_client.dart';

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

ResponseBody _jsonResponse(int statusCode, Map<String, dynamic> body) {
  return ResponseBody.fromString(
    jsonEncode(body),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    dotenv.loadFromString(envString: 'API_BASE_URL=http://localhost:8081/api');
  });

  tearDown(() {
    DioClient.onReconsentRequired = null;
    DioClient.resetReconsentGuard();
  });

  test('calls onReconsentRequired once across multiple 428 RECONSENT_REQUIRED responses', () async {
    var calls = 0;
    DioClient.onReconsentRequired = () => calls++;

    final dio = DioClient().dio;
    dio.httpClientAdapter = _StubAdapter(
      (_) => _jsonResponse(428, {'code': 'RECONSENT_REQUIRED'}),
    );

    await expectLater(dio.get('/groups'), throwsA(isA<DioException>()));
    await expectLater(dio.get('/expenses'), throwsA(isA<DioException>()));

    expect(calls, 1);
  });

  test('calls onReconsentRequired again after resetReconsentGuard', () async {
    var calls = 0;
    DioClient.onReconsentRequired = () => calls++;

    final dio = DioClient().dio;
    dio.httpClientAdapter = _StubAdapter(
      (_) => _jsonResponse(428, {'code': 'RECONSENT_REQUIRED'}),
    );

    await expectLater(dio.get('/groups'), throwsA(isA<DioException>()));
    expect(calls, 1);

    DioClient.resetReconsentGuard();
    await expectLater(dio.get('/groups'), throwsA(isA<DioException>()));
    expect(calls, 2);
  });

  test('ignores 428 without code and 400 responses', () async {
    var calls = 0;
    DioClient.onReconsentRequired = () => calls++;

    final dio = DioClient().dio;
    dio.httpClientAdapter = _StubAdapter((options) {
      if (options.path == '/no-code') {
        return _jsonResponse(428, {'message': 'no code'});
      }
      return _jsonResponse(400, {'code': 'RECONSENT_REQUIRED'});
    });

    await expectLater(dio.get('/no-code'), throwsA(isA<DioException>()));
    await expectLater(dio.get('/bad-request'), throwsA(isA<DioException>()));

    expect(calls, 0);
  });
}
