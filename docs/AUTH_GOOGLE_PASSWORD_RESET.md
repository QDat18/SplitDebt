# Google Sign-In + Quên mật khẩu

Bản cập nhật này bổ sung hai luồng xác thực mới cho SplitDebt và giữ nguyên đăng nhập email/mật khẩu + JWT hiện có.

## 1. Google Sign-In

### Backend

Backend nhận `idToken` từ Flutter tại:

```text
POST /api/auth/google
```

Backend xác minh Google ID token, kiểm tra audience bằng `GOOGLE_CLIENT_ID`, kiểm tra email đã được Google xác minh, sau đó:

- tìm liên kết trong `user_identities` theo `provider=GOOGLE` + Google subject;
- nếu chưa có, liên kết với tài khoản SplitDebt có cùng email đã xác minh;
- nếu email chưa tồn tại, tạo user mới;
- phát hành JWT SplitDebt như luồng đăng nhập thường.

`.env` backend:

```properties
GOOGLE_CLIENT_ID=xxxxxxxx.apps.googleusercontent.com
```

Dùng **Web OAuth 2.0 Client ID** cho `GOOGLE_CLIENT_ID` vì đây cũng là audience/server client ID mà Android gửi về Backend.

### Flutter Web

Chạy Web ở một port cố định để cấu hình Google Cloud dễ dàng:

```powershell
flutter run -d chrome --web-port=5000 `
  --dart-define=API_URL=http://localhost:8080/api `
  --dart-define=GOOGLE_WEB_CLIENT_ID=xxxxxxxx.apps.googleusercontent.com
```

Trong Google Cloud Console, Web OAuth Client cần Authorized JavaScript origin tương ứng, ví dụ:

```text
http://localhost:5000
https://your-production-domain.example
```

### Android

Flutter dùng cùng Web Client ID làm `serverClientId`:

```powershell
flutter run -d <android-device> `
  --dart-define=API_URL=http://10.0.2.2:8080/api `
  --dart-define=GOOGLE_WEB_CLIENT_ID=xxxxxxxx.apps.googleusercontent.com
```

Trong Google Cloud cần tạo thêm Android OAuth Client cho package hiện tại:

```text
com.example.split_debt
```

và khai báo SHA-1/SHA-256 của keystore debug/release đúng với môi trường chạy.

## 2. Quên mật khẩu

Luồng mới:

```text
Login
  → Quên mật khẩu?
  → nhập email
  → POST /api/auth/forgot-password
  → nhận mã 6 chữ số qua email
  → nhập mã + mật khẩu mới
  → POST /api/auth/reset-password
  → đăng nhập bằng mật khẩu mới
```

Backend chỉ lưu **SHA-256 hash** của mã reset trong `password_reset_tokens`. Mã có hạn sử dụng, dùng một lần và bị vô hiệu sau nhiều lần nhập sai.

### SMTP

Ví dụ Gmail SMTP:

```properties
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your-email@gmail.com
SMTP_PASSWORD=your-google-app-password
MAIL_FROM=your-email@gmail.com
SMTP_STARTTLS=true
PASSWORD_RESET_TTL_MINUTES=10
```

Nên dùng Google App Password, không dùng mật khẩu Gmail chính.

### Chế độ local/dev

Nếu chưa muốn cấu hình SMTP, có thể cho Backend trả mã reset trong JSON để test local:

```properties
PASSWORD_RESET_DEV_RETURN_CODE=true
```

Flutter sẽ tự điền mã và hiển thị cảnh báo DEV mode.

**Không bật tùy chọn này ở staging/production.** Production nên để:

```properties
PASSWORD_RESET_DEV_RETURN_CODE=false
```

## 3. Animation và chuyển tab

- Login ↔ Home dùng fade + slide + scale nhẹ.
- Login → Đăng ký / Quên mật khẩu dùng `SmoothPageRoute` 360 ms.
- Form quên mật khẩu dùng `AnimatedSwitcher` giữa các bước nhập email → nhập mã → thành công.
- Home NavigationBar dùng `AnimatedSwitcher` fade + slide 320 ms khi đổi Tổng quan / Nhóm / Lịch sử / Cá nhân.
- Chuyển tab có `HapticFeedback.selectionClick()` trên nền tảng hỗ trợ.
- Tất cả animation chính tôn trọng `MediaQuery.disableAnimationsOf(context)`.

## 4. Endpoint mới

```text
POST /api/auth/google
POST /api/auth/forgot-password
POST /api/auth/reset-password
```

Bảng mới:

```text
user_identities
password_reset_tokens
```

## 5. Kiểm thử

Backend contract test đã bổ sung luồng:

```text
register
→ forgot-password
→ reset-password
→ mật khẩu cũ bị từ chối
→ mật khẩu mới đăng nhập thành công
```

Flutter API test bổ sung request/reset password contract. Sau khi cấu hình dependency mới, chạy:

```powershell
cd frontend
flutter clean
flutter pub get
flutter test
```

và backend:

```powershell
cd api
.\mvnw.cmd test
```
