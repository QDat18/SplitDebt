# Chạy SplitDebt trong Android Studio

## 1. Yêu cầu

- JDK 17+.
- Android Studio + Flutter/Dart SDK.
- PostgreSQL nếu muốn chạy với database thật. Có thể dùng Supabase chỉ như dịch vụ PostgreSQL; app không còn phụ thuộc Supabase Auth.
- Internet cho lần tải Maven/Flutter dependency đầu tiên.

## 2. Backend

Tại `api/`:

```powershell
Copy-Item .env.example .env
```

Cấu hình PostgreSQL:

```properties
DB_URL=jdbc:postgresql://HOST:5432/postgres?sslmode=require
DB_USERNAME=postgres
DB_PASSWORD=...
JWT_SECRET=mot-chuoi-ngau-nhien-dai-va-bi-mat
JWT_TTL_HOURS=168
ALLOWED_ORIGIN_PATTERNS=http://localhost:*,http://127.0.0.1:*
```

Hoặc để trống `DB_URL` để dùng H2 local.

Chạy:

```powershell
.\mvnw.cmd spring-boot:run
```

macOS/Linux:

```bash
chmod +x mvnw
./mvnw spring-boot:run
```

Kiểm tra `http://localhost:8080/api/health`.

`schema.sql` tạo các bảng nếu chưa tồn tại và seed các danh mục mặc định. Nếu PostgreSQL của bạn đã có schema theo đề bài, `CREATE TABLE IF NOT EXISTS` không tạo lại bảng hiện hữu.

## 3. Flutter

API URL được cấu hình bằng Dart define để source ZIP không phải chứa file `.env` riêng tư. Nếu không truyền gì, ứng dụng tự chọn URL phù hợp:

- Flutter Web / desktop: `http://localhost:8080/api`
- Android Emulator: `http://10.0.2.2:8080/api`
- Điện thoại thật: phải truyền IP LAN của máy chạy backend, ví dụ `flutter run --dart-define=API_URL=http://192.168.1.10:8080/api`

Với Flutter Web, backend mặc định cho phép origin phát triển `http://localhost:*` và `http://127.0.0.1:*`, nên cổng ngẫu nhiên của `flutter run -d chrome` không bị CORS chặn.

Chạy:

```powershell
cd frontend
flutter pub get
flutter run
```

## 4. Luồng kiểm thử đề xuất

1. Đăng ký hai tài khoản A/B.
2. A tạo nhóm VND; kiểm tra mã mời.
3. B tham gia bằng mã hoặc A thêm B qua email.
4. A thêm khoản chi và thử lần lượt EQUAL / AMOUNT / PERCENT / WEIGHT / ITEM.
5. Kiểm tra tổng phần chia luôn bằng tổng khoản chi.
6. Mở tab công nợ và xem Smart Settlement.
7. Debtor đánh dấu đã thanh toán; creditor phải xác nhận trước khi số dư thay đổi.
8. Sửa/xóa khoản chi và kiểm tra công nợ được tính lại.
9. Kiểm tra thông báo, lịch sử và thống kê WEEK/MONTH/ALL.

## 5. Build/test

```powershell
# api
.\mvnw.cmd verify

# frontend
flutter analyze
flutter test
flutter build apk --debug
```

Trong môi trường bàn giao hiện tại không có Flutter SDK và Maven wrapper không thể tải dependency qua mạng, vì vậy các lệnh trên cần được chạy trên máy phát triển của bạn trước khi phát hành.

## 6. Nếu đăng ký/đăng nhập trên Chrome bị timeout

1. Xác nhận backend đang chạy trước:

```powershell
cd api
.\mvnw.cmd spring-boot:run
```

2. Mở `http://localhost:8080/api/health` trên Chrome. Phải thấy `SplitDebt API is running.`
3. Ở terminal khác chạy frontend:

```powershell
cd frontend
flutter run -d chrome
```

Flutter Web tự dùng `http://localhost:8080/api`. Nếu backend chạy cổng khác, truyền rõ URL, ví dụ:

```powershell
flutter run -d chrome --dart-define=API_URL=http://localhost:9090/api
```

Nếu health endpoint không mở được thì lỗi nằm ở backend/database, không phải DDS của Flutter.

## Google Sign-In / Forgot Password

Backend `.env`:

```properties
GOOGLE_CLIENT_ID=xxxxxxxx.apps.googleusercontent.com
PASSWORD_RESET_TTL_MINUTES=10
PASSWORD_RESET_DEV_RETURN_CODE=true
# SMTP optional for local, required for real email delivery
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your-email@gmail.com
SMTP_PASSWORD=your-app-password
MAIL_FROM=your-email@gmail.com
SMTP_STARTTLS=true
```

Flutter Web example:

```powershell
flutter run -d chrome --web-port=5000 --dart-define=API_URL=http://localhost:8080/api --dart-define=GOOGLE_WEB_CLIENT_ID=xxxxxxxx.apps.googleusercontent.com
```

For production, set `PASSWORD_RESET_DEV_RETURN_CODE=false`. See `AUTH_GOOGLE_PASSWORD_RESET.md` for Google Cloud origins, Android OAuth package/SHA and SMTP details.
