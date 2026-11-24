# SplitDebt Progress Tracking

- **Status**: Hoàn thành cơ chế Xem/Sửa thông tin cá nhân và đánh giá tính năng QR/Link mời nhóm.
- **Done**:
  - Humanizer UI: Thay đổi toàn bộ icon AI và thuật ngữ máy móc sang ngôn ngữ đời thường.
  - Backend User Update & Activity Log: `UserActivityLog`, `UserService`, `PUT /api/users/me`, `GET /api/users/me/logs`. Tests 51/51 passed.
  - Profile Update UI (Apple HIG):
    - Chế độ Mặc định: Hiển thị thông tin dạng thẻ Inset Grouped gọn gàng, nút "Sửa" trên AppBar góc phải và "Chỉnh sửa" bên dưới.
    - Chế độ Sửa (khi bấm nút): Mở ô nhập liệu `TextField`, nút "Huỷ" và "Lưu", tự động lưu và ghi nhận vào Nhật ký tài khoản.
- **Verification**:
  - Backend: 51/51 tests passed (`mvnw test`).
  - Frontend: 40/40 tests passed (`flutter test`).
- **In progress**: Đánh giá & chuẩn bị giải pháp Link mời / Mã QR cho nhóm.
- **Next**: Triển khai tính năng Mã mời / QR Code tham gia nhóm nếu được người dùng duyệt.
- **Blockers**: Không có.
