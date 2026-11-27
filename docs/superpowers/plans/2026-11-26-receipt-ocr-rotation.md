# Ảnh hoá đơn chụp xoay hoặc nghiêng

Áp dụng Global Constraints của `2026-11-25-receipt-ocr.md`. Không chép dữ liệu VietReceipt vào repo.

## Vấn đề

`buildReceiptRows` gom hàng theo toạ độ Y của `boundingBox` thẳng đứng. Khi ảnh bị xoay 90° (người dùng cầm máy ngang, hoặc ảnh trong VietReceipt), mỗi dòng chữ thành một khung cao và hẹp. Ngưỡng gom hàng (0,5 × chiều cao trung bình) vì vậy rất lớn, và **cả hoá đơn bị dồn vào 2–4 hàng**.

**Bằng chứng:**
- Smoke test: 48/200 file thuộc loại `BROKEN_ROWS` (24%).
- Quét thử trên máy ảo một ảnh hoá đơn Bách Hoá Xanh trong VietReceipt chụp xoay 90°: ML Kit đọc chữ đúng gần hết, nhưng kết quả chỉ còn 3 hàng, các món và số tiền bị trộn lẫn.

Ảnh nghiêng nhẹ (5–20°) cũng gây lỗi tương tự ở mức nhẹ hơn: dòng này lấn sang dòng kia.

## Cách sửa

ML Kit trả `TextLine.cornerPoints`: 4 góc theo chiều kim đồng hồ, **bắt đầu từ góc trên-trái theo hướng đọc của chữ**, nên hướng từ điểm 0 sang điểm 1 chính là hướng dòng chữ.

### X1. `OcrLine` nhận các góc (`receipt_text_rows.dart`)

- Thêm trường tuỳ chọn `List<Offset>? corners` (hoặc kiểu điểm thuần Dart, không phụ thuộc ML Kit, để test được). Giữ nguyên `top`, `bottom`, `left` để code và test cũ không đổi.
- `ReceiptScanner` truyền `line.cornerPoints` vào `corners`.

### X2. Xoay về thẳng trước khi gom hàng

Trong `buildReceiptRows`, trước bước gom hàng:
1. Với các dòng có `corners` và có từ 4 ký tự trở lên, tính góc `atan2(p1.y − p0.y, p1.x − p0.x)`.
2. Lấy **trung vị** các góc làm góc của cả ảnh. Nếu có dưới 3 dòng có `corners`, hoặc |góc| < 3°, thì bỏ qua bước xoay (giữ nguyên hành vi hiện tại).
3. Xoay toàn bộ góc của mọi dòng đi **−góc** quanh gốc toạ độ, rồi tính lại `top` = min y, `bottom` = max y, `left` = min x trên các góc đã xoay. Dòng không có `corners` giữ nguyên.
4. Phần gom hàng và sắp xếp phía sau giữ nguyên.

Viết thành hàm thuần `List<OcrLine> deskewLines(List<OcrLine> lines)` để test riêng.

**Test (`receipt_text_rows_test.dart`):**
- Một hoá đơn tự viết, 5 hàng, mỗi hàng 2 ô (tên món, giá). Dựng toạ độ thẳng rồi xoay toàn bộ các góc đi 90°, 180°, 270° và 12°. Cả 4 trường hợp phải cho **đúng cùng danh sách hàng** như bản thẳng.
- Dòng không có `corners` → kết quả giống hệt hiện tại (mọi test cũ vẫn PASS).
- Có dưới 3 dòng có `corners` → không xoay.

### X3. Converter VietReceipt — **HUỶ (2026-11-26)**

Antigravity đã dừng đúng quy tắc. Claude Code đã kiểm tra lại: `polygon` của VietReceipt luôn bắt đầu từ góc trên-trái **của ảnh** (theo trục ảnh), không theo hướng chữ. Vì vậy từ polygon không phân biệt được ảnh xoay 90° với ảnh xoay 270°. Không làm heuristic riêng cho công cụ dữ liệu. File `BROKEN_ROWS` tiếp tục bị loại khỏi smoke, và ảnh xoay được đo qua ML Kit thật (fixture có nhãn).

Nội dung gốc (giữ để tham khảo):

`tool/vietreceipt_to_rows.dart` truyền 4 điểm của `polygon` vào `corners`.

**Phải kiểm tra trước:** thứ tự điểm trong `polygon` của VietReceipt có bắt đầu từ góc trên-trái theo hướng chữ hay không. Mở 3 file đang là `BROKEN_ROWS` trong `smoke_report.tsv`, chạy lại converter cho riêng chúng, và xem các hàng tạo ra có đọc được theo thứ tự trên xuống không.
- **Nếu đúng:** chạy lại converter cho cả 200 file.
- **Nếu không đúng** (hàng bị đảo ngược hoặc lẫn lộn): **dừng lại và báo**, không tự đoán thứ tự khác. Khi đó X1, X2 vẫn giữ cho app thật.

Cập nhật test converter với một bản ghi xoay 90° tự viết.

## Kiểm tra cuối

- `flutter analyze` 0 error. `flutter test` PASS, bộ hồi quy R0 không đổi.
- Chạy lại smoke. Ghi vào PROGRESS bảng trước/sau cho `BROKEN_ROWS`, `foundTotal`, `unreadable`. Lưu ý mẫu số `eligible` sẽ tăng, nên so cả số tuyệt đối.
- Không sửa parser trong plan này. Nếu file thoát khỏi `BROKEN_ROWS` mà vẫn sai, chỉ ghi lại để đo ở Bước 3.
- Mỗi mục một commit. Không push.
