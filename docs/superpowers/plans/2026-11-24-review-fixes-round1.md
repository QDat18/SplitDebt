# Review vòng 1: sửa lỗi sau Task 1–7

Review của Claude Code trên `109857c..32d11d9`. Backend 32/32 test PASS, `flutter analyze` 0 error.
Vẫn áp dụng toàn bộ Global Constraints của `2026-11-24-review-fixes.md` (TDD, không `.env`, không push, mơ hồ thì hỏi).
Mỗi mục là một commit riêng.

## R1. Tắt thông báo không được làm mất tự động làm mới màn hình (quan trọng)

**Lỗi:** `NotificationService.shouldPush()` bỏ hẳn bước gửi FCM. Trong khi đó `live_settlement_screen.dart:46` và `notification_screen.dart:31` chỉ tải lại dữ liệu khi nhận `FirebaseMessaging.onMessage`. Hậu quả: người tắt thông báo sẽ thấy số dư cũ cho tới khi rời màn hình.

**Sửa:**
- `FcmPushService`: thêm `public void sendDataOnlyToUserTopic(Long userId, Map<String, String> data)`. Gửi tới cùng topic như `sendToUserTopic` nhưng **không** gọi `setNotification`, chỉ `putAllData`. Lỗi xử lý giống `sendToUserTopic`.
- `NotificationService.createAndPush`: khi `shouldPush` là `false`, gọi `sendDataOnlyToUserTopic(userId, payload)` (payload vẫn có `type`), cũng chạy sau commit như nhánh hiện tại.
- App: `push_notification_service.dart` không được hiện local notification cho message không có `notification`. Hãy kiểm tra `_handleForegroundMessage`; nếu nó hiện thông báo từ `data` thì thêm điều kiện bỏ qua khi `message.notification == null`.

**Test (sửa `NotificationServiceTest`):** trong 2 test "skipped", thay `verify(fcm, never()).sendToUserTopic(...)` bằng: vẫn `never()` cho `sendToUserTopic` **và** `verify(fcm).sendDataOnlyToUserTopic(eq(7L), argThat(m -> "SETTLEMENT_PAID".equals(m.get("type"))))` (dùng type tương ứng của từng test).

## R2. `UserPreferencesNotifier`: lỗi sau khi rời màn và khi bấm hai công tắc liên tiếp (quan trọng)

**Lỗi 1:** provider là `autoDispose`. Nếu người dùng rời màn Cài đặt trong lúc đang lưu, đoạn `state = ...` chạy sau `await` sẽ ném `StateError`.

**Lỗi 2:** bấm hai công tắc nhanh liên tiếp. Nếu lần lưu đầu thất bại, state bị khôi phục về bản chụp cũ và xoá luôn thay đổi của lần lưu thứ hai. Kết quả: giao diện hiển thị khác với dữ liệu trên server.

**Sửa (`frontend/lib/features/profile/user_preferences.dart`):**
- Kiểm tra `if (!mounted) return ...;` trước **mọi** lần gán `state` sau một `await` (trong `load`, cả hai setter).
- Thêm `bool _saving = false;` và getter `bool get isSaving`. Nếu đang lưu thì setter trả về `false` ngay, không gọi repository.
- `settings_screen.dart`: tắt cả hai `SwitchListTile` (`onChanged: null`) khi `notifier.isSaving`. Vì `isSaving` không nằm trong state, hãy gọi `setState` ở màn hình trước và sau khi await setter.

**Test (thêm vào `user_preferences_test.dart`):**
- `'second toggle while saving is rejected'`: fake `save` chờ một `Completer`. Gọi setter thứ nhất (không await), gọi setter thứ hai → kết quả `false`, `fake.saveCount == 1`. Sau đó complete để dọn.
- `'no state write after dispose'`: fake `save` chờ `Completer`, gọi setter, `notifier.dispose()`, rồi complete → không có exception (dùng `expectLater(future, completes)`).

## R3. Lời chào Trang chủ luôn là "Bạn" (quan trọng, có từ trước nhưng sửa luôn)

**Lỗi:** `frontend/lib/features/home/dashboard_screen.dart:64` đọc `res.data['data']`, nhưng `GET /users/me` trả `UserDto` thô, không có envelope.

**Sửa:** đọc `res.data['fullName']` trực tiếp, giống `auth_repository.dart`. Không cần test tự động; kiểm tra bằng mắt.

## R4. Chỉ OWNER/ADMIN được sửa cài đặt nhóm

**Sửa:** trong `SettingsController.updateGroupSettings`, thay `requireActiveMember` bằng kiểm tra vai trò OWNER hoặc ADMIN. Dùng cùng cách `GroupServiceImpl` đang làm ở dòng ~91 (lấy `GroupMember`, so `getRole()`, ném `GroupPermissionException`). Nếu cần dùng chung thì thêm `requireAdmin(Long groupId, Long userId)` vào `GroupAccessService`. GET vẫn chỉ cần là thành viên.

**Test (`SettingsSecurityTest`):** `plainMember_cannotUpdateGroupSettings`: chủ nhóm thêm user B qua `POST /api/groups/{id}/members`, B gọi PUT → 403.

## R5. Trang chủ báo "chưa có nhóm" khi thực ra là tải lỗi

**Sửa:** trong `dashboard_screen.dart`, khi `groupsAsync.hasError`, hiển thị `ErrorState` (đã có ở `features/groups/widgets/error_state.dart`) kèm nút thử lại gọi lại fetch nhóm. Thẻ số dư thì hiện `—` thay cho `0 ₫`. Phải xử lý nhánh lỗi trước nhánh danh sách rỗng.

## R6. Dọn nhỏ

- `ExpenseServiceImpl.java:~324`: xoá biến `groupId` không còn dùng.
- `groups_screen.dart:5`: đổi import thành `'../../../core/theme/app_colors.dart'`.

## Không sửa (đã cân nhắc)

- Tổng số dư cộng lẫn nhiều loại tiền: `GroupModel` không có trường tiền tệ, và màn Cài đặt đã bỏ chỗ đổi tiền tệ nhóm, nên thực tế mọi nhóm đều là VND. Ghi lại là giới hạn đã biết.
- Hai request đồng thời cùng tạo bản ghi cài đặt mặc định: rất hiếm, để sau.

## Kiểm tra cuối

`cd api; .\mvnw.cmd test` và `cd frontend; flutter analyze; flutter test` đều PASS. Cập nhật `docs/PROGRESS.md`, báo lại danh sách commit.
