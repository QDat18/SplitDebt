// Trách nhiệm file: Chuyển lỗi từ chối quyền camera/ảnh của hệ điều hành sang thông báo hướng dẫn bật lại trong Cài đặt.

import 'package:flutter/services.dart';

String? permissionDeniedMessage(Object error) {
  if (error is! PlatformException) return null;
  switch (error.code) {
    case 'camera_access_denied':
      return 'Chưa có quyền dùng camera. Bạn có thể bật trong Cài đặt > SplitDebt.';
    case 'photo_access_denied':
      return 'Chưa có quyền truy cập ảnh. Bạn có thể bật trong Cài đặt > SplitDebt.';
    default:
      return null;
  }
}
