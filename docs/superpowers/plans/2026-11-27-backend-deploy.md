# Deploy backend lên Internet (https)

**Mục tiêu:** backend Spring Boot chạy 24/7 ở một URL `https://<tên>.onrender.com/api`, để APK release (plan `2026-11-27-android-release-apk.md`) dùng được trên điện thoại thật. Chi phí 0 đồng.

## Hiện trạng (Claude Code đã kiểm tra)

| Mục | Hiện tại | Ảnh hưởng khi deploy |
|---|---|---|
| Database | PostgreSQL qua `DB_URL`, `DB_USERNAME`, `DB_PASSWORD` (`.env.example` gợi ý managed pooler, có `sslmode=require`) | **Dùng lại database managed hiện có** (Supabase). Không cần tạo database mới, dữ liệu giữ nguyên |
| Cổng | `server.port: 8081` cố định | Render cấp cổng qua biến `PORT`. Phải đọc `${PORT:8081}` |
| Secret | Đọc từ biến môi trường, `.env` chỉ là `optional:` | Khai báo biến trên Render. Không đưa `.env` lên server |
| Firebase Admin | `GoogleCredentials.getApplicationDefault()`, tức đọc file theo `GOOGLE_APPLICATION_CREDENTIALS` | Dùng **Secret File** của Render, không sửa code. Thiếu file thì app vẫn chạy, chỉ tắt push |
| Health check | `GET /api/health`, không cần đăng nhập | Dùng cho Render và cho dịch vụ giữ server thức |
| Swagger | Bật công khai | Nên tắt trên production bằng biến môi trường |
| Hikari | `maximum-pool-size: 15` | Pooler gói miễn phí giới hạn số kết nối. Cho chỉnh bằng biến, production đặt 5 |
| Java | 21, Spring Boot 3.3 | Render không có runtime Java sẵn, nên **cần `Dockerfile`** |
| App | `connectTimeout` và `receiveTimeout` 10 giây | Gói free của Render **ngủ sau 15 phút** không có request, khởi động lại mất khoảng 1 phút, nên request đầu tiên sẽ lỗi timeout. Xử lý ở D5 và bằng ping giữ thức |

## Chọn nơi deploy: Render (gói Free, Web Service dùng Docker)

- Miễn phí, có https và domain `*.onrender.com` sẵn, deploy tự động khi push lên GitHub.
- 750 giờ mỗi tháng, đủ cho 1 service chạy suốt tháng.
- RAM 512 MB, nên phải giới hạn heap của JVM (xem D2).
- Chọn region **gần region của database** (xem trong Supabase, Project Settings → General). Nếu database ở Singapore thì chọn Singapore.

Thay thế nếu Render không hợp: Koyeb (free, cũng Docker), Railway (dùng thử có hạn mức). Plan này chỉ viết cho Render.

## Phần Antigravity làm

Global Constraints: không thêm dependency Maven hay Flutter. **Không đọc, không sửa, không commit `.env`** (cả `api/.env` lẫn `frontend/.env`). Không ghi secret thật vào bất kỳ file nào. Mỗi mục một commit. Không push.

### D1. Cấu hình đọc từ biến môi trường

Trong `api/src/main/resources/application.yaml`:
- `server.port: ${PORT:8081}`.
- `spring.datasource.hikari.maximum-pool-size: ${DB_POOL_MAX:15}` và `minimum-idle: ${DB_POOL_MIN_IDLE:3}`.
- `springdoc.api-docs.enabled: ${SWAGGER_ENABLED:true}` và `springdoc.swagger-ui.enabled: ${SWAGGER_ENABLED:true}`.
- Thêm `server.forward-headers-strategy: framework`, vì Render đứng sau proxy https.
- Giá trị mặc định giữ nguyên như hiện tại, để chạy local không đổi gì.

Cập nhật `api/.env.example`: thêm `PORT`, `DB_POOL_MAX`, `DB_POOL_MIN_IDLE`, `SWAGGER_ENABLED` (có chú thích, không có giá trị thật).

**Test:** `cd api; .\mvnw.cmd test` vẫn PASS (profile test không bị ảnh hưởng).

### D2. Dockerfile

Tạo `api/Dockerfile`, build 2 giai đoạn:
- Giai đoạn build: `maven:3.9-eclipse-temurin-21`. Copy `pom.xml` trước và chạy `mvn -q dependency:go-offline` để tận dụng cache, rồi copy `src` và chạy `mvn -q -DskipTests package`.
- Giai đoạn chạy: `eclipse-temurin:21-jre`. Chạy bằng user không phải root. Copy file jar vào `/app/app.jar`.
- `ENV JAVA_OPTS="-XX:MaxRAMPercentage=75 -XX:+UseSerialGC -Xss512k"` (vừa với RAM 512 MB).
- `CMD` dạng shell: `java $JAVA_OPTS -jar /app/app.jar`.
- `EXPOSE 8081`, chỉ để ghi chú. Cổng thật lấy từ `PORT`.

Tạo `api/.dockerignore` gồm: `.env`, `.env.*` (trừ `!.env.example`), `target/`, `target_test-classes/`, `*.json` của service account (`*firebase*.json`, `*service-account*.json`), `.git`, `.idea`, `*.iml`.

**Kiểm tra:** chạy `docker build -t splitdebt-api api`, rồi xác nhận image không chứa `.env` bằng `docker run --rm --entrypoint sh splitdebt-api -c "ls -la /app"`. Chỉ được có `app.jar`.

### D3. Blueprint `render.yaml` ở gốc repo

```yaml
services:
  - type: web
    name: splitdebt-api
    runtime: docker
    rootDir: api
    dockerfilePath: ./Dockerfile
    plan: free
    region: singapore        # đổi nếu database ở region khác
    branch: main             # chủ dự án có thể đổi sang dev2-dat khi demo
    healthCheckPath: /api/health
    autoDeploy: true
    envVars:
      - key: DB_URL
        sync: false
      - key: DB_USERNAME
        sync: false
      - key: DB_PASSWORD
        sync: false
      - key: JWT_SECRET
        sync: false
      - key: JWT_EXPIRATION_MS
        value: "86400000"
      - key: FIREBASE_ENABLED
        value: "true"
      - key: GOOGLE_APPLICATION_CREDENTIALS
        value: /etc/secrets/firebase-service-account.json
      - key: SUPABASE_KEY
        sync: false
      - key: DB_POOL_MAX
        value: "5"
      - key: DB_POOL_MIN_IDLE
        value: "1"
      - key: SWAGGER_ENABLED
        value: "false"
      - key: CORS_ALLOWED_ORIGINS
        value: "http://localhost:3000"
```
`sync: false` nghĩa là Render hỏi giá trị lúc tạo service, nên **không có secret nào nằm trong repo**.

### D4. Script kiểm tra sau deploy

Tạo `api/tool/smoke_deploy.ps1 -BaseUrl https://<tên>.onrender.com/api`:
1. `GET /health`, chờ tối đa 120 giây (lần đầu server có thể đang ngủ). In thời gian phản hồi.
2. Đăng ký một user ngẫu nhiên `smoke_<random>@example.com` (gửi kèm `consents`, `platform`, `appVersion` như app), rồi đăng nhập lấy token.
3. Tạo nhóm, gửi 1 tin chat, đọc lại tin bằng `GET /groups/{id}/messages`.
4. Xoá tài khoản smoke bằng API xoá tài khoản (để không để rác trên database thật).
5. In PASS hoặc FAIL cho từng bước. Không in token hay mật khẩu.

Script chỉ dùng `Invoke-RestMethod`, không thêm công cụ.

**Kiểm tra:** chạy script với backend local `http://localhost:8081/api`. Cho phép `http://` khi host là `localhost`, còn lại bắt buộc `https://`.

### D5. App chịu được lúc server đang khởi động

Trong `frontend`:
- Tạo `lib/core/network/server_warmup.dart` với hàm `Future<void> warmUpServer(Dio dio)`: gọi `GET /health` với `receiveTimeout` và `connectTimeout` 90 giây, nuốt mọi lỗi (chỉ `debugPrint`).
- Gọi `warmUpServer` một lần, không `await`, ngay khi app khởi động (trong `main.dart` sau khi khởi tạo xong, hoặc ở màn splash nếu có).
- Khi request lỗi do `DioExceptionType.connectionTimeout` hoặc `receiveTimeout`, thông báo cho người dùng là **"Máy chủ đang khởi động, vui lòng thử lại sau ít giây."** thay vì thông báo lỗi chung. Sửa ở chỗ đang chuyển `DioException` thành thông báo lỗi (tìm hàm xử lý lỗi dùng chung). Không đổi timeout 10 giây của các request khác.

**Test:**
- `server_warmup_test.dart`: Dio giả ném lỗi thì `warmUpServer` không ném ra ngoài; request gửi đi là `GET .../health`.
- Test cho hàm chuyển lỗi: `connectionTimeout` và `receiveTimeout` cho ra đúng thông báo trên; các lỗi khác giữ thông báo cũ.

### D6. Tài liệu `docs/backend-deploy.md`

Viết từng bước cho chủ dự án (theo "Phần chủ dự án làm" bên dưới), kèm:
- Bảng biến môi trường: tên, ý nghĩa, lấy ở đâu. Ví dụ `DB_URL` lấy ở Supabase → Connect → **Session pooler**, dạng JDBC.
- Cách tạo `JWT_SECRET` mới: `$b = New-Object byte[] 48; [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($b); [Convert]::ToBase64String($b)`.
- Cách tải Secret File Firebase và tên file phải đúng `firebase-service-account.json`.
- Cách xem log trên Render, cách deploy lại, cách rollback.
- Lưu ý gói free: server ngủ sau 15 phút, cách cài ping giữ thức.
- Lệnh build APK với URL mới: `.\tool\build_apk.ps1 -ApiBaseUrl https://<tên>.onrender.com/api`.

## Kiểm tra cuối (Antigravity)

- `cd api; .\mvnw.cmd test` PASS.
- `docker build -t splitdebt-api api` thành công, image chỉ chứa `app.jar` trong `/app`.
- Chạy thử container với database local hoặc database dev: `docker run --rm -p 8099:8099 -e PORT=8099 --env-file api/.env splitdebt-api`, rồi `.\api\tool\smoke_deploy.ps1 -BaseUrl http://localhost:8099/api` PASS. **Không được in hay mở nội dung `.env`.** Nếu không có database để chạy thì ghi rõ "chưa chạy" vào PROGRESS, không bịa kết quả.
- `flutter analyze` 0 error, `flutter test -j 1` PASS.
- Cập nhật `docs/PROGRESS.md`. Không push.

## Phần chủ dự án làm

1. **Đổi các secret đã từng dùng trên máy dev:** tạo `JWT_SECRET` mới cho production (khác giá trị trong `.env`). Đổi `JWT_SECRET` sẽ làm mọi phiên đăng nhập cũ hết hạn, như vậy là bình thường.
2. Push code lên GitHub (khi đã merge vào nhánh mà `render.yaml` trỏ tới).
3. Vào render.com → New → **Blueprint** → chọn repo. Render đọc `render.yaml` và hỏi các biến `sync: false`: điền `DB_URL`, `DB_USERNAME`, `DB_PASSWORD`, `JWT_SECRET`, `SUPABASE_KEY`.
4. Service → Environment → **Secret Files** → thêm `firebase-service-account.json` (file service account của Firebase Admin). Không có file này thì push tắt, app vẫn chạy.
5. Chờ deploy xong, mở `https://<tên>.onrender.com/api/health`. Chạy `.\api\tool\smoke_deploy.ps1 -BaseUrl https://<tên>.onrender.com/api`.
6. Giữ server thức: tạo monitor miễn phí ở UptimeRobot (hoặc cron-job.org), gọi `https://<tên>.onrender.com/api/health` mỗi 10 phút.
7. Build APK bằng URL này, rồi đi qua danh sách kiểm tra trong `docs/android-release.md`.

## Rủi ro đã biết

- **Một database dùng chung cho dev và production:** test thủ công trên máy dev sẽ ghi vào cùng dữ liệu người dùng thật. Khi có người dùng thật, nên tạo project Supabase thứ hai cho dev.
- `ddl-auto: update` tự sửa schema khi deploy. Chấp nhận được với đồ án; không xoá cột cũ.
- Gói free không có SLA. Đủ cho demo và chấm điểm.
