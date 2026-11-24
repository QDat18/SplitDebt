# SplitDebt Progress Tracking

- **Status**: Hoàn thành toàn bộ 6 Tasks tính năng Nhắn tin nhóm (Group Chat).
- **Done**:
  - Task 1: Backend lưu, gửi và lấy tin nhắn nhóm (REST API, idempotent clientMessageId, phân trang cursor, 8 tests).
  - Task 2: Đánh dấu đã đọc (`markRead`), đếm số tin chưa đọc (`unreadMessageCount`), dọn dẹp tin nhắn khi xoá nhóm (13 tests).
  - Task 3: Push tin mới qua FCM cho thành viên khác người gửi, tuỳ chọn tắt trong UserSetting (18 tests).
  - Task 4: App — tầng dữ liệu và logic chat: `ChatMessage`, `uuidV4`, `ChatRepository`, `mergeMessages`, `buildChatRows`, `ChatNotifier` (10 tests).
  - Task 5: App — màn chat `GroupChatScreen` HIG, lối vào AppBar, badge số tin chưa đọc trên card/chi tiết nhóm, suppress push foreground khi đang chat.
  - Task 6: App — công tắc "Tin nhắn nhóm" trong cài đặt thông báo, lưu trữ qua `UserPreferences` (64 tests).
  - Khắc phục lỗi tương thích constructor `GroupResponseDto`.
- **Verification**:
  - Backend: 72/72 tests passed (`mvnw test`).
  - Frontend: 64/64 tests passed (`flutter test`).
- **In progress**: Hoàn tất bàn giao và hướng dẫn người dùng.
- **Next**: Khởi động lại backend server để áp dụng các thay đổi mới nhất.
- **Blockers**: Không có.
