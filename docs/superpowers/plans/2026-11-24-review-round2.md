# Review vòng 2: push im lặng + màn Cài đặt mới

Review của Claude Code trên `32d11d9..2d822b8` (vòng 1 R1–R6 và Task 1–4 của plan giao diện).

Trạng thái hiện tại: `flutter test` 22/22 PASS, `flutter analyze` 0 error và 0 warning.

Áp dụng Global Constraints của các plan trước: TDD, không đụng `.env`, không push, mỗi mục một commit, mơ hồ thì hỏi.
**Không commit `frontend/android/gradle.properties`.** Đó là thay đổi riêng trên máy của chủ dự án.

## P1. Đánh dấu rõ push im lặng (quan trọng)

**Lỗi:** từ R1, khi người dùng tắt thông báo, backend gửi message chỉ có data. Nhưng service worker web (`frontend/web/firebase-messaging-sw.js:45`) lại biến đúng loại message này thành một thông báo hệ thống "Bạn có thông báo mới". Kết quả: người đã tắt thông báo vẫn bị làm phiền.

Trong khi đó, ở app, `push_notification_service.dart:106` bỏ qua mọi message không có `notification`, nên nhánh dự phòng đọc `data['title']` bên dưới không bao giờ chạy tới.

**Sửa:**
- `NotificationService`: khi gửi data-only, thêm `payload.put("silent", "true")`.
- `firebase-messaging-sw.js`: nếu `payload.data?.silent === 'true'` thì `return` và không hiện gì.
- `push_notification_service.dart`: chỉ `return` sớm khi `message.data['silent'] == 'true'`. Giữ nguyên nhánh dự phòng `data['title']/['body']`.

**Test:** trong `NotificationServiceTest`, các test "skipped" kiểm tra thêm `argThat(m -> "true".equals(m.get("silent")))`.

## P2. Push im lặng phải tới được iOS và không bị Android trì hoãn (quan trọng)

**Lỗi:** `FcmPushService.sendDataOnlyToToken` (~dòng 112) chỉ có token và data, thiếu cấu hình APNs. APNs sẽ không giao message này tới iPhone.

**Sửa:** khi build message data-only, thêm:
- `ApnsConfig`: header `apns-push-type: background`, `apns-priority: 5`, và `Aps` với `setContentAvailable(true)`.
- `AndroidConfig` với `setPriority(AndroidConfig.Priority.HIGH)`.

Dùng các lớp builder của `com.google.firebase.messaging` sẵn có trong firebase-admin, không thêm dependency.

**Test:** không có test tự động cho phần build message của FCM. Kiểm tra bằng mắt và ghi chú trong PROGRESS rằng cần thử trên iPhone thật khi build iOS.

## P3. `UserPreferencesNotifier`: phân biệt "bị bỏ qua" với "lưu lỗi"

**Lỗi 1:** khi đang lưu mà người dùng bấm lần nữa, setter trả `false`, và màn hình hiểu nhầm là lưu lỗi nên hiện SnackBar báo lỗi.

**Lỗi 2:** nếu `state.value` là `null` (đang tải hoặc tải lỗi), setter lấy giá trị mặc định rồi lưu đè lên cài đặt thật của người dùng.

**Sửa (`user_preferences.dart`):**
- Đổi kiểu trả về của hai setter thành `Future<bool?>`: `null` nghĩa là bị bỏ qua (đang lưu, hoặc `state.value == null`), `true` là lưu thành công, `false` là lưu lỗi.
- Khi `state.value == null`, trả `null` và không gọi repository.
- `notification_settings_screen.dart` chỉ hiện SnackBar lỗi khi kết quả `== false`.

**Test (`user_preferences_test.dart`):**
- Sửa test `'second toggle while saving is rejected'` để kỳ vọng `isNull`.
- Thêm `'toggle before load is ignored and does not save'`: notifier ở trạng thái error → `setNotifyOnSettlement(false)` trả `null` và `fake.saveCount == 0`.

## P4. Cài đặt nhóm: hai lỗi nhỏ

1. **Nút "Lưu" sáng sẵn khi chưa sửa gì.** `_isDirty` đang so text đã trim với giá trị gốc chưa trim. Sửa: trim cả hai phía (`widget.group.name.trim()`, `(widget.group.description ?? '').trim()`).
2. **Thành viên thường chỉ thấy dòng đầu của mô tả** vì `value` bị giới hạn 1 dòng. Sửa: ở chế độ chỉ xem, hiển thị mô tả bằng `subtitle` của `GroupedTile` (tối đa nhiều dòng), còn `value` để trống. Nếu `GroupedTile.subtitle` đang bị giới hạn số dòng thì cho phép tối đa 6 dòng.

**Test:** thêm vào `group_settings_screen_test.dart` (đang có sẵn trong working tree, commit cùng mục này):
- `'save disabled when name has trailing spaces but unchanged'`: group tên `'Du lịch '` → nút Lưu bị khoá.
- `'member sees full multi-line description'`: mô tả dài 3 câu → `find.textContaining('<câu thứ 3>')` tìm thấy.

## P5. Chỉ admin còn hoạt động mới được xoá nhóm (có từ trước)

**Lỗi:** `GroupServiceImpl.deleteGroup` (~dòng 118) chỉ kiểm tra vai trò, không kiểm tra trạng thái ACTIVE. Admin đã rời nhóm hoặc đã bị xoá khỏi nhóm vẫn xoá được cả nhóm.

**Sửa:** gọi `groupAccessService.requireAdmin(groupId, currentUserId)`, thay cho kiểm tra vai trò hiện tại.

**Test (MockMvc, theo mẫu `SettingsSecurityTest`):** `removedAdmin_cannotDeleteGroup`. Chủ nhóm thêm B với vai trò ADMIN (hoặc thêm rồi nâng quyền, theo cách test hiện có làm được), sau đó B rời nhóm bằng `DELETE /api/groups/{id}/members/me`. B gọi `DELETE /api/groups/{id}` → kỳ vọng 403. Nếu không có API nâng quyền admin thì dừng lại và hỏi.

## P6. Ảnh chụp màn hình

`screenshot_test.dart` tạo ảnh bằng font Ahem (chữ thành ô vuông), nên không dùng để review giao diện được. **Xoá `frontend/test/screenshot_test.dart` và `docs/screenshots/settings/*.png`.** Chủ dự án sẽ tự chụp trên điện thoại thật.

## Kiểm tra cuối

`cd api; .\mvnw.cmd test` và `cd frontend; flutter analyze; flutter test` đều PASS. Cập nhật `docs/PROGRESS.md` và báo lại danh sách commit.
