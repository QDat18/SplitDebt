# SplitDebt Backend API

REST API cho hệ thống SplitDebt, được viết hoàn toàn bằng Java 21 và Spring Boot. Backend chịu trách nhiệm xác thực, phân quyền, nhóm, khoản chi, tính công nợ, quyết toán, thống kê, cài đặt và thông báo.

## Công nghệ

- Java 21
- Spring Boot 3.3
- Spring Web và Spring Security
- Spring Data JPA/Hibernate
- PostgreSQL; H2 chỉ dùng cho test
- JWT với JJWT
- Firebase Admin SDK cho FCM
- Google API Client để xác minh Google ID token
- Springdoc OpenAPI/Swagger
- Maven Wrapper

## Yêu cầu môi trường

- JDK 21.
- PostgreSQL local hoặc PostgreSQL managed service.
- Không cần cài Maven toàn cục vì repository có `mvnw.cmd`.

Kiểm tra Java:

```powershell
java -version
$env:JAVA_HOME='C:\Program Files\Java\jdk-21'
```

## Cấu hình `.env`

Tạo cấu hình local:

```powershell
Copy-Item .env.example .env
```

| Biến | Bắt buộc | Mục đích |
|---|---:|---|
| `DB_URL` | Có | JDBC URL của PostgreSQL |
| `DB_USERNAME` | Có | Tài khoản database |
| `DB_PASSWORD` | Có | Mật khẩu database |
| `JWT_SECRET` | Có | Khóa ký JWT, tối thiểu 32 byte ngẫu nhiên |
| `JWT_EXPIRATION_MS` | Không | Thời hạn token, mặc định 24 giờ |
| `CORS_ALLOWED_ORIGINS` | Không | Danh sách web origin, phân tách bằng dấu phẩy |
| `FIREBASE_ENABLED` | Không | Bật Firebase Admin, mặc định `false` |
| `GOOGLE_APPLICATION_CREDENTIALS` | Khi bật FCM | Đường dẫn service-account JSON ngoài Git |
| `GOOGLE_WEB_CLIENT_ID` | Khi dùng Google login | OAuth Web client ID, phải giống frontend |

Spring Boot nạp file `.env` qua `spring.config.import`. Biến môi trường của hệ điều hành có thể được dùng để ghi đè khi deploy.

Không commit `.env`, service-account JSON, database password hoặc JWT secret.

## Chạy backend

```powershell
$env:JAVA_HOME='C:\Program Files\Java\jdk-21'
.\mvnw.cmd spring-boot:run
```

Các địa chỉ mặc định:

- API: `http://localhost:8081/api`
- Health check: `http://localhost:8081/api/health`
- Swagger UI: `http://localhost:8081/swagger-ui.html`
- OpenAPI JSON: `http://localhost:8081/v3/api-docs`

## Kiến trúc mã nguồn

```text
src/main/java/com/splitdebt/api/
├── config/       # Firebase Admin và OpenAPI
├── controller/   # HTTP endpoint và lấy danh tính từ SecurityContext
├── dto/          # Request/response contract
├── entity/       # JPA entity và enum nghiệp vụ
├── exception/    # Exception nghiệp vụ và error mapping tập trung
├── repository/   # Spring Data JPA
├── security/     # JWT filter, access denied và security policy
├── service/      # Nghiệp vụ, authorization và transaction
└── util/         # Thuật toán chia tiền
```

Luồng xử lý:

```text
HTTP Request
    ↓
JWT Filter → SecurityContext
    ↓
Controller → Service/Authorization → Repository → PostgreSQL
    ↓
ApiResponse/GlobalExceptionHandler
```

## Nhóm API chính

| Prefix | Chức năng |
|---|---|
| `/api/auth` | Đăng ký, đăng nhập email và đăng nhập Google |
| `/api/users` | Thông tin người dùng hiện tại |
| `/api/groups` | Nhóm và thành viên |
| `/api/v1/expenses` | Khoản chi và người tham gia |
| `/api/groups/{groupId}/debts` | Công nợ trong nhóm |
| `/api/groups/{groupId}/smart-settlement` | Tối ưu giao dịch thanh toán |
| `/api/groups/{groupId}/settlements` | Tạo và xác nhận thanh toán |
| `/api/groups/{groupId}/stats` | Thống kê tài chính |
| `/api/settings` | Thiết lập user/nhóm |
| `/api/notifications` | Thông báo và FCM token |

Chi tiết request/response được xem trực tiếp tại Swagger hoặc trong `API_DOCUMENTATION.md`.

## Xác thực và phân quyền

Các endpoint bảo vệ sử dụng header:

```http
Authorization: Bearer <JWT>
```

Đăng nhập Google gọi `POST /api/auth/google` với Google ID token. API kiểm tra chữ ký, issuer, thời hạn, trạng thái email đã xác minh và `audience` khớp `GOOGLE_WEB_CLIENT_ID` trước khi phát JWT nội bộ. Không nhận email/tên do client tự khai báo làm căn cứ xác thực.

Nguyên tắc bắt buộc:

- Server lấy danh tính từ JWT, không tin `userId` do client gửi.
- Người dùng phải là thành viên `ACTIVE` mới được đọc dữ liệu nhóm.
- Chỉ payer, `OWNER` hoặc `ADMIN` được sửa/xóa khoản chi.
- Payer và participant phải thuộc đúng nhóm.
- Thành viên không được tạo hoặc xác nhận settlement thay cho người khác.
- CORS chỉ áp dụng cho browser; Android/iOS native không dựa vào CORS.

## Quy tắc dữ liệu tiền

- Tổng tiền phải dương.
- Không chấp nhận participant trùng nhau.
- Số tiền, phần trăm và trọng số phải dương.
- Tổng phần trăm/số tiền chia phải khớp tổng khoản chi theo quy tắc làm tròn.
- Với chia theo món, số lượng và đơn giá phải hợp lệ; tổng các món phải khớp tổng khoản chi.
- Tiền dùng `BigDecimal`; không sử dụng số thực nhị phân cho tính toán nghiệp vụ.

## Quy ước comment

- Mỗi file Java có Javadoc `Trách nhiệm file` ở đầu file.
- Comment tập trung vào nghiệp vụ, phân quyền, transaction và lý do của thuật toán.
- Không ghi secret, token hoặc dữ liệu người dùng vào comment/log.

## Kiểm thử

```powershell
$env:JAVA_HOME='C:\Program Files\Java\jdk-21'
.\mvnw.cmd test
```

Test dùng profile `test` và H2, không ghi vào PostgreSQL thật. Các nhóm test hiện có bao phủ context, controller, thiết lập, nhóm, settlement và thuật toán chia tiền.

Build file JAR:

```powershell
.\mvnw.cmd clean package
```

## Trước khi triển khai production

- Tạo `JWT_SECRET` mới bằng nguồn ngẫu nhiên an toàn.
- Dùng database account có quyền tối thiểu và bật TLS.
- Chỉ cho phép CORS origin thật của frontend web.
- Đặt Firebase service-account ngoài repository và quản lý bằng secret manager.
- Dùng đúng OAuth Web client ID ở frontend/backend; đăng ký SHA-1/SHA-256 của keystore Android trong Google Cloud/Firebase.
- Chạy migration có kiểm soát thay vì phụ thuộc lâu dài vào `ddl-auto=update`.
- Chạy đầy đủ test và kiểm tra Swagger contract trước khi release.
