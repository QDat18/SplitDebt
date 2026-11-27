# Chat: polling thích ứng

**Mục tiêu:** khi nhóm đang trò chuyện, B thấy tin của A trong khoảng **1 giây** (hiện trung bình 2,2 giây, tệ nhất 4,9 giây). Khi nhóm im lặng, số request không tăng so với hiện tại.

**Số liệu gốc** (Claude Code đo ngày 2026-11-27, backend chạy trên máy với H2): server chỉ mất khoảng 31 ms (trung vị) để tin đi từ A sang B. Gần như toàn bộ độ trễ là do chờ chu kỳ polling 5 giây trong `group_chat_screen.dart`.

Áp dụng Global Constraints của `2026-11-25-group-chat.md`. **Chỉ sửa app, không sửa backend.** Không thêm dependency.

## Quy tắc

| Tình huống | Chu kỳ poll kế tiếp |
|---|---|
| Có "hoạt động" trong 30 giây gần nhất | **1 giây** |
| Không có hoạt động trong 30 giây | **5 giây** (như hiện tại) |
| Lần poll vừa rồi lỗi (mạng, 5xx) | **5 giây**, không dùng chu kỳ nhanh khi đang lỗi |
| App chạy nền, hoặc `removed == true` | Dừng poll (như hiện tại) |

**"Hoạt động"** là một trong các sự kiện sau:
- `refreshNewer` nhận được ít nhất 1 tin mới (của bất kỳ ai);
- chính mình gửi tin thành công;
- nhận push FCM `GROUP_MESSAGE` của nhóm đang mở;
- vừa mở màn chat, hoặc app vừa quay lại từ nền.

## T1. Hàm chính sách thuần

Tạo `lib/features/chat/chat_poll_policy.dart`:
```dart
const kChatFastPoll = Duration(seconds: 1);
const kChatSlowPoll = Duration(seconds: 5);
const kChatActiveWindow = Duration(seconds: 30);

Duration nextChatPollDelay({
  required DateTime now,
  required DateTime? lastActivity,
  required bool lastPollFailed,
});
```
- `lastPollFailed == true` → `kChatSlowPoll`.
- `lastActivity != null` và `now - lastActivity < kChatActiveWindow` → `kChatFastPoll`.
- Còn lại → `kChatSlowPoll`.

**Test (`test/chat_poll_policy_test.dart`):**
- `lastActivity` null → 5 giây.
- Hoạt động cách đây 10 giây → 1 giây; cách đây 29 giây → 1 giây; cách đây 30 giây → 5 giây.
- Hoạt động cách đây 1 giây nhưng `lastPollFailed` → 5 giây.

## T2. `refreshNewer` báo kết quả

Trong `chat_notifier.dart`, đổi `refreshNewer` thành `Future<RefreshResult>`. `RefreshResult` có `int newCount` và `bool failed`.
- Thành công: `newCount` = số tin trong danh sách trả về mà **trước đó chưa có** trong state (so theo `id`).
- Lỗi mạng hoặc 5xx: `failed = true`.
- 403: giữ cách xử lý `removed` hiện tại, trả `failed = true`.
- Bị bỏ qua vì đang chạy dở hoặc đang tải lần đầu: `newCount = 0`, `failed = false`.
- Nhánh gọi `loadInitial()` (C2): `failed` = `state.error != null` sau khi tải xong.

Các chỗ đang gọi `refreshNewer()` mà không dùng kết quả vẫn chạy được, không phải sửa.

**Test (`chat_notifier_test.dart`, repository giả):**
- `after` trả 2 tin mới → `newCount == 2`.
- `after` trả lại đúng tin đã có → `newCount == 0`.
- `after` ném lỗi → `failed == true`.

## T3. Màn chat dùng timer tự lên lịch

Trong `group_chat_screen.dart`:
- Thay `Timer.periodic(5s)` bằng **một `Timer` duy nhất tự lên lịch**: `_scheduleNextPoll()` huỷ timer cũ, rồi đặt timer mới với `nextChatPollDelay(...)`. Khi timer chạy: gọi `refreshNewer()`, cập nhật `_lastActivity` nếu `newCount > 0`, nhớ `failed`, rồi gọi lại `_scheduleNextPoll()`.
- Có một `_markActivity()` để đặt `_lastActivity = DateTime.now()` rồi lên lịch lại ngay. Gọi hàm này khi:
  - mở màn chat (thay cho `_startPolling()` trong `initState`);
  - app quay lại từ nền (`resumed`);
  - gửi tin thành công. Để làm được, `send` trả `Future<bool>`, hoặc màn chat nghe state thấy tin của mình chuyển sang `sent`; chọn cách đơn giản hơn;
  - nhận push `GROUP_MESSAGE` của nhóm này (vẫn gọi `refreshNewer()` ngay như hiện tại).
- Không bao giờ có 2 timer cùng lúc. App chạy nền, `removed`, hoặc `dispose` thì huỷ timer.
- Không đổi các phần khác của màn hình.

**Test (`group_chat_screen_test.dart`, dùng `tester.pump(duration)` và repository giả đếm số lần gọi `after`):**
- Mở màn chat, không có tin mới: trong 30 giây đầu poll khoảng mỗi 1 giây. Sau đó, trong 10 giây tiếp theo chỉ gọi `after` khoảng 2 lần (chu kỳ 5 giây).
- Đang ở chu kỳ chậm, repository trả 1 tin mới → lần poll kế tiếp sau 1 giây.
- `after` ném lỗi → lần kế tiếp sau 5 giây.
- Sau khi màn chat bị huỷ, không còn lần gọi `after` nào.

## Kiểm tra cuối

- `flutter analyze` 0 error. `flutter test -j 1` PASS.
- Mỗi mục (T1, T2, T3) một commit. Cập nhật `docs/PROGRESS.md`. Không push.
- **Kiểm thử thủ công** (nếu chạy được 2 máy ảo hoặc máy ảo cộng web): A gửi 5 tin liên tiếp, B thấy mỗi tin trong khoảng 1–2 giây. Để im 1 phút, rồi A gửi: B thấy trong tối đa khoảng 5 giây.
