# SplitDebt — OCR nâng cao local

## Phạm vi và điều kiện
Bản vá kế tiếp của SplitDebt_OCR_Layout_UPDATE.zip, yêu cầu đã áp dụng các bản OCR miễn phí, QR/PDF và Layout trước đó. Không chứa .env, không sửa database, không thay đổi các file chia tiền hoặc QR/PDF. Flutter hiện có các dependency từ các bản trước. Không train mô hình, không API key, không phí dịch vụ OCR. Python 3.11 x64, CPU, mạng để tải package và model lần đầu. Dự trù vài GB dung lượng trống, PP-StructureV3 có thể tốn nhiều RAM; không cam kết tốc độ. Không bắt buộc dịch vụ nâng cao để dùng OCR nhanh.

## Cài trên Windows (CMD)
1. Tắt app/backend, sao lưu file đã sửa, kiểm tra git status trên test rồi giải nén patch vào thư mục D:\AndroidProject\SplitDebt.
2. Kiểm tra `py -3.11 -V`. Nếu thiếu, cài Python 3.11 x64 từ python.org; dùng Custom install và chọn ổ D nếu phù hợp. Có thể cần Microsoft Visual C++ Redistributable nếu thiếu DLL. 
3. `cd /d D:\AndroidProject\SplitDebt\ocr-service` rồi `install.cmd`. Script tạo .venv, pip cache, TEMP dưới thư mục dịch vụ. Chỉ cài một lần. Dung lượng đĩa thực tế phụ thuộc phiên bản dependency.
4. Cũng tại đó chạy `start.cmd`. Service chỉ lắng nghe 127.0.0.1:8002 (không expose ra mạng LAN). `curl http://127.0.0.1:8002/health` cho biết process đang chạy, không chứng minh model hoạt động. Model được nạp theo yêu cầu.
5. Mở CMD khác tại ocr-service chạy `warmup.cmd` khi có mạng. Dùng ảnh tổng hợp đi kèm Layout để tải và kiểm tra cả hai model. File JSON nằm trong .cache, không được xem là PASS độ chính xác chỉ vì HTTP 200. So sánh với tổng 175000, ngày 2026-11-26, Cơm gà 2×45000, Coca 3×15000, Bún bò 1×40000. Nếu timeout tải model, xem log dịch vụ; lần quét sau dùng cache nếu tải thành công. Cache chính PaddleX/HuggingFace và temp được cấu hình dưới ổ D, nhưng Windows/dependency có thể vẫn dùng một phần ổ C.
6. CMD backend: `cd /d D:\AndroidProject\SplitDebt\api`, `set "JAVA_HOME=C:\Program Files\Java\jdk-21.0.12.1"`, `set "PATH=%JAVA_HOME%\bin;%PATH%"`, `mvnw.cmd clean spring-boot:run`.
7. CMD frontend: `cd /d D:\AndroidProject\SplitDebt\frontend`, `flutter pub get`, `flutter analyze`, `flutter test`, `flutter run -d chrome --web-port=3000 --dart-define=API_BASE_URL=http://localhost:8081/api`. Android emulator dùng 10.0.2.2 thay localhost như trước.

## Luồng nghiệp vụ
OCR nhanh -> /api/v1/receipts/parse. Nếu thiếu trường hoặc cảnh báo hoặc tổng không khớp, gọi endpoint JWT /api/v1/receipts/advanced với ảnh multipart (mode=ocr). Spring Boot chuyển ảnh đến loopback 8002. Nếu kết quả PaddleOCR chưa rõ, thử mode=structure. Người dùng có thể yêu cầu PP-StructureV3 thủ công ngay cả khi kết quả nhanh nhất quán. Mỗi kết quả độc lập, không tự ghép giá giữa các engine. Ưu tiên ứng viên không có cảnh báo/khớp phép tính nhưng vẫn cần xác nhận; ứng viên khác được giữ để so sánh. Khi service tắt hoặc thất bại, giữ OCR nhanh. Nút phân tích nâng cao không ghi đè nội dung đang chỉnh sửa; chọn ứng viên khác sẽ thay dữ liệu (có thông báo trước). QR và PDF không đổi. Ảnh được xử lý trên thiết bị/server local; dịch vụ Python không lưu ảnh, không gửi ảnh đến cloud. Mô hình tải từ nguồn của PaddleOCR lần đầu. Dịch vụ xử lý một lượt đồng thời và Spring Boot timeout 150 giây/lượt. Nếu triển khai backend từ xa, phải triển khai OCR local trên cùng host hoặc thay địa chỉ an toàn, không mở service công khai.

PaddleOCR trả vùng chữ/cell (không phải luôn là từng từ); adapter không tạo tọa độ giả. PP-StructureV3 dùng bảng HTML thật; chỉ bảng đơn giản với đủ tiêu đề tên/SL/đơn giá/thành tiền, số nguyên VND và dòng khớp phép tính được đưa thành ứng viên độc lập. Bảng gộp ô, nhiều bảng, thiếu trường hoặc phép tính mâu thuẫn dùng kết quả tọa độ và cảnh báo. Không suy diễn đơn giá hay số lượng khi thiếu. Hóa đơn nhiều đơn vị tiền, số lượng thập phân, chữ viết tay khó, ảnh cong/mờ, bảng phức tạp vẫn có thể sai. QR thanh toán không chứa danh sách hàng. Không khẳng định độ chính xác mọi hóa đơn.

## Kiểm thử đã thực hiện trong môi trường chỉnh sửa
- 12 kiểm tra Python (adapter, giới hạn ảnh, endpoint FastAPI bằng TestClient với model giả lập, busy, bảng gộp ô). `python-tests.txt`.
- 10 ca Java độc lập mới + 14 ca layout + 9 ca parser cũ, tổng 33. `java-tests.txt`.
- Không có PaddleOCR/PaddlePaddle đã cài trong môi trường chỉnh sửa; chưa chạy mô hình thật hoặc build Flutter/Spring Boot. Không có benchmark ảnh thực tế. Kiểm tra sau cài đặt theo warmup và ứng dụng.
- Để chạy lại Python test sau khi cài: `.venv\Scripts\python.exe -m pip install httpx` rồi `.venv\Scripts\python.exe -m unittest discover -s tests -v` tại ocr-service.
- Nghiệm thu: quét ảnh in chuẩn, ảnh không tiêu đề, ảnh lệch, ảnh viết tay, hóa đơn VAT, nhiều mẫu mới; ghi tỷ lệ đúng từng dòng và tổng, thời gian lạnh/ấm. Tắt service rồi kiểm tra OCR nhanh; chọn ứng viên sau khi sửa và kiểm tra cảnh báo; kiểm tra QR, in PDF, nhập tay/chia tiền không hồi quy.

## Tài liệu phiên bản
- https://www.paddleocr.ai/v3.3.1/en/version3.x/pipeline_usage/PP-StructureV3.html
- https://www.paddleocr.ai/v3.3.1/en/version3.x/installation.html
- https://www.paddleocr.ai/main/en/version3.x/algorithm/PP-OCRv5/PP-OCRv5_multi_languages.html
