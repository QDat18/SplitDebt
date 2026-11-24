# SplitDebt Progress Tracking

- **Status**: Hoàn thành Task 5 Nhắn tin nhóm; Đang thực hiện Task 6 (App — công tắc "Tin nhắn nhóm" trong cài đặt thông báo).
- **Done**:
  - Task 1: Backend lưu, gửi và lấy tin nhắn nhóm (REST API, idempotent với clientMessageId, phân trang cursor before/after, 8 test cases).
  - Task 2: Đánh dấu đã đọc (`markRead`), đếm số tin chưa đọc (`unreadMessageCount`), dọn dẹp tin nhắn khi xoá nhóm (13 test cases).
  - Task 3: Push tin mới qua FCM cho thành viên khác người gửi, tuỳ chọn tắt trong UserSetting (18 test cases).
  - Task 4: App — tầng dữ liệu và logic chat: `ChatMessage`, `uuidV4`, `ChatRepository`, `mergeMessages`, `buildChatRows`, `ChatNotifier` (10 test cases).
  - Task 5: App — màn chat `GroupChatScreen` HIG, lối vào AppBar, badge số tin chưa đọc trên card và chi tiết nhóm, suppress push foreground khi đang chat (62 test cases).
- **Verification**:
  - Backend: 72/72 tests passed (`mvnw test`).
  - Frontend: 62/62 tests passed (`flutter test`).
- **In progress**: Task 6: App — công tắc "Tin nhắn nhóm" trong cài đặt thông báo.
- **Next**: Hoàn thành toàn bộ kế hoạch 6 tasks và nghiệm thu.
- **Blockers**: Không có.
