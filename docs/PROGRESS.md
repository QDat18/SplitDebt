# SplitDebt Progress Tracking

- **Status**: Hoàn thành Task 1 Nhắn tin nhóm; Đang thực hiện Task 2 (Đánh dấu đã đọc, đếm tin chưa đọc, xoá nhóm).
- **Done**:
  - Task 1: Backend lưu, gửi và lấy tin nhắn nhóm (REST API, idempotent với clientMessageId, phân trang cursor before/after, TDD 8 test cases).
  - Hoàn thiện luồng Mời/Tham gia nhóm bằng QR Code và Link mời nhóm.
- **Verification**:
  - Backend: 62/62 tests passed (`mvnw test`).
  - Frontend: 47/47 tests passed (`flutter test`).
- **In progress**: Task 2: Backend — đánh dấu đã đọc, đếm tin chưa đọc, xoá nhóm (`GroupMember.lastReadMessageId`, `GroupResponseDto.unreadMessageCount`).
- **Next**: Task 3: Push tin mới qua FCM và tuỳ chọn tắt trong cài đặt.
- **Blockers**: Không có.
