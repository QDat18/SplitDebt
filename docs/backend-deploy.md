# Hướng dẫn Deploy Backend SplitDebt lên Render (HTTPS miễn phí)

Tài liệu này hướng dẫn từng bước đưa backend Spring Boot lên Render (gói Free dùng Docker) tại URL `https://<tên>.onrender.com/api`, sử dụng lại database PostgreSQL managed (Supabase).

---

## 1. Chuẩn bị secret cho production

> **Quan trọng:** Tạo `JWT_SECRET` **mới** cho production (không dùng lại giá trị trong `.env` trên máy dev). Khi đổi `JWT_SECRET`, mọi phiên đăng nhập cũ sẽ hết hạn.

Chạy lệnh PowerShell sau để tạo `JWT_SECRET` ngẫu nhiên:

```powershell
$b = New-Object byte[] 48; [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($b); [Convert]::ToBase64String($b)
```

---

## 2. Bảng biến môi trường trên Render

| Tên biến | Ý nghĩa | Lấy ở đâu |
|---|---|---|
| `DB_URL` | Chuỗi kết nối PostgreSQL JDBC (có `sslmode=require`) | Supabase → **Connect** → **Session pooler** → dạng JDBC (`jdbc:postgresql://...`) |
| `DB_USERNAME` | Tên đăng nhập database (Session pooler) | Supabase → **Connect** → **Session pooler** |
| `DB_PASSWORD` | Mật khẩu database | Mật khẩu project Supabase |
| `JWT_SECRET` | Khoá ký JWT cho production | Tạo mới bằng lệnh PowerShell ở mục 1 |
| `SUPABASE_KEY` | Service/API key để upload avatar | Supabase → **Project Settings** → **API** |
| `JWT_EXPIRATION_MS` | Thời hạn JWT (ms), mặc định `86400000` (24 giờ) | Đã đặt sẵn trong `render.yaml` |
| `FIREBASE_ENABLED` | Bật/tắt gửi push FCM (`true`) | Đã đặt sẵn trong `render.yaml` |
| `GOOGLE_APPLICATION_CREDENTIALS` | Đường dẫn Secret File Firebase Admin | Đã đặt sẵn `/etc/secrets/firebase-service-account.json` |
| `DB_POOL_MAX` | Số kết nối tối đa Hikari (`5` cho gói free) | Đã đặt sẵn trong `render.yaml` |
| `DB_POOL_MIN_IDLE` | Số kết nối nhàn rỗi tối thiểu (`1`) | Đã đặt sẵn trong `render.yaml` |
| `SWAGGER_ENABLED` | Tắt Swagger trên production (`false`) | Đã đặt sẵn trong `render.yaml` |
| `CORS_ALLOWED_ORIGINS` | Origin web được phép gọi API | Đã đặt sẵn trong `render.yaml` |

*(Lưu ý: Nếu database Supabase ở region khác Singapore, hãy sửa `region` trong `render.yaml` trước khi tạo Blueprint.)*

---

## 3. Tạo service trên Render bằng Blueprint

1. Merge code vào nhánh mà `render.yaml` trỏ tới (`main`, hoặc đổi `branch` sang `dev2-dat` khi demo) rồi **push lên GitHub**.
2. Truy cập [render.com](https://render.com) → **New** → **Blueprint** → chọn repository `SplitDebt`.
3. Render sẽ đọc `render.yaml` ở gốc repo và hỏi các biến có `sync: false`: điền `DB_URL`, `DB_USERNAME`, `DB_PASSWORD`, `JWT_SECRET`, `SUPABASE_KEY`.

---

## 4. Thêm Secret File Firebase Admin

1. Trong Firebase Console → **Project Settings** → **Service accounts** → **Generate new private key** để tải file JSON.
2. Trên Render, mở service `splitdebt-api` → **Environment** → **Secret Files** → **Add Secret File**:
   - **Filename:** phải đặt đúng tên `firebase-service-account.json` (Render tự mount vào `/etc/secrets/firebase-service-account.json`).
   - **Contents:** dán nội dung file JSON vừa tải.
3. Nếu chưa thêm file này, backend vẫn chạy bình thường, chỉ tắt tính năng gửi push notification.

---

## 5. Kiểm tra sau khi deploy

1. Chờ Render build và deploy xong, mở trình duyệt kiểm tra:
   `https://<tên>.onrender.com/api/health`
2. Chạy script smoke test từ gốc repo:
   ```powershell
   .\api\tool\smoke_deploy.ps1 -BaseUrl https://<tên>.onrender.com/api
   ```

---

## 6. Giữ server thức (gói Free)

- Gói Free của Render sẽ đưa server vào trạng thái ngủ sau **15 phút** không có request; lần gọi tiếp theo mất khoảng 1 phút để khởi động lại.
- Tạo một monitor miễn phí trên **UptimeRobot** hoặc **cron-job.org** gọi `GET https://<tên>.onrender.com/api/health` mỗi **10 phút** để giữ server luôn sẵn sàng.

---

## 7. Xem log, deploy lại và rollback trên Render

- **Xem log:** vào service `splitdebt-api` → tab **Logs** để theo dõi log khởi động Spring Boot và request lỗi.
- **Deploy lại:** nhấn **Manual Deploy** → **Deploy latest commit** (hoặc push commit mới lên nhánh đã cấu hình khi `autoDeploy: true`).
- **Rollback:** vào tab **Events** (hoặc **Deploys**), chọn bản deploy ổn định trước đó và nhấn **Rollback to this deploy**.

---

## 8. Build APK với URL production

Sau khi backend hoạt động ở URL `https://<tên>.onrender.com/api`, đứng ở thư mục `frontend` và chạy:

```powershell
.\tool\build_apk.ps1 -ApiBaseUrl https://<tên>.onrender.com/api
```

Sau đó cài APK lên điện thoại và kiểm tra theo danh sách trong `docs/android-release.md`.

