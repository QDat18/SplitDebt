import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:split_debt/data/api.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    Api.resetTestOverrides();
    Api.baseUrlOverride = 'http://splitdebt.test/api';
    await Session.clear();
  });

  tearDown(() async {
    Api.resetTestOverrides();
    await Session.clear();
  });

  test('publicCall sends JSON and decodes a successful response', () async {
    late http.Request captured;
    Api.clientFactory = () => MockClient((request) async {
      captured = request;
      return http.Response(jsonEncode({'ok': true, 'id': 7}), 200,
          headers: {'content-type': 'application/json'});
    });

    final result = await Api.publicCall('/demo', method: 'POST', body: {'name': 'Duy'}) as Map;
    expect(result['ok'], true);
    expect(result['id'], 7);
    expect(captured.method, 'POST');
    expect(captured.url.toString(), 'http://splitdebt.test/api/demo');
    expect(captured.headers['Content-Type'], 'application/json');
    expect(jsonDecode(captured.body), {'name': 'Duy'});
  });

  test('server error uses API message instead of leaking technical details', () async {
    Api.clientFactory = () => MockClient((_) async =>
        http.Response(jsonEncode({'message': 'Email is already in use.'}), 409));

    await expectLater(
      Api.publicCall('/auth/register', method: 'POST'),
      throwsA(isA<ApiFailure>().having((e) => e.message, 'message', 'Email is already in use.')),
    );
  });

  test('invalid JSON response is converted to a friendly ApiFailure', () async {
    Api.clientFactory = () => MockClient((_) async => http.Response('<html>bad gateway</html>', 502));
    await expectLater(
      Api.publicCall('/demo'),
      throwsA(isA<ApiFailure>().having((e) => e.message, 'message', contains('dữ liệu không hợp lệ'))),
    );
  });

  test('request timeout is converted to a friendly ApiFailure', () async {
    Api.requestTimeout = const Duration(milliseconds: 5);
    Api.clientFactory = () => MockClient((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      return http.Response('{}', 200);
    });
    await expectLater(
      Api.publicCall('/slow'),
      throwsA(isA<ApiFailure>().having((e) => e.message, 'message', contains('quá thời gian'))),
    );
  });

  test('signIn stores token and user session then clear removes it', () async {
    Api.clientFactory = () => MockClient((request) async {
      expect(request.url.path, '/api/auth/login');
      return http.Response(jsonEncode({
        'token': 'test-token',
        'user': {'id': 12, 'email': 'duy@example.com', 'name': 'Duy'}
      }), 200);
    });

    await Session.signIn('duy@example.com', 'password123');
    expect(Session.authenticated.value, true);
    expect(Session.token, 'test-token');
    expect(Session.userId, 12);
    expect(Session.email, 'duy@example.com');

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('auth_token'), 'test-token');
    expect(prefs.getInt('auth_user_id'), 12);

    await Session.clear();
    expect(Session.authenticated.value, false);
    expect(Session.token, isNull);
    expect(prefs.getString('auth_token'), isNull);
  });

  test('initialize restores a valid persisted session using /me', () async {
    SharedPreferences.setMockInitialValues({
      'auth_token': 'persisted-token',
      'auth_user_id': 44,
      'auth_email': 'old@example.com',
      'auth_name': 'Old Name',
    });
    Api.clientFactory = () => MockClient((request) async {
      expect(request.headers['Authorization'], 'Bearer persisted-token');
      return http.Response(jsonEncode({
        'id': 44,
        'email': 'fresh@example.com',
        'name': 'Fresh Name',
        'phone': null,
        'avatarUrl': null,
      }), 200);
    });

    await Session.initialize();
    expect(Session.authenticated.value, true);
    expect(Session.userId, 44);
    expect(Session.email, 'fresh@example.com');
    expect(Session.name, 'Fresh Name');
  });

  test('401 on authenticated request clears local session', () async {
    Api.clientFactory = () => MockClient((request) async {
      if (request.url.path.endsWith('/auth/login')) {
        return http.Response(jsonEncode({
          'token': 'expired-token',
          'user': {'id': 9, 'email': 'user@example.com', 'name': 'User'}
        }), 200);
      }
      return http.Response(jsonEncode({'message': 'Your session expired.'}), 401);
    });
    await Session.signIn('user@example.com', 'password123');
    expect(Session.authenticated.value, true);

    await expectLater(
      Api.call('/groups'),
      throwsA(isA<ApiFailure>().having((e) => e.message, 'message', contains('expired'))),
    );
    expect(Session.authenticated.value, false);
    expect(Session.token, isNull);
  });

  test('authenticated request without token fails before opening HTTP client', () async {
    var clientOpened = false;
    Api.clientFactory = () {
      clientOpened = true;
      return MockClient((_) async => http.Response('{}', 200));
    };
    await expectLater(Api.call('/groups'), throwsA(isA<ApiFailure>()));
    expect(clientOpened, false);
  });
  test('forgot password requests code then resets with the new password', () async {
    final requests = <http.Request>[];
    Api.clientFactory = () => MockClient((request) async {
      requests.add(request);
      if (request.url.path.endsWith('/auth/forgot-password')) {
        return http.Response(jsonEncode({
          'message': 'ok',
          'expiresInMinutes': 10,
          'delivery': 'DEV',
          'devCode': '123456',
        }), 200);
      }
      if (request.url.path.endsWith('/auth/reset-password')) {
        return http.Response(jsonEncode({'message': 'reset'}), 200);
      }
      return http.Response('{}', 404);
    });

    final result = await Session.requestPasswordReset('duy@example.com');
    expect(result['devCode'], '123456');
    await Session.resetPassword(
      email: 'duy@example.com',
      code: '123456',
      newPassword: 'new-password-123',
    );

    expect(requests, hasLength(2));
    expect(requests[0].url.path, '/api/auth/forgot-password');
    expect(jsonDecode(requests[0].body), {'email': 'duy@example.com'});
    expect(requests[1].url.path, '/api/auth/reset-password');
    expect(jsonDecode(requests[1].body), {
      'email': 'duy@example.com',
      'code': '123456',
      'newPassword': 'new-password-123',
    });
  });

}
