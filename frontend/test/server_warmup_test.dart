import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:split_debt/core/network/server_warmup.dart';

class _RecordingAdapter implements HttpClientAdapter {
  RequestOptions? lastOptions;
  final bool shouldThrow;

  _RecordingAdapter({this.shouldThrow = false});

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastOptions = options;
    if (shouldThrow) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );
    }
    return ResponseBody.fromString('{"status":"UP"}', 200);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('warmUpServer', () {
    test('sends GET /health with 90s connect and receive timeouts', () async {
      final adapter = _RecordingAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'https://example.com/api'))
        ..httpClientAdapter = adapter;

      await warmUpServer(dio);

      expect(adapter.lastOptions, isNotNull);
      expect(adapter.lastOptions!.method, equals('GET'));
      expect(adapter.lastOptions!.uri.toString(), equals('https://example.com/api/health'));
      expect(adapter.lastOptions!.connectTimeout, equals(const Duration(seconds: 90)));
      expect(adapter.lastOptions!.receiveTimeout, equals(const Duration(seconds: 90)));
    });

    test('swallows errors when Dio throws', () async {
      final adapter = _RecordingAdapter(shouldThrow: true);
      final dio = Dio(BaseOptions(baseUrl: 'https://example.com/api'))
        ..httpClientAdapter = adapter;

      await expectLater(warmUpServer(dio), completes);
    });
  });

  group('dioTimeoutMessage', () {
    final req = RequestOptions(path: '/groups');

    test('returns warmup message for connectionTimeout and receiveTimeout', () {
      expect(
        dioTimeoutMessage(
          DioException(requestOptions: req, type: DioExceptionType.connectionTimeout),
        ),
        equals('Máy chủ đang khởi động, vui lòng thử lại sau ít giây.'),
      );
      expect(
        dioTimeoutMessage(
          DioException(requestOptions: req, type: DioExceptionType.receiveTimeout),
        ),
        equals('Máy chủ đang khởi động, vui lòng thử lại sau ít giây.'),
      );
    });

    test('returns null for non-timeout errors so original message is kept', () {
      expect(
        dioTimeoutMessage(
          DioException(requestOptions: req, type: DioExceptionType.badResponse),
        ),
        isNull,
      );
      expect(
        dioTimeoutMessage(
          DioException(requestOptions: req, type: DioExceptionType.connectionError),
        ),
        isNull,
      );
    });
  });
}
