# SplitDebt

SplitDebt là ứng dụng quản lý chi tiêu nhóm và sổ công nợ theo tài liệu SRS/PTTKHT của Nhóm 8.


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

