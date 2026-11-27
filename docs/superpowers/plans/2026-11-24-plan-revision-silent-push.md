# Điều chỉnh plan: bỏ "push im lặng", màn hình tự làm mới định kỳ

Đã đủ 3 vòng review/sửa (R1 → P1/P2 → review vòng 3). Theo quy tắc, chuỗi này không vá tiếp mà đổi thiết kế.

## Vì sao bỏ push im lặng

Mục đích ban đầu: khi người dùng tắt thông báo, màn quyết toán và màn thông báo vẫn tự cập nhật. Mỗi vòng sửa lại lộ ra một vấn đề nền tảng mới:

- **Web:** Chrome bắt buộc mỗi push phải hiện thông báo (`userVisibleOnly`). Push mà không hiện gì thì Chrome tự hiện "This site has been updated in the background".
- **Android:** gửi push ưu tiên cao (HIGH) mà không hiện thông báo thì FCM sẽ hạ ưu tiên của app, làm chậm cả các thông báo thật.
- **iOS:** thiếu `UIBackgroundModes/remote-notification` nên push nền không tới được app. Thêm vào thì lại phải xử lý thêm phần entitlement.

Trong khi đó, cả hai màn **đã tự tải lại khi app quay lại foreground và khi kéo để làm mới**. Phần còn thiếu chỉ là trường hợp đang mở màn hình đúng lúc người khác thao tác. Trường hợp này giải quyết bằng làm mới định kỳ thì đơn giản hơn nhiều.

## Việc cần làm

Áp dụng Global Constraints của các plan trước (TDD khi có logic, không `.env`, không push, mỗi mục một commit, mơ hồ thì hỏi). **Không commit `frontend/android/gradle.properties`.**

### V1. Gỡ push im lặng (backend + app + web)

- `NotificationService.createAndPush`: khi `shouldPush` là `false` thì **không gửi gì**. Vẫn lưu bản ghi `Notification` như trước. Xoá nhánh gọi `sendDataOnlyToUserTopic` và key `silent`.
- `FcmPushService`: xoá `sendDataOnlyToUserTopic` / `sendDataOnlyToToken` cùng phần cấu hình APNs/Android đi kèm (thêm ở commit `d77de42`, `f416380`).
- `firebase-messaging-sw.js`: bỏ nhánh `silent`. Nếu `payload.notification` có thì return (FCM tự hiện); nếu không thì hiện từ `data.title/body`, giống trước commit `922a483`.
- `push_notification_service.dart`: early return quay về điều kiện `message.notification == null && message.data['title'] == null`.
- **Test:** trong `NotificationServiceTest`, 2 test "skipped" quay về `verify(fcm, never()).sendToUserTopic(...)` và **`verifyNoMoreInteractions(fcm)`**. Bản ghi `Notification` vẫn được `save`.

### V2. Làm mới định kỳ khi màn hình đang hiển thị

- Tạo `frontend/lib/core/utils/visible_poller.dart`:
  ```dart
  class VisiblePoller {
    VisiblePoller({required this.interval, required this.onTick});
    final Duration interval; final Future<void> Function() onTick;
    void start(); void stop(); void onLifecycle(AppLifecycleState s);
    // resumed → start, mọi trạng thái khác → stop. Không chạy tick chồng: nếu tick trước chưa xong thì bỏ qua.
  }
  ```
- `live_settlement_screen.dart` và `notification_screen.dart`:
  - Tạo `VisiblePoller(interval: const Duration(seconds: 20), onTick: _load)`.
  - Gọi `start()` trong `initState`, `stop()` trong `dispose`.
  - Chuyển trạng thái lifecycle sang `onLifecycle` trong `didChangeAppLifecycleState` đã có.
  - **Giữ** listener `onMessage` hiện tại: push thật vẫn kích hoạt làm mới ngay lập tức.
- **Test (`frontend/test/visible_poller_test.dart`, dùng `fake_async` có sẵn trong `flutter_test`):**
  - `'ticks every interval while resumed'`: sau `start()`, `elapse(61s)` → onTick được gọi 3 lần.
  - `'stops when paused and resumes'`: `onLifecycle(paused)`, `elapse(60s)` → 0 lần; `onLifecycle(resumed)`, `elapse(21s)` → 1 lần.
  - `'skips overlapping ticks'`: onTick chờ một `Completer` chưa complete, `elapse(60s)` → chỉ 1 lần gọi.

### V3. Sửa test và các chỗ nhỏ từ review vòng 3

- `SettingsSecurityTest.removedAdmin_cannotDeleteGroup`: đang pass vì sai lý do (`leaveGroup` xoá hẳn bản ghi thành viên). Sửa: đặt trạng thái của B thành `INACTIVE` qua `GroupMemberRepository` (giữ vai trò ADMIN), rồi B gọi DELETE → kỳ vọng 403.
- `GroupAccessService.requireAdmin`: đổi thông báo thành chung chung: "Chỉ trưởng nhóm hoặc quản trị viên mới thực hiện được thao tác này".
- `GroupServiceImpl.updateGroup`, `addGroupMember`, `removeMember`: cũng dùng `groupAccessService.requireAdmin(...)` thay cho kiểm tra vai trò thủ công.
- `GroupedTile`: thêm tham số `int? subtitleMaxLines` (mặc định `null`, tức không giới hạn). Bỏ giới hạn cứng 6 dòng.
- `group_settings_screen.dart`: ở chế độ chỉ xem, coi mô tả là trống khi `description?.trim().isEmpty != false` và hiển thị bản đã trim.

## Kiểm tra cuối

`cd api; .\mvnw.cmd test` và `cd frontend; flutter analyze; flutter test` đều PASS. Cập nhật `docs/PROGRESS.md` (ghi rõ đã bỏ push im lặng và lý do), báo lại danh sách commit.

Sau bước này, Claude Code review **một lần cuối**. Nếu vẫn còn lỗi, sẽ xử lý trong plan mới, không mở thêm vòng vá.
