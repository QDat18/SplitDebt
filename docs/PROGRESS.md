# SplitDebt Progress Tracking

- **Status**: Hoàn thành Task 4 Nhắn tin nhóm; Đang thực hiện Task 5 (App — màn chat, lối vào, badge, push).
- **Done**:
  - Task 1: Backend lưu, gửi và lấy tin nhắn nhóm (REST API, idempotent với clientMessageId, phân trang cursor before/after, 8 test cases).
  - Task 2: Đánh dấu đã đọc (`markRead`), đếm số tin chưa đọc (`unreadMessageCount`), dọn dẹp tin nhắn khi xoá nhóm (13 test cases).
  - Task 3: Push tin mới qua FCM cho thành viên khác người gửi, tuỳ chọn tắt trong UserSetting (18 test cases).
  - Task 4: App — tầng dữ liệu và logic chat: `ChatMessage`, `uuidV4`, `ChatRepository`, `mergeMessages`, `buildChatRows`, `ChatNotifier` (10 test cases).
  - Thêm constructor 11 tham số cho `GroupResponseDto` bảo đảm tương thích ngược.
- **Verification**:
  - Backend: 72/72 tests passed (`mvnw test`).
  - Frontend: 57/57 tests passed (`flutter test`).
- **In progress**: Task 5: App — màn chat HIG, lối vào AppBar, badge số tin, push background/foreground.
- **Next**: Task 6: App — công tắc "Tin nhắn nhóm" trong cài đặt thông báo.
- **Blockers**: Không có.
