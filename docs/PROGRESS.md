# Tiến độ SplitDebt (Receipt OCR)

## Done
- **Task 1–5 (Core):** Row builder, money parser, row classifier, rule-based parser, proportional applier, preview sheet, scanner, flow, debug OCR lab (`kDebugMode`), wired into `CreateExpenseScreen`.
- **Review vòng 1 (O1–O10):** Đã sửa & commit đầy đủ (iOS deployment target 15.0 + `ios/Podfile` chưa chạy `pod install` vì trên Windows — cần kiểm tra trên máy Mac).
- **Review vòng 2 (R0–R10):**
  - R0: Tạo bộ test hồi quy cố định (`frontend/test/receipt_regression_corpus_test.dart`).
  - R1–R10: Đã sửa và bỏ toàn bộ `skip` trong bộ hồi quy (R7 giữ cả test cũ `'BÚN BÒ HUẾ O XUÂN'` theo lựa chọn người dùng: chỉ loại hàng ngay trước hàng số liệu món).
  - `flutter analyze`: 0 errors. `flutter test`: 176 passed, 1 skipped (`receipt_fixtures_test.dart` — `'Chưa có fixture hoá đơn thật'`).

## In progress
- Chờ fixture thật để chạy kiểm tra độ chính xác (`test/fixtures/receipts/`).

## Next
- Khi có dữ liệu OCR hoá đơn thật, tạo `rNN.rows.txt` và `rNN.expected.json`, chạy `receipt_fixtures_test.dart` và chỉ tinh chỉnh parser theo fixture thật.

## Blockers
- Chưa có fixture hoá đơn thật.
- Chưa chạy `pod install` cho `frontend/ios/Podfile` trên macOS.
