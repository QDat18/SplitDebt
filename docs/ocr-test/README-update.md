# SplitDebt — cập nhật OCR + QR + in

Dựa trên FULL_test + OCR_mien_phi + FIX_Onboarding, không thay đổi .env hoặc DB. Giải nén đè vào thư mục gốc repo sau khi sao lưu thay đổi cục bộ. Controller được kèm để có POST /api/v1/receipts/parse. Không phải gói độc lập.

## Cài đặt
CMD frontend: `flutter pub add "mobile_scanner:6.0.11" pdf printing` (nếu chưa có ML Kit: `flutter pub add google_mlkit_text_recognition`). `flutter pub get`. Android kiểm tra `minSdk = maxOf(23, flutter.minSdkVersion)` và quyền camera; mobile_scanner khai báo quyền qua manifest plugin. iOS cần NSCameraUsageDescription (đã có ở bản gốc). Camera web yêu cầu localhost hoặc HTTPS. In dùng Noto Sans qua PdfGoogleFonts, có thể tải font lần đầu; không cần API key/Billing. OCR web cần tải Tesseract.js/mô hình lần đầu.

CMD backend: `mvnw.cmd clean spring-boot:run`. Swagger cần hiện POST /api/v1/receipts/parse. CMD frontend: `flutter analyze`, `flutter test`, `flutter run -d chrome --web-port=3000 --dart-define=API_BASE_URL=http://localhost:8081/api`.

## Kiểm thử
- Chọn Nhập thủ công: không có nút quét; chọn Quét hóa đơn: không có ô nhập số tiền bên ngoài popup. Đổi chế độ phải xác nhận bỏ dữ liệu nếu đã nhập.
- Quét ảnh mẫu hoặc hóa đơn có ngày, SL, đơn giá, thành tiền; kiểm tra popup tự mở; sửa các dòng, chọn ngày nếu OCR không đọc được, xác nhận và in/PDF. Với dòng chỉ có thành tiền, xác nhận dòng gộp hoặc nhập đúng SL và đơn giá.
- Mở receipt-qr-sample.png trên điện thoại khác rồi quét bằng camera; mong đợi ngày 26/11/2026, Cơm gà 2 × 45.000, Trà đá 3 × 5.000, tổng 105.000. QR thanh toán VietQR ASCII có CRC đúng chỉ lấy số tiền VND nếu có, không có thông tin hàng hóa/ngày, không phải chứng minh đã trả. QR URL không tự mở hoặc truy xuất, cần ảnh hóa đơn. Không hỗ trợ đọc QR từ file ảnh ở bản này.
- Nếu chênh lệch tổng tiền: hiển thị cảnh báo, chỉ chia tổng tiền; nếu khớp, cho phép chia theo món và gửi quantity/unitPrice thật. Chi tiết hàng hóa trong DB chỉ lưu với ITEM (giữ logic backend cũ). Nếu cần in các chế độ chia khác, in trước khi lưu; phiếu trong popup không phải chứng từ gốc, không lưu ảnh gốc.
- Đã chạy 9 kiểm tra Java độc lập và node --check; chưa chạy Flutter build/test, Maven integration, QR camera hoặc in thật. Cải thiện OCR web chưa đo độ chính xác bằng tập ảnh thực; chữ viết tay không đảm bảo. Kiểm tra file diff do bản máy bạn có thể đã dart fix/chỉnh thêm.
