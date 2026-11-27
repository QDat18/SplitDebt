# SplitDebt – sửa lỗi kết nối và khai báo thư viện

Bản vá dựa trên FULL_test + OCR miễn phí + onboarding + QR/PDF + layout + advanced local. Không có bản checkout trực tiếp mới nhất trên máy người dùng; sao lưu/đối chiếu trước khi giải nén. Không đính kèm .env, lockfile, mô hình hoặc dữ liệu. pubspec.yaml được dựng lại từ bản gốc đã biết; giữ các dependency khác nếu đã tự bổ sung. Không chạy flutter upgrade.

- CORS mặc định chỉ chấp nhận hai origin local cổng 3000; script run-backend-local.cmd đặt biến môi trường cho phiên chạy, không thay cấu hình production. Không tắt security Chrome; không mở wildcard CORS. Nếu .env cũ có CORS_ALLOWED_ORIGINS chỉ localhost, script ghi đè ở phạm vi phiên CMD, hoặc sửa dòng đó thủ công.
- Dùng run-backend-local.cmd, đợi Spring Boot báo Started; chạy check-local.cmd ở CMD khác; nếu health không 200, sửa lỗi backend trước (JAVA_HOME, Maven, DB, port). Nếu health 200 nhưng OPTIONS 403, đối chiếu Origin và CORS. Nếu preflight 200 mà login lỗi, xem POST /api/auth/login trên Network và backend log.
- run-web-local.cmd cố định host/cổng. OCR local cổng 8002 không cần thiết cho đăng nhập.
- Pin bốn thư viện dựa trên phiên bản đã biết; Android minSdk >=23, compileSdk >=35. flutter pub get cập nhật lockfile hiện có. Flutter >=3.32 (mã đã có withValues và CardThemeData); kiểm tra flutter --version. Nếu có lỗi giải dependency, gửi log, không dùng dependency_overrides tùy tiện.
- Chạy flutter analyze, flutter test, mvnw.cmd -Dtest=CorsConfigTest test. Test CORS dùng CorsFilter độc lập không cần DB. Test Dart cho thông báo lỗi mạng. Chưa chạy được các test này trong môi trường tạo bản vá vì thiếu SDK Flutter và Maven dependencies; kiểm tra tĩnh không thay thế build.
- Sửa text theme login, giới hạn Row chia đều, Material cho CheckboxListTile, kiểm tra mounted, bảo toàn lỗi backend khi OCR tự động fallback. Các cảnh báo ListTile/RenderFlex khác cần stack trace file/dòng mới để sửa đúng.
- Không log token, không gửi .env khi cung cấp log. Các script chỉ chạy local development.
