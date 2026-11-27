# SplitDebt — bản cập nhật nhánh test

Cơ sở: nội dung làm việc trong SplitDebt(1).zip, HEAD là test; giữ nguyên các thay đổi chưa commit có trong ZIP. Không kết nối hoặc chỉnh sửa remote/database của bạn. Đây là bản cải tiến cần kiểm tra tích hợp trước khi merge main.

## 1. Áp dụng vào repository đang sử dụng (khuyên dùng)

Tắt backend và frontend. Kiểm tra `git status`, sao lưu các thay đổi đang có và hai file `.env` ngoài repository. Bản UPDATE chứa các file được sửa/thêm, giải nén vào thư mục gốc (có `api`, `frontend`), cho phép ghi đè file trùng sau khi kiểm tra diff. Không có `.git` hay `.env` thật trong ZIP. Không dùng reset --hard. Nếu đã cập nhật main sau khi tạo ZIP, cần đối chiếu từng file trước khi ghi đè.

CMD:

```cmd
cd /d D:\AndroidProject\SplitDebt
git switch test
git status
```

PowerShell (sửa đường dẫn file ZIP theo vị trí tải):

```powershell
Expand-Archive -LiteralPath "$env:USERPROFILE\Downloads\SplitDebt_UPDATE_test.zip" -DestinationPath 'D:\AndroidProject\SplitDebt' -Force
```

Bản FULL là mã nguồn đầy đủ (không gồm lịch sử Git, cấu hình bí mật, cache/build). Dùng nếu cần thư mục độc lập; copy hai `.env` của dự án cũ hoặc tạo từ `.env.example` và cấu hình DB được phép dùng. Không thay `.git` khi áp dụng.

## 2. Chạy Windows

CMD 1:

```cmd
cd /d D:\AndroidProject\SplitDebt\api
set "JAVA_HOME=C:\Program Files\Java\jdk-21.0.12.1"
set "PATH=%JAVA_HOME%\bin;%PATH%"
mvnw.cmd -v
mvnw.cmd spring-boot:run
```

Backend cổng 8081, DB lấy từ .env hiện có. Dùng DB thử nghiệm vì cấu hình gốc ddl-auto:update. CORS cần cho phép đúng origin frontend; nếu chạy Chrome port 3000, đảm bảo CORS_ALLOWED_ORIGINS chứa http://localhost:3000.

CMD 2:

```cmd
cd /d D:\AndroidProject\SplitDebt\frontend
flutter config --jdk-dir="C:\Program Files\Java\jdk-21.0.12.1"
flutter pub get
flutter analyze
flutter test
flutter run -d chrome --web-port=3000 --dart-define=API_BASE_URL=http://localhost:8081/api
```

Android: mở emulator, `flutter devices`, chạy `flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:8081/api` (thay ID đúng). `flutter pub get` sẽ cập nhật pubspec.lock để phù hợp Flutter SDK và image_picker/flutter_localizations mới; lockfile cũ được giữ làm cơ sở, chưa resolve trong môi trường này.

## 3. OCR không cần Cloud (hóa đơn in)

Cài Tesseract OCR cho Windows và gói `vie.traineddata`, `eng.traineddata`. Nếu cần chọn vị trí cài trên D để tiết kiệm ổ C. Kiểm tra bằng `tesseract --version` và `tesseract --list-langs` hoặc chạy bằng đường dẫn tuyệt đối. Thêm vào **api/.env** (không ghi đè giá trị DB):

```properties
OCR_TESSERACT_PATH=C:/Program Files/Tesseract-OCR/tesseract.exe
OCR_LANG=vie+eng
```

Thay đường dẫn theo vị trí thực tế. Khởi động lại backend. Ở Thêm khoản chi chọn nhóm → Quét hóa đơn → chọn ảnh/chụp ảnh → Đọc chữ từ ảnh → đối chiếu tổng → Dùng số tiền → chọn cách chia → Lưu. Thử ảnh `docs/ocr-test/receipt-sample.png` (tổng 50.000, 2 dòng). Chỉ nhập cả dòng món nếu tổng khớp. Có thể sửa/xóa dòng, gán người và dùng tổng các món; không ghi dữ liệu tự động. Ảnh JPEG/PNG tối đa 8 MB / 16 MP; giới hạn 2 lượt OCR đồng thời, timeout 20 giây local / 22 giây cloud. Ảnh tạm local được xóa sau xử lý, không lưu ảnh gốc vào DB.

## 4. Viết tay (tùy chọn)

Tesseract chủ yếu dành cho chữ in. Muốn nhận dạng viết tay, bật Google Cloud Vision API trên dự án Google Cloud được phép sử dụng; cấu hình billing, hạn chế API key chỉ cho Vision và theo chính sách Google. Thêm `OCR_VISION_API_KEY=...` vào **api/.env**. Không để API key trong Flutter .env, Git hay log. Khởi động lại backend. Màn hình đối chiếu sẽ hiển thị lựa chọn Hóa đơn viết tay (Cloud) nếu key có cấu hình. Người dùng phải chủ động bật và nhấn đọc ảnh: ảnh sẽ được gửi tới Google. Không có key thì OCR local vẫn dùng được. Không đảm bảo chữ viết tay/xấu/mờ chính xác. Kiểm tra quyền riêng tư trước khi dùng hóa đơn thực tế. Nguồn kỹ thuật: https://cloud.google.com/vision/docs/handwriting và https://cloud.google.com/vision/docs/request.

## 5. Kết quả rà soát và giới hạn

| Hạng mục | Thay đổi | Trạng thái |
|---|---|---|
| OCR | API multipart có JWT, nhận dạng local/cloud tùy chọn, parse tổng/dòng, xác nhận, lỗi rõ ràng | Parser chạy thực tế; chưa chạy endpoint trên Spring Boot |
| Cài đặt | theme light/dark/system, lưu và khôi phục khi vào layout sau login; ngôn ngữ VI/EN ở điều hướng/cài đặt và một số nhãn khoản chi | Chưa build Flutter; chưa dịch toàn bộ ứng dụng |
| Thông báo | tùy chọn push thanh toán có tác dụng ở NotificationService; vẫn lưu thông báo trong app | Chưa kiểm thử Firebase |
| Các tùy chọn cũ | Ẩn công tắc chưa thực thi đầy đủ (sinh trắc học, nhắc tự động, phê duyệt, hạn mức, chốt sổ, tối ưu nợ tùy chọn). Không thay/xóa dữ liệu DB cũ. Quản lý thông tin nhóm vẫn ở màn hình nhóm | Chưa triển khai các nghiệp vụ mới này |
| Tiền tệ | Không cung cấp đổi tiền USD/EUR giả lập; giao diện nhập và OCR hiện theo VND | Đa tiền tệ chưa hoàn tất |
| Quyền | `/api/v1/settings/user/{id}` chỉ chủ tài khoản; cả hai route cấu hình nhóm cần thành viên ACTIVE; ghi chỉ OWNER/ADMIN | Có test Mockito chưa chạy |
| Giao diện | Nút OCR ngay đầu form, ghi chú, danh mục thực từ DB (nếu đã có danh mục), nút sửa/xóa dòng, màu theme ở form và thẻ nhóm, khung web tối đa 720px | Cần kiểm thử mobile/nhiều kích cỡ; một số màn hình cũ còn màu cố định |
| Hiệu năng | lazy-init các tab; giảm trùng GET nhóm; tránh cache static xuyên tài khoản; chống kết quả cũ khi đổi nhóm; tải song song user + thành viên; batch truy vấn expense participants/items/item participants | Chưa đo benchmark thật; `/groups` vẫn tính nợ mỗi nhóm, cần đánh giá thêm. Lịch sử vẫn trả toàn bộ danh sách, chưa phân trang |
| Android | bỏ đường dẫn Java cứng, giảm giới hạn heap Gradle từ 8GB xuống 2GB (có thể tăng nếu build thiếu RAM) | Chưa build Android |

## 6. Kiểm thử thực tế và đề nghị trước khi nộp

Đã chạy độc lập trên Java 21: 5 tình huống parser và ảnh hóa đơn tổng hợp tiếng Việt qua Tesseract; xem `docs/ocr-test/results.txt`. Có thể chạy lại không cần Maven:

```cmd
cd /d D:\AndroidProject\SplitDebt
mkdir ocr-qa
javac -encoding UTF-8 -d ocr-qa api\src\main\java\com\splitdebt\api\ocr\ReceiptParser.java docs\ocr-test\ParserSmoke.java
java -Dfile.encoding=UTF-8 -cp ocr-qa ParserSmoke docs\ocr-test\recognized.txt
```

Chưa chạy Maven/Spring Boot, Flutter analyze/test/build, DB, Firebase hoặc Cloud Vision vì môi trường chỉnh sửa thiếu SDK/dependencies và không dùng thông tin DB bí mật. Test mới:

```cmd
cd /d D:\AndroidProject\SplitDebt\api
mvnw.cmd -Dtest=ReceiptParserTest,SettingsAccessServiceTest test
mvnw.cmd test
```

Checklist tích hợp:
- Login/logout tài khoản A rồi B: không thấy hồ sơ/nhóm/lịch sử A. Theme, ngôn ngữ của từng tài khoản giữ sau khởi động lại. Test chế độ SYSTEM và đổi theme thiết bị.
- Đổi cài đặt lúc mạng chậm/mất: không báo lưu thành công sai; API trả 403 khi đọc/sửa ID người khác, người ngoài nhóm đọc cấu hình, MEMBER sửa cấu hình. ADMIN/OWNER sửa hợp lệ.
- Test OCR ảnh mẫu, ảnh trống, ảnh quá 8MB, ảnh mờ, không có Tesseract, hủy chọn ảnh, chụp Android, chọn ảnh Chrome, OCR viết tay nếu đã cấu hình cloud. Không tạo khoản chi khi hủy review; không ghi đè draft nếu chưa xác nhận. So sánh total và từng dòng; kiểm tra đúng người được chia.
- Kiểm tra 5 phương thức chia hiện có, số tiền 0, tổng dòng lệch, tạo/sửa/xóa khoản chi, yêu cầu thanh toán/đánh dấu/confirm, thông báo, nhóm, lịch sử và thống kê. Dữ liệu và công nợ phải đúng trước/sau.
- Đo cold start, chuyển tab, GET /groups, GET /v1/expenses/group/{id} trên cùng data trước/sau, 3–5 lượt warmup, ít nhất 30 lượt đo, p50/p95 và SQL query count; chưa có số liệu thực nên không tuyên bố % tăng tốc.
- Kiểm tra tương phản dark mode và font 1.0/1.3/1.5, màn hình nhỏ, web, thiết bị thật; dịch các chuỗi còn lại trước khi công bố hỗ trợ song ngữ toàn bộ.
- Sau khi tất cả đạt, `git status`, `git diff`, kiểm tra tuyệt đối không stage `.env`, rồi commit/push nhánh test. Không push force.


## Cải thiện OCR, QR và giao diện — 27/11/2026

- OCR giữ vùng chữ và độ tin cậy từ MLKit/Tesseract để phân tích cột, xử lý ảnh xoay theo EXIF và tăng tương phản khi kết quả yếu. Parser hỗ trợ thêm định dạng tiền VND/ngày, nhãn tổng thanh toán và tên món xuống dòng. Các khoản thuế, giảm giá, tiền khách đưa không tự biến thành món hàng.
- Màn hình duyệt hóa đơn có ảnh phóng to, cảnh báo phần chưa rõ, chênh lệch tiền hàng/tổng thanh toán, sửa từng dòng và xác nhận trước khi nhập. Màn hình nhỏ dùng toàn màn hình; màn hình rộng đặt ảnh cạnh biểu mẫu. Có thể dừng nhận dạng bổ sung để kiểm tra dữ liệu hiện có.
- QR có camera, đèn pin, nhập ảnh và dán nội dung. Hỗ trợ JSON hóa đơn SplitDebt và VietQR VND có TLV/CRC hợp lệ. QR thanh toán không có ngày/dòng hàng sẽ yêu cầu bổ sung; đường dẫn tra cứu hóa đơn không được tự tải hay chuyển thành dữ liệu hóa đơn.
- Theme tăng độ tương phản ở cả sáng/tối, các nút chung có vùng chạm tối thiểu 48dp. Khung ứng dụng rộng tối đa 1440px, chuyển thanh điều hướng sang bên cạnh từ 840px. Form tạo khoản chi dùng hai cột khi có đủ không gian, giữ dữ liệu khi đổi cách nhập và hỗ trợ chữ lớn/giảm chuyển động.
- Tổng phần chia được kiểm tra trước khi lưu. Chia VND nguyên phân bổ phần lẻ; phần trăm giữ hai chữ số thập phân; sửa tên món vẫn giữ số lượng/đơn giá.

Chạy local: mở `ocr-service/start.cmd`, `run-backend-local.cmd` và `run-web-local.cmd` trong các cửa sổ riêng. Model OCR có thể cần mạng để tải lần đầu; camera web cần localhost hoặc HTTPS và quyền camera. Nếu OCR nâng cao chưa sẵn sàng, vẫn có thể duyệt kết quả đã đọc hoặc nhập thủ công.

Đã xác minh 26 kiểm thử Java OCR, 19 kiểm thử Python và 42 kiểm thử Flutter cho QR, tương phản, điều hướng, duyệt hóa đơn và tạo khoản chi. Phân tích Flutter không có lỗi/cảnh báo, còn 30 gợi ý style/API cũ (chạy với `--no-fatal-infos`). Kiểm thử ảnh mẫu bằng PaddleOCR có model cache đọc đúng 45.000 + 5.000 = 50.000; khởi tạo lạnh và nhận dạng mất khoảng 88,5 giây trên máy này. Đây là ảnh mẫu có sẵn, không phải benchmark độ chính xác cho nhiều hóa đơn thực tế. Mô hình vẫn mất một số dấu tiếng Việt; ảnh mờ, chữ viết tay, hóa đơn phức tạp và ngoại tệ chưa được bảo đảm. Tesseract phía server chưa được thử thực tế vì máy không có executable; OCR web và Paddle là các đường nhận dạng khác.

Các lệnh kiểm tra trong `frontend`: `flutter test`, `flutter analyze --no-fatal-infos`, `flutter build web`, `node test/receipt_ocr_web_test.cjs`. Kiểm thử Java: `mvn test -Dtest=ReceiptParserTest,ReceiptOcrServiceTest,ReceiptAdvancedAnalysisTest` trong `api`. Python: `.venv\Scripts\python -m unittest discover -s tests` trong `ocr-service`.

Tiêu chí thiết kế đối chiếu: [Flutter accessibility](https://docs.flutter.dev/ui/accessibility), [WCAG contrast minimum](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum). Các cặp màu theme có kiểm thử tương phản; chưa thực hiện đánh giá chứng nhận WCAG cho toàn bộ các màn hình cũ hoặc kiểm tra camera trên thiết bị Android/iOS thật.
