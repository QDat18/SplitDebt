# SplitDebt Progress Tracking

- **Status**: Hoàn thiện toàn diện luồng Mời/Tham gia nhóm bằng QR & Link; sẵn sàng kế hoạch Nhắn tin nhóm.
- **Done**:
  - Xác minh logic thêm thành viên: Email bắt buộc phải tồn tại trong CSDL, trả về lỗi 404 rõ ràng nếu chưa đăng ký.
  - Hoàn thiện luồng QR Code & Link mời nhóm:
    - `groups_screen.dart`: Thêm nút "Tham gia nhóm" trên AppBar mở `JoinGroupDialog` (tự động nhận diện link/mã).
    - `group_detail_screen.dart`: Thêm nút "Mã QR & Link" trên AppBar và trong tab Thành viên mở `GroupInviteDialog`.
  - Phân tích và phác thảo thiết kế tính năng Nhắn tin nhóm (Group Chat).
- **Verification**:
  - Frontend: 47/47 tests passed (`flutter test`).
  - Frontend analyze: 0 errors, 0 warnings (`flutter analyze`).
  - Backend: 8/8 tests passed (`mvnw test`).
- **In progress**: Trao đổi và lên kế hoạch triển khai tính năng Nhắn tin nhóm (Group Chat).
- **Next**: Triển khai API và giao diện Chat nhóm nếu người dùng duyệt.
- **Blockers**: Không có.
