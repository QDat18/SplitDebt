import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:split_debt/core/network/network_error.dart';

void main() {
  final request = RequestOptions(path: '/auth/login');
  test('Connection error is readable and does not dump XMLHttpRequest', () {
    final error = DioException(
      requestOptions: request,
      type: DioExceptionType.connectionError,
      message: 'XMLHttpRequest onError',
    );
    expect(networkErrorMessage(error), contains('Không kết nối được máy chủ'));
    expect(networkErrorMessage(error), isNot(contains('XMLHttpRequest')));
  });
  test('Backend message is preserved', () {
    final error = DioException(
      requestOptions: request,
      type: DioExceptionType.badResponse,
      response: Response(
        requestOptions: request,
        statusCode: 400,
        data: {'message': 'Sai thông tin'},
      ),
    );
    expect(networkErrorMessage(error), 'Sai thông tin');
  });
  test('Timeout has actionable message', () {
    expect(
      networkErrorMessage(
        DioException(
          requestOptions: request,
          type: DioExceptionType.receiveTimeout,
        ),
      ),
      contains('quá lâu'),
    );
  });
}
