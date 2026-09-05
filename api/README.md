Sao chép toàn bộ nội dung dưới đây và lưu vào file `SplitDebt/api/README.md`.

```markdown
# ⚙️ SplitDebt API - Backend

Phân hệ Backend (RESTful API) của dự án **SplitDebt**, được phát triển bởi **Team ErrorAtLine1**. Hệ thống đóng vai trò trung tâm xử lý dữ liệu, quản lý bảo mật và thực thi thuật toán tối ưu hóa công nợ (Smart Settlement).

## 🛠 Công nghệ sử dụng

*   **Ngôn ngữ:** Java 21
*   **Framework:** Spring Boot 3.3.0
*   **Database:** PostgreSQL (Vận hành trên Supabase)
*   **ORM:** Spring Data JPA / Hibernate 6.5
*   **Build Tool:** Maven
*   **Tiện ích:** Lombok, Spring Dotenv (Native Config)

## 📂 Kiến trúc thư mục

```text
src/main/java/com/splitdebt/api/
├── config/       # Cấu hình hệ thống (CORS, Security)
├── controller/   # (Presentation) Tiếp nhận HTTP Requests và trả về JSON
├── dto/          # (Data Transfer Objects) Định dạng dữ liệu giao tiếp FE-BE
├── entity/       # (Domain Model) Ánh xạ trực tiếp với bảng PostgreSQL
├── exception/    # Xử lý ngoại lệ tập trung (@ControllerAdvice)
├── repository/   # (Data Access) Thao tác với cơ sở dữ liệu qua JPA
└── service/      # (Business Logic) Xử lý thuật toán chia tiền, xén nợ

```

## 🚀 Hướng dẫn cài đặt & Khởi chạy

### 1. Yêu cầu hệ thống

* JDK 21 trở lên.
* IDE hỗ trợ Java (VS Code, IntelliJ IDEA).

### 2. Thiết lập biến môi trường

Tạo file `.env` tại thư mục gốc của backend (`SplitDebt/api/.env`), đặt ngang hàng với file `pom.xml`:

```env
# URL kết nối trực tiếp đến Postgres Supabase (Cổng 5432)
DB_URL=jdbc:postgresql://db.[YOUR_PROJECT_REF].supabase.co:5432/postgres?sslmode=require
DB_USERNAME=postgres
DB_PASSWORD=[YOUR_DB_PASSWORD]

```

*(Lưu ý: Không commit file `.env` lên Git).*

### 3. Khởi chạy Server

Mở Terminal tại thư mục `api` và chạy lệnh sau để tải thư viện và khởi động máy chủ:

* **Windows:**
```bash
.\mvnw clean spring-boot:run

```


* **macOS / Linux:**
```bash
./mvnw clean spring-boot:run

```



### 4. Nghiệm thu kết nối

Khi console báo `Tomcat started on port 8080`, hãy mở trình duyệt và gọi API Health Check để xác nhận đường truyền:

* **Endpoint:** `GET http://localhost:8080/api/health`
* **Phản hồi:** `Backend SplitDebt đang chạy tốt và sẵn sàng!`

## 🧩 Luồng nghiệp vụ chính

1. **Xác thực (Auth):** Kết hợp xác thực Token JWT sinh ra từ Supabase Auth.
2. **Quản lý giao dịch:** Tính toán tỷ lệ chia tiền (Equally, Exact, Percent) và ghi nhận nợ chéo.
3. **Thuật toán Smart Settlement:** Áp dụng lý thuyết đồ thị (Directed Graph) để triệt tiêu các khoản nợ vòng tròn, trả về danh sách chuyển khoản tối giản nhất cho người dùng.

```

```