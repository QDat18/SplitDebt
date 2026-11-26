# SplitDebt Progress Tracking

- **Status**: Hoàn thành OCR Round 1 (O1 → O10); chờ fixture hoá đơn thật để đo độ chính xác.
- **Done**:
  - Task 0 (code) → Task 5: Hệ thống OCR trên máy (`google_mlkit_text_recognition: ^1.0.3`, `buildReceiptRows`, `RuleBasedReceiptParser`, `ReceiptApplier`, `ReceiptPreviewSheet`, `ReceiptFlow`, `ReceiptOcrLabScreen` khi `kDebugMode`).
  - O1–O10: Tách `qty/unit/total` cách nhau bằng dấu cách; ghép dòng tên + dòng số; loại SĐT VN; huỷ chọn ảnh thoát im lặng; tổng xem trước khớp tổng form; ưu tiên dòng tổng & bỏ `Khách thanh toán`; sửa từ khoá ngắn `the/ban`; nâng iOS `15.0` + tạo `ios/Podfile` (cần chạy `pod install` và test trên máy Mac); bỏ phân bổ nếu món $\le 0$; hỗ trợ số lượng giữa đơn giá–thành tiền & giữ `Combo 2`.
- **Verification**:
  - `flutter analyze`: 0 errors.
  - `flutter test`: 126 passed, 1 skipped (`Chưa có fixture hoá đơn thật`).
- **In progress**: Chờ fixture thật để chạy kiểm tra độ chính xác.
- **Next**: Tạo `rNN.rows.txt` + `rNN.expected.json` từ hoá đơn thật qua `ReceiptOcrLabScreen` và ghi bảng chỉ số thật.
- **Blockers**: Chưa có fixture hoá đơn thật; iOS `pod install` cần kiểm tra trên máy Mac.
