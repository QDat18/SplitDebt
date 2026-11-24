# SplitDebt Progress Tracking

- **Status**: Hoàn thành Task 3 Nhắn tin nhóm; Đang thực hiện Task 4 (App — tầng dữ liệu và logic chat).
- **Done**:
  - Task 1: Backend lưu, gửi và lấy tin nhắn nhóm (REST API, idempotent với clientMessageId, phân trang cursor before/after, 8 test cases).
  - Task 2: Đánh dấu đã đọc (`markRead`), đếm số tin chưa đọc (`unreadMessageCount`), dọn dẹp tin nhắn khi xoá nhóm (13 test cases).
  - Task 3: Push tin mới qua FCM cho thành viên khác người gửi, tuỳ chọn tắt trong UserSetting (18 test cases).
  - Hoàn thiện luồng Mời/Tham gia nhóm bằng QR Code và Link mời nhóm.
- **Verification**:
  - Backend: 72/72 tests passed (`mvnw test`).
  - Frontend: 47/47 tests passed (`flutter test`).
- **In progress**: Task 4: App — tầng dữ liệu và logic chat (không UI): `ChatMessage`, `uuidV4`, `ChatRepository`, `mergeMessages`, `buildChatRows`, `ChatNotifier`.
- **Next**: Task 5: App — màn chat HIG, lối vào AppBar, badge số tin, push background/foreground.
- **Blockers**: Không có.
