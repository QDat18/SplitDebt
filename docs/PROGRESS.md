# SplitDebt Progress Tracking

- **Status**: Hoàn thành Task 2 Nhắn tin nhóm; Đang thực hiện Task 3 (Push tin mới & tuỳ chọn tắt).
- **Done**:
  - Task 1: Backend lưu, gửi và lấy tin nhắn nhóm (REST API, idempotent với clientMessageId, phân trang cursor before/after, 8 test cases).
  - Task 2: Đánh dấu đã đọc (`markRead`), đếm số tin chưa đọc (`unreadMessageCount`), dọn dẹp tin nhắn khi xoá nhóm (13 test cases).
  - Hoàn thiện luồng Mời/Tham gia nhóm bằng QR Code và Link mời nhóm.
- **Verification**:
  - Backend: 67/67 tests passed (`mvnw test`).
  - Frontend: 47/47 tests passed (`flutter test`).
- **In progress**: Task 3: Backend — push tin mới qua FCM và tuỳ chọn tắt trong cài đặt (`GroupChatPushService`, `UserSetting.notifyOnGroupMessage`).
- **Next**: Task 4: App — tầng dữ liệu và logic chat (không UI).
- **Blockers**: Không có.
