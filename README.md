# SplitDebt

SplitDebt là ứng dụng quản lý chi tiêu nhóm và sổ công nợ theo tài liệu SRS/PTTKHT của Nhóm 8.


## UI reference v9 — Stitch Reference Complete

Frontend v9 sử dụng đầy đủ bộ Stitch reference **Luminous Depth** do người dùng cung cấp cho splash, auth, dashboard, group details, add expense, debts, smart settlement, history, profile và analytics. Logo runtime là **ảnh PNG gốc của reference**, không redraw bằng Flutter code. Xem `CHANGELOG_REFERENCE_COMPLETE_V9.md`. Logic nghiệp vụ v7/v6 được giữ nguyên.

## Kiến trúc

- `frontend/`: Flutter/Dart, Material 3, lưu JWT cục bộ bằng `shared_preferences`.
- `api/`: Java 17+, Spring Boot REST API, xác thực email/mật khẩu + Google Sign-In, quên mật khẩu bằng mã xác minh, JWT HMAC-SHA256, JDBC.
- Database: PostgreSQL (có thể dùng Supabase PostgreSQL như một PostgreSQL managed database). Local development có H2 PostgreSQL mode.
- Nghiệp vụ: nhóm + mã mời, OWNER/MEMBER, khoản chi, chia đều/số tiền/%/trọng số/theo món, công nợ, Smart Settlement, xác nhận thanh toán hai chiều, thông báo, thống kê và cài đặt.
- UI/UX: premium Material 3, light/dark/system, glass surface, 3D interaction nhẹ, feedback success/error/warning/info, chuyển tab/auth mượt và hướng dẫn nhanh 4 bước cho người mới.

## Bắt đầu nhanh

### Backend

```powershell
cd api
Copy-Item .env.example .env
.\mvnw.cmd spring-boot:run
```

Nếu không cấu hình `DB_URL`, backend dùng H2 local. Với PostgreSQL, điền `DB_URL`, `DB_USERNAME`, `DB_PASSWORD` và `JWT_SECRET` trong `api/.env`.

### Flutter

```powershell
cd frontend
flutter pub get
flutter run
```

Mặc định Flutter trỏ Android Emulator tới `http://10.0.2.2:8080/api`. Với điện thoại thật, chạy kèm `--dart-define=API_URL=http://<IP-LAN>:8080/api`.

Xem `docs/SETUP.md`, `docs/API.md`, `docs/DESIGN_SYSTEM.md`, `docs/UX_UI_UPGRADE.md` và `docs/AUTH_GOOGLE_PASSWORD_RESET.md` để biết chi tiết.

## Kiểm thử

Project có bộ kiểm thử tự động cho backend, thuật toán chia tiền/Smart Settlement, REST E2E, Flutter API/session, widget/form/onboarding/feedback, integration flow và build smoke.

Windows chạy toàn bộ:

```powershell
.\test-all.ps1
```

Chạy nhanh trong lúc code:

```powershell
.\test-all.ps1 -Fast
```

Chi tiết test case, coverage, E2E và checklist Android: [`docs/TESTING.md`](docs/TESTING.md).

### UX công nợ v7

Trang nhóm hiện phân biệt rõ số **còn phải trả**, **còn được nhận**, **đã thanh toán** và **đã nhận**. Khoản đã ghi nhận thanh toán được trừ khỏi số cần xử lý ngay để tránh trả lặp, nhưng vẫn giữ trạng thái **Chờ xác nhận** cho đến khi người nhận xác nhận. Trưởng nhóm có thể thêm thành viên bằng email/số điện thoại hoặc chia sẻ mã nhóm; khi thêm khoản chi mới, Trưởng nhóm là người trả mặc định và chi phí được chọn chia cho các thành viên còn lại.
