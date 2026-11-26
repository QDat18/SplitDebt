# SplitDebt Progress Tracking

- **Status**: Đang thực hiện OCR Task 0 (đã xong Step 1–2; chờ thu thập 10–15 hoá đơn thật ở Step 3–5).
- **Done**:
  - Task 0 Step 1: Thêm `google_mlkit_text_recognition: ^1.0.3` vào `frontend/pubspec.yaml`, chạy `flutter pub get`.
  - Task 0 Step 2: Viết `receipt_text_rows.dart` (`OcrLine`, `buildReceiptRows`) theo TDD, 3/3 tests passed (`receipt_text_rows_test.dart`).
- **Verification**:
  - `flutter analyze lib/features/expenses/receipt/receipt_text_rows.dart test/receipt_text_rows_test.dart`: No issues found.
  - `flutter test test/receipt_text_rows_test.dart`: 3/3 passed.
- **In progress**: Task 0 Step 3–5: Chạy ML Kit trên 10–15 hoá đơn thật để tạo `test/fixtures/receipts/rNN.rows.txt` + `rNN.expected.json` và đánh giá tỉ lệ đọc số tiền.
- **Next**: Khi có dữ liệu hoá đơn thật (hoặc xác nhận bỏ qua thu thập ảnh thật ở Task 0), commit Task 0 và làm Task 1 → 5.
- **Blockers**: Thiếu 10–15 ảnh hoá đơn thật và thao tác chụp/chọn trên thiết bị thật để đo độ chính xác ML Kit.
