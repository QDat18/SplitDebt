# Project Notes & Tracking

This file tracks the completion of tasks and their associated modifications.

- [2026-09-08 19:16:00] - Thiết lập Tracking và Core Security (Backend) - Thêm thư viện Security và JWT, tạo cấu hình stateless JWT authentication cho Spring Boot. - `api/pom.xml`, `application.yaml`, `JwtUtils.java`, `JwtAuthenticationFilter.java`, `SecurityConfig.java`
- [2026-09-08 19:30:00] - Hoàn thiện API Auth và Settings (Backend) - Thiết kế luồng đăng ký / đăng nhập (BCrypt), API lấy profile người dùng (`/api/users/me`), cấu trúc bảng `UserPreferences` / `GroupSettings` và các endpoint cho phép thiết lập. - `AuthService.java`, `AuthController.java`, `UserController.java`, `SettingsController.java`, `UserPreferences.java`, `GroupSettings.java`
- [2026-09-08 19:58:00] - Frontend Foundation & Token Storage - Tích hợp quản lý token cho frontend bằng `flutter_secure_storage`, viết Interceptor cho `dio_client` tự động đính kèm Token (bỏ qua path có `auth`), và thêm cấu trúc state management qua `flutter_riverpod`. - `pubspec.yaml`, `token_storage.dart`, `dio_client.dart`, `auth_provider.dart`
- [2026-09-08 20:19:00] - Hoàn thiện UI Auth & Ráp nối API (Flutter) - Ráp nối API `register` và `login` vào UI, tách `splash_screen.dart` để tự động điều hướng theo trạng thái đăng nhập (`authProvider`), tạo `profile_screen.dart` hiển thị thông tin người dùng và chức năng đăng xuất. - `home_screen.dart`, `profile_screen.dart`, `splash_screen.dart`, `login_screen.dart`, `register_screen.dart`, `main.dart`
- [2026-09-08 23:20:00] - Fix Lỗi Tích hợp & Kiểm thử Toàn diện - Đổi `spring.jpa.hibernate.ddl-auto` thành `update` trong `application.yaml` để tự tạo bảng Settings. Sửa payload `register` ở Frontend từ `name` thành `fullName` để trùng khớp DTO Backend. Kiểm thử API thành công. - `application.yaml`, `register_screen.dart`

## Hướng dẫn Chạy Dự Án

### 1. Khởi động Backend (Spring Boot)
- Mở Terminal và di chuyển vào thư mục `api`: `cd api`
- Đảm bảo cơ sở dữ liệu PostgreSQL (hoặc Supabase DB) đã được thiết lập và thông tin kết nối đúng trong file `.env` hoặc `application.yaml`.
- Chạy lệnh: `.\mvnw spring-boot:run` (trên Windows) hoặc `./mvnw spring-boot:run` (trên Mac/Linux).
- Backend sẽ chạy ở cổng mặc định là `8081` (http://localhost:8081).

### 2. Khởi động Frontend (Flutter)
- Mở một Terminal khác và di chuyển vào thư mục `frontend`: `cd frontend`
- Chạy lệnh lấy các packages cần thiết: `flutter pub get`
- Khởi chạy ứng dụng Flutter trên trình duyệt Chrome: `flutter run -d chrome --web-port 3000`
- *(Lưu ý: Chúng ta dùng port 3000 cho Web hoặc có thể chạy trên Simulator/Device thật bằng lệnh `flutter run` thông thường).*
