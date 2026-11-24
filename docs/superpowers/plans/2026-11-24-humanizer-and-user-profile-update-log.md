# Kế hoạch Triển khai: Humanizer UI & Tính năng Cập nhật Thông tin User kèm Nhật ký Hoạt động

**Mục tiêu:**
1. **Humanizer UI**: Loại bỏ toàn bộ từ ngữ và biểu tượng mang tính chất "AI / robot / thuật toán cồng kềnh" (như icon `Icons.auto_awesome`, nhãn "Min-Cash-Flow", "SplitDebt Ledger", "Tối ưu hóa nợ"), thay bằng ngôn từ gần gũi, sòng phẳng, đời thường và biểu tượng thanh toán/tài chính thực tế.
2. **Cập nhật thông tin User & Lưu nhật ký (Audit Log)**:
   - Backend: Cung cấp API `PUT /api/users/me` cập nhật Họ và tên (`fullName`), Số điện thoại (`phone`).
   - Lưu trữ nhật ký thay đổi (`user_activity_logs`) khi đổi thông tin cá nhân và khi đổi ảnh đại diện.
   - Cung cấp API `GET /api/users/me/logs` để truy xuất lịch sử thay đổi thông tin.
   - Frontend: Màn hình `PersonalInfoScreen` cho phép chỉnh sửa thông tin, lưu cập nhật, và xem danh sách nhật ký hoạt động chuẩn Apple HIG.

---

## Danh sách Task

### Task 1: Humanizer giao diện (Frontend)
- [ ] `frontend/lib/features/home/dashboard_screen.dart`:
  - Đổi `'SplitDebt Ledger'` -> `'Sổ tay chi tiêu nhóm'`.
  - Nút hành động Quyết toán: Đổi icon `Icons.auto_awesome_rounded` thành `Icons.payments_outlined`, đổi subtitle `'Tối ưu hóa nợ'` thành `'Tính tiền phải trả'`.
  - Nút Tạo chi tiêu: Đổi subtitle `'Chia tiền tự động'` thành `'Nhập chi tiêu mới'`.
  - Thẻ số dư: Đổi nhãn `'TỔNG SỐ DƯ RÒNG'` thành `'TỔNG TIỀN CẦN THU / TRẢ'`, tag trạng thái thành `'Cần thu về'` / `'Cần trả lại'` / `'Không còn nợ'`.
- [ ] `frontend/lib/features/expenses/create_expense_screen.dart`:
  - Đổi icon `Icons.auto_awesome` thành `Icons.document_scanner_outlined`, nhãn `'Quét hoá đơn'`.
- [ ] `frontend/lib/features/profile/help_screen.dart`:
  - Đổi icon `Icons.auto_awesome_outlined` thành `Icons.swap_horiz_rounded`.
  - Đổi tiêu đề thành `'3. Cân bằng tiền sòng phẳng'` và mô tả: `'Gom các khoản nợ chéo để bạn chỉ cần chuyển tiền ít lần nhất.'`.

### Task 2: Backend - Thực thể, Repository & DTO Nhật ký hoạt động
- [ ] `UserActivityLog.java` trong `api/src/main/java/com/splitdebt/api/entity/`:
  - Các trường: `id`, `userId`, `action`, `description`, `oldValue`, `newValue`, `createdAt`.
- [ ] `UserActivityLogRepository.java` trong `api/src/main/java/com/splitdebt/api/repository/`:
  - `List<UserActivityLog> findByUserIdOrderByCreatedAtDesc(Long userId)`.
- [ ] DTOs:
  - `UpdateProfileRequest.java` trong `api/src/main/java/com/splitdebt/api/dto/request/`: `fullName` (NotBlank, max 100), `phone` (max 20).
  - `UserActivityLogDto.java` trong `api/src/main/java/com/splitdebt/api/dto/response/`: `id`, `action`, `description`, `oldValue`, `newValue`, `createdAt`.

### Task 3: Backend - Service & Controller xử lý Cập nhật & Ghi log
- [ ] `UserService.java` & `UserServiceImpl.java` trong `api/src/main/java/com/splitdebt/api/service/`:
  - `updateProfile(String email, UpdateProfileRequest request)`: So sánh giá trị cũ & mới, lưu nhật ký nếu có thay đổi.
  - `getUserLogs(String email)`: Trả về danh sách nhật ký sắp xếp mới nhất.
  - `logActivity(Long userId, String action, String description, String oldValue, String newValue)`: Hàm ghi nhận nhật ký dùng chung.
- [ ] `UserController.java`:
  - Thêm endpoint `PUT /api/users/me`.
  - Thêm endpoint `GET /api/users/me/logs`.
  - Cập nhật endpoint `POST /api/users/me/avatar` để tự động ghi log `UPDATE_AVATAR`.
- [ ] Unit & Controller Tests:
  - `UserServiceTest.java` & cập nhật `UserAvatarControllerTest.java` / `UserControllerTest.java`.

### Task 4: Frontend - Repository & Màn hình Cập nhật Thông tin kèm Nhật ký
- [ ] `frontend/lib/data/repositories/user_repository.dart`:
  - `updateProfile({required String fullName, String? phone})`
  - `getUserLogs()`
- [ ] `frontend/lib/features/profile/personal_info_screen.dart`:
  - Form chỉnh sửa `fullName` và `phone` với phong cách iOS Inset Grouped.
  - Nút "Lưu" trên AppBar và nút "Lưu thay đổi".
  - Section "Nhật ký hoạt động": Hiển thị danh sách các lần cập nhật (mô tả, thời gian `dd/MM/yyyy HH:mm`, icon trực quan).
- [ ] `frontend/lib/features/profile/profile_screen.dart`:
  - Nhận callback khi thông tin cá nhân cập nhật để đồng bộ tên người dùng.

### Task 5: Kiểm thử toàn diện & Cập nhật Tiến độ
- [ ] Backend: `.\mvnw.cmd test`
- [ ] Frontend: `flutter analyze` & `flutter test`
- [ ] Cập nhật `docs/PROGRESS.md`

