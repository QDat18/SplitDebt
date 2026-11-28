# SplitDebt — Đóng gói APK cho điện thoại thật

## Phạm vi và điều kiện

Bản này dựa trên SplitDebt-test.zip ngày 28/11/2026. Không chứa APK đã build, máy chủ đã triển khai, tài khoản Supabase, Firebase Admin credentials hoặc khóa ký. Người dùng cài APK không cần Python, Java, Flutter, Tesseract hay Docker. Nhóm phát triển phải duy trì Spring Boot, database và OCR service ở địa chỉ Internet mà APK truy cập được. ML Kit xử lý ảnh trên điện thoại nhưng phân tích dữ liệu vẫn gọi API. In PDF hiện sử dụng font tải qua Internet lần đầu. Không cam kết OCR đọc đúng mọi hóa đơn.

Kiến trúc: APK (HTTPS) → Spring Boot `/api` → PostgreSQL/Supabase; Spring Boot → OCR local qua mạng riêng. QR/ML Kit chạy phía điện thoại, PaddleOCR/PP-StructureV3 chạy trên máy chủ, không đưa mô hình Paddle vào APK. Không công khai cổng 8002 hoặc database. Không cần chạy Flutter Web khi sử dụng APK.

## A. Demo miễn phí trên Windows (không Docker)

### 1. Cập nhật project

Giữ repository và `.env` hiện có. Chuyển nhánh `test`, kiểm tra `git status`, sao lưu các file bạn đã sửa. Giải nén bản PATCH vào gốc `D:\AndroidProject\SplitDebt` hoặc dùng bản FULL cho một thư mục mới. Không ghi đè file cấu hình riêng. Kiểm tra `git diff` và `git status` trước khi commit.

Cài đặt môi trường: `flutter doctor -v`, JDK 21, Android SDK/Build Tools, Python 3.11 x64 cho OCR. Không thay các phiên bản dependency Flutter đang được khóa trong pubspec.lock. Nếu là bản clone mới, Flutter có thể sinh Gradle wrapper/local.properties trong lần build; nếu thiếu, dùng Flutter SDK đúng phiên bản để khôi phục wrapper (không tạo lại project).

### 2. Database

Dùng `api/.env` hiện có **chỉ khi đây là database demo được phép sử dụng**. Nếu tạo mới, sao chép `api/.env.example`, điền DB_URL, DB_USERNAME, DB_PASSWORD và JWT_SECRET ngẫu nhiên đủ ít nhất 32 byte. Không đưa `.env` hoặc khóa ký lên GitHub. Release mặc định `ddl-auto=validate`; nếu schema chưa có, khởi động bản local để tạo schema trên database demo trống (kiểm tra trước khi dùng `ddl-auto=update` trên dữ liệu đang có). Sau đó dừng local. Không chạy `update` tùy tiện trên database production.

### 3. OCR (CMD 1)

```
cd /d D:\AndroidProject\SplitDebt\ocr-service
install.cmd
start.cmd
```

Chỉ cài một lần. Mở CMD riêng:

```
cd /d D:\AndroidProject\SplitDebt\ocr-service
warmup.cmd
curl.exe http://127.0.0.1:8002/health
```

Warmup dùng `docs/ocr-test/receipt-sample.png`, phải nhận dạng thành công cả `ocr` và `structure`. Health phải có `ready` chứa hai chế độ. Lần đầu mô hình cần tải qua Internet, dung lượng và RAM phụ thuộc máy. Nếu máy không đủ tài nguyên, chỉ demo OCR nhanh với cờ `-AllowBasicOcr`; không mô tả như OCR nâng cao đã hoạt động.

### 4. Backend (CMD 2)

```
cd /d D:\AndroidProject\SplitDebt
set "JAVA_HOME=C:\Program Files\Java\jdk-21.0.12.1"
set "PATH=%JAVA_HOME%\bin;%PATH%"
run-backend-release.cmd
```

Mở CMD riêng kiểm tra:

```
curl.exe -i http://127.0.0.1:8081/api/ready
```

Mong đợi JSON: `{ "service":"SplitDebt", "database":true, "ocr":true, "structure":true }`. HTTP 503 nếu database chưa kết nối. OCR false không chặn đăng nhập; phải khắc phục OCR trước khi chia sẻ APK có đủ chức năng. Release tắt Swagger và Tesseract server mặc định, giữ OCR ML Kit + Paddle. Nếu đã cài Tesseract trên server, có thể đặt `TESSERACT_ENABLED=true` và cấu hình `OCR_TESSERACT_PATH`.

### 5. HTTPS tạm thời (CMD 3)

Tải cloudflared Windows x64 từ https://developers.cloudflare.com/tunnel/downloads/ , đổi tên `cloudflared.exe`, lưu vào `D:\Tools\cloudflared\cloudflared.exe`.

```
D:\Tools\cloudflared\cloudflared.exe tunnel --url http://127.0.0.1:8081
```

Sao chép URL HTTPS `https://<random>.trycloudflare.com` xuất hiện trong log (không dùng nguyên ví dụ). Kiểm tra trên điện thoại bằng 4G/5G:

```
https://<random>.trycloudflare.com/api/ready
```

Quick Tunnel chỉ dùng demo/kiểm thử: URL tạm thời, đổi khi tạo tunnel mới, không SLA. Giữ máy tính, backend, OCR và tunnel hoạt động. Không mở port 8081/8002 ra router; tunnel tạo kết nối outbound. URL là công khai, chỉ dùng database demo không có dữ liệu nhạy cảm và giới hạn chia sẻ cho nhóm môn học. Tắt tunnel sau buổi demo. Cloudflare là trung gian TLS; không gửi hóa đơn thật có thông tin nhạy cảm lên môi trường demo. Địa chỉ cố định: cấu hình Named Tunnel với domain do nhóm sở hữu, hoặc triển khai theo phần B. Nếu URL đổi, APK phải build lại với URL mới. Không phải dịch vụ luôn miễn phí/luôn sẵn sàng cho production.

### 6. Ký APK (chỉ tạo khóa một lần)

Nếu nhóm đã có keystore dùng phát hành trước đó thì dùng lại, không tạo khóa mới. Nếu chưa có, chạy CMD:

```
mkdir D:\SplitDebtKeys
"%JAVA_HOME%\bin\keytool.exe" -genkeypair -v -keystore D:\SplitDebtKeys\splitdebt-release.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias splitdebt
```

Nhập mật khẩu đủ mạnh theo lời nhắc, không ghi mật khẩu vào lịch sử CMD. Lưu khóa an toàn. Tạo cấu hình:

```
cd /d D:\AndroidProject\SplitDebt\frontend\android
copy key.properties.example key.properties
notepad key.properties
```

Điền mật khẩu thật trong `storePassword`, `keyPassword`, `keyAlias` và `storeFile` (dùng dấu / trong đường dẫn). Không chia sẻ keystore hay file key.properties. Khi cập nhật app, giữ cùng applicationId và khóa ký, tăng versionCode (`version: 1.0.0+2` trong pubspec.yaml nếu lần trước là +1). App debug cũ ký bằng khóa khác sẽ không thể nâng cấp trực tiếp; sao lưu thông tin cần thiết rồi gỡ app debug trước khi cài release. Dữ liệu local có thể mất khi gỡ, dữ liệu server không tự bị xóa.

### 7. Build APK (PowerShell)

```
cd D:\AndroidProject\SplitDebt\frontend
Set-ExecutionPolicy -Scope Process Bypass
.\build-apk.ps1 -ApiBaseUrl 'https://URL-THUC-TE.trycloudflare.com/api'
```

Thay URL bằng địa chỉ thật từ tunnel hoặc máy chủ. Script kiểm tra HTTPS, `/api/ready`, OCR, Gradle signing, chạy pub get/analyze/test/build; kiểm tra chữ ký Android bằng apksigner; kiểm tra không có `.env` riêng tư trong APK; xuất APK đa ABI mặc định và SHA256. Không tắt TLS hay Android cleartext. Nếu không tìm thấy Android SDK, đặt ANDROID_HOME hoặc ANDROID_SDK_ROOT tới SDK thật. Không dùng dependency_overrides để né lỗi.

APK ở `D:\AndroidProject\SplitDebt\release-output\<ngay-gio>\app-release.apk`. Chỉ gửi APK và SHA256 cho người dùng. Không gửi `.env`, symbols hay keystore. Dùng `-SplitPerAbi` nếu muốn file APK nhỏ hơn theo kiến trúc, nhưng mặc định một file dễ chia sẻ hơn. Nếu muốn thông báo push, xem phần C; mặc định bản phát hành tắt FCM, thông báo dữ liệu trong app vẫn dùng backend.

## B. Triển khai tên miền cố định

Dành cho máy chủ Linux x86_64 đã cài Docker Engine + Compose, có đủ CPU/RAM và SSD cho PaddleOCR. Dự trù 4 vCPU, 8 GB RAM hoặc cao hơn làm mức thử nghiệm, đo thực tế trước khi công bố. Dịch vụ VPS/tên miền có thể mất phí. Không cần chạy Docker trên máy Windows của bạn nếu server đã có.

1. Đưa project lên server qua phương thức an toàn. Tạo `api/.env` riêng trên server. Tạo `deploy/.env` từ mẫu, điền `API_DOMAIN` là hostname thực tế, không có `https://` hoặc `/api`. Tạo DNS trỏ về server, mở TCP 80/443 và chỉ các cổng quản trị cần thiết.
2. Từ gốc project: `docker compose -f deploy/compose.yaml --env-file deploy/.env up -d --build`.
3. `docker compose -f deploy/compose.yaml --env-file deploy/.env logs -f api ocr proxy` để kiểm tra. Chạy `docker compose -f deploy/compose.yaml --env-file deploy/.env exec -T ocr python warmup.py` để khởi tạo cả hai mô hình. Model cache lưu trong volume; không xóa volume nếu muốn giữ cache.
4. Caddy cấp TLS cho domain hợp lệ, proxy `/api/*` đến Spring Boot. Backend và OCR không publish cổng. Kiểm tra `https://<domain>/api/ready`, sau đó build APK ở Windows với URL domain thật. Cấu hình Compose mới chưa được chạy ở môi trường chỉnh sửa; kiểm tra trên server trước khi dùng.
5. Nếu triển khai cho người dùng thật, cần thêm rate limiting tại proxy/WAF (đặc biệt auth và OCR), giám sát, backup, kiểm thử phân quyền theo nhóm và người dùng, bảo vệ token lưu trên thiết bị, nâng cấp bảo mật dependency và chính sách dữ liệu. Đây là cấu hình release cho môn học, chưa phải chứng nhận production security.

## C. Firebase, PDF và phát triển local

- `frontend/.env` không còn là Flutter asset. `assets/client.env` chỉ dành cho thông tin client công khai, mặc định `FIREBASE_ENABLED=false`. Không đưa DB, JWT, service account, Vision key vào file này. Local web `run-web-local.cmd` tiếp tục dùng localhost; nếu muốn FCM local, điền các thông số client Firebase hợp lệ vào `assets/client.env` và không commit cấu hình riêng.
- Khi cần push trên Android: giữ đúng package `com.example.split_debt` trong Firebase, điền FIREBASE_ANDROID_* trong `frontend/.env`, cấu hình `FIREBASE_ENABLED=true` và Application Default Credentials trên server (Docker cần mount service-account chỉ đọc và đặt GOOGLE_APPLICATION_CREDENTIALS trỏ trong container), chạy build với `-EnableFcm`. Script chỉ sao chép các trường Firebase client được cho phép. Push phải được kiểm tra trên máy thật; nếu từ chối quyền thông báo, app vẫn dùng được.
- In/PDF hóa đơn đang sử dụng PdfGoogleFonts.notoSansRegular/Bold; lần đầu cần mạng để tải font. Thử in một hóa đơn trước khi demo. Không yêu cầu cài font hoặc trình OCR trên điện thoại. OCR ảnh cần Internet để phân tích backend và nhận dạng nâng cao.
- Máy ảo: debug vẫn được dùng `http://10.0.2.2:8081/api`, Web debug dùng `http://localhost:8081/api`. Release bắt buộc `--dart-define=API_BASE_URL=https://.../api`. Không dùng HTTP hay địa chỉ IP local cho release.

## D. Nghiệm thu bắt buộc trên máy thật (chưa chạy tại môi trường chỉnh sửa)

- Backend: `mvnw.cmd clean test` rồi `run-backend-release.cmd`; kiểm tra schema, JWT, tài khoản test và readiness.
- APK ký hợp lệ, cài mới trên ít nhất 2 máy Android; Wi-Fi và 4G/5G khác mạng máy chủ; thử app tắt/mở, đăng ký, đăng nhập, nhóm, khoản chi, chia tiền, thanh toán công nợ, lịch sử.
- OCR: chụp ảnh rõ, chọn ảnh, quét QR, thử ảnh khó để dùng Paddle, kiểm tra popup và tổng tiền, sửa dữ liệu, in PDF. Tắt OCR service để xác nhận OCR nhanh/nhập thủ công còn hoạt động; tắt backend để xác nhận báo lỗi dễ hiểu. Không khẳng định kết quả đúng khi chưa đối chiếu hóa đơn.
- Đăng xuất và đổi tài khoản: không thấy dữ liệu của người trước; kiểm tra từ chối truy cập nhóm không thuộc quyền. Push (nếu bật), chuyển ngôn ngữ, dark mode, camera bị từ chối, màn hình nhỏ, dữ liệu lớn.
- Thử cập nhật APK bằng cùng key, không mất tài khoản/dữ liệu server. Kiểm tra SHA256.

## E. Khắc phục nhanh

| Hiện tượng | Kiểm tra |
| --- | --- |
| Cài APK được nhưng đăng nhập lỗi | URL `/api/ready` trên 4G, HTTPS thật, backend và database |
| Tunnel đổi URL | Tạo build mới hoặc dùng domain cố định |
| OCR nhanh có nhưng nâng cao lỗi | `warmup.cmd`, health `ready`, log Python, giới hạn CPU/RAM |
| APK không cài đè app debug | Khác chữ ký; dùng lại khóa cũ hoặc gỡ debug sau khi sao lưu |
| Gradle/Pub lỗi | Chạy `flutter doctor -v`, kiểm tra JDK/SDK/dependency; không xóa Pub Cache hoặc SDK |
| In PDF chưa hoạt động | Kiểm tra mạng, font lần đầu, dịch vụ in Android |

Tham khảo: https://docs.flutter.dev/deployment/android ; https://developers.cloudflare.com/tunnel/get-started/quick-tunnels/ ; https://www.paddleocr.ai/v3.3.1/en/version3.x/installation.html
