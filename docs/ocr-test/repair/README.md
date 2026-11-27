# SplitDebt - Đồng bộ backend OCR và CORS

Bản vá tổng hợp 8 file Java từ các bản cập nhật OCR Layout, Advanced Local và Connection Dependencies. SecurityConfig dùng constructor tường minh thay cho Lombok @RequiredArgsConstructor. Không thay đổi quyền truy cập API, không bỏ kiểm thử CORS, không sửa .env hoặc database.

Áp dụng vào thư mục gốc SplitDebt trên nhánh test sau khi sao lưu các sửa đổi cục bộ. Dừng backend trước khi ghi đè.

Kiểm tra trong CMD tại thư mục api:

    mvnw.cmd -v
    mvnw.cmd clean compile
    mvnw.cmd -Dtest=ReceiptParserTest,CorsConfigTest test
    mvnw.cmd spring-boot:run

Chỉ chạy lệnh sau khi lệnh trước thành công. Nếu Maven thành công mà VS Code còn lỗi, chạy Java: Clean Java Language Server Workspace và mở lại workspace.

Kiểm thử thực tế trong môi trường tạo bản vá: javac --release 21 biên dịch thành công ReceiptParser, ReceiptLayoutAnalyzer, ReceiptAdvancedAnalysis cùng 3 chương trình kiểm thử độc lập; 33/33 ca PASS. Xem java-test-results.txt. Chưa chạy Maven/Spring Boot do thiếu dependency và không truy cập được Maven Central. Không xác nhận build toàn bộ ứng dụng hoặc tích hợp CORS trên máy người dùng.
