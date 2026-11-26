import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:split_debt/core/utils/permission_messages.dart';

void main() {
  test('camera_access_denied returns camera permission message', () {
    expect(
      permissionDeniedMessage(PlatformException(code: 'camera_access_denied')),
      'Chưa có quyền dùng camera. Bạn có thể bật trong Cài đặt > SplitDebt.',
    );
  });

  test('photo_access_denied returns photo permission message', () {
    expect(
      permissionDeniedMessage(PlatformException(code: 'photo_access_denied')),
      'Chưa có quyền truy cập ảnh. Bạn có thể bật trong Cài đặt > SplitDebt.',
    );
  });

  test('other PlatformException or generic Exception returns null', () {
    expect(
      permissionDeniedMessage(PlatformException(code: 'other')),
      isNull,
    );
    expect(
      permissionDeniedMessage(Exception('x')),
      isNull,
    );
  });
}
