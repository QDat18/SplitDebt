# Review vòng 2: Quyền riêng tư, phần app (Task 7–9)

Review của Claude Code trên `bba0a93..b280ce6`. Áp dụng Global Constraints của `2026-11-26-privacy-consent.md`.

**Đã kiểm tra:**
- `flutter analyze` 0 error. `flutter test -j 1`: 242 passed, 1 skipped.
- Review Focus 1: user cũ đi qua splash hoặc login, rồi `GET /users/me` (route được miễn), `ReconsentScreen`, `POST /users/me/consents` (route được miễn), reset cờ. Không có vòng lặp điều hướng.
- Review Focus 4: `initialize()` không còn gọi `requestPermission`. Sheet chỉ hiện ở Trang chủ, theo policy 7 ngày, tối đa 2 lần.
- Review Focus 5: mọi chỗ đều kiểm tra `isSupported()` trước.
- Checkbox đăng ký mặc định không tích, nút khoá cho tới khi tích đủ 3 ô.
- Xoá tài khoản ánh xạ đúng `WRONG_PASSWORD` và 409, thành công thì logout và về Login.
- `Info.plist` khớp spec 6.4.

Đây là **vòng 2 trên tối đa 3**. Cả hai mục dưới đây là chỗ plan bỏ sót so với spec, không phải lỗi của Antigravity.

## A1. Bị từ chối quyền camera hoặc ảnh thì báo đúng câu của spec

Spec 6.4 yêu cầu khi bị từ chối quyền thì hiện SnackBar "Chưa có quyền dùng camera. Bạn có thể bật trong Cài đặt > SplitDebt.". Hiện tại:
- Quét hoá đơn báo chung chung "Không quét được hoá đơn. Vui lòng thử lại.", khiến người dùng thử lại mãi mà không biết vì sao.
- Màn đổi ảnh đại diện cũng chưa có câu này.

**Sửa:**
- Tạo hàm thuần `String? permissionDeniedMessage(Object error)` (ví dụ trong `lib/core/utils/permission_messages.dart`):
  - `PlatformException` có `code == 'camera_access_denied'` → "Chưa có quyền dùng camera. Bạn có thể bật trong Cài đặt > SplitDebt."
  - `code == 'photo_access_denied'` → "Chưa có quyền truy cập ảnh. Bạn có thể bật trong Cài đặt > SplitDebt."
  - Trường hợp khác → `null`.
- `ReceiptFlow` (khối `catch` quanh `activeScanner.scan`) và `personal_info_screen.dart` (chỗ gọi `pickImage`): nếu hàm trả câu báo thì hiện câu đó, nếu không thì giữ câu báo lỗi cũ.

**Test (`test/permission_messages_test.dart`):** hai mã trên trả đúng câu; `PlatformException(code: 'other')` và `Exception('x')` trả `null`.

## A2. Test cho interceptor 428

Spec mục 8 yêu cầu test "interceptor Dio gặp 428 thì gọi callback điều hướng", nhưng plan Task 7 không liệt kê nên chưa có.

**Test (`test/reconsent_interceptor_test.dart`):** dùng `DioClient().dio`, gắn một `HttpClientAdapter` tự viết trả về mã và body tuỳ ý.
- 428 với body `{"code":"RECONSENT_REQUIRED"}` → callback `DioClient.onReconsentRequired` được gọi **đúng 1 lần**, kể cả khi có 2 request cùng bị 428.
- Sau `DioClient.resetReconsentGuard()`, một 428 mới gọi callback thêm lần nữa.
- 428 không có `code`, và 400 → callback không được gọi.
- Dọn `onReconsentRequired` và reset cờ trong `tearDown`, để không ảnh hưởng test khác.

Nếu thấy cần đổi code `dio_client.dart` để test được thì dừng lại hỏi.

## Kiểm tra cuối

- `flutter analyze` 0 error. `flutter test -j 1` PASS.
- Mỗi mục một commit. Cập nhật `docs/PROGRESS.md`. Không push.
