import 'package:flutter_test/flutter_test.dart';
import 'package:split_debt/core/constants/app_constants.dart';

void main() {
  String resolve(String url, {bool release = true, bool web = false}) =>
      AppConstants.resolveApiBaseUrl(url, release: release, web: web);
  test('release accepts HTTPS API URL and normalizes slash', () {
    expect(resolve('https://api.splitdebt.vn/api/'), 'https://api.splitdebt.vn/api');
  });
  test('release rejects missing, cleartext, local and malformed URLs', () {
    for (final url in [
      '', 'http://api.splitdebt.vn/api', 'https://localhost/api',
      'https://10.0.2.2/api', 'https://192.168.1.5/api',
      'https://server.local/api', 'https://api.splitdebt.vn',
      'https://api.splitdebt.vn/api?token=abc',
      'https://user:pass@api.splitdebt.vn/api',
    ]) {
      expect(() => resolve(url), throwsFormatException, reason: url);
    }
  });
  test('debug retains emulator and web configuration', () {
    expect(resolve('', release: false), 'http://10.0.2.2:8081/api');
    expect(resolve('', release: false, web: true), 'http://localhost:8081/api');
    expect(resolve('http://10.0.2.2:8081/api', release: false, web: true),
        'http://localhost:8081/api');
  });
}
