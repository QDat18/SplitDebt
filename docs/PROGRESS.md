# SplitDebt Progress Tracking

- **Status**: Chờ fixture thật để chạy kiểm tra độ chính xác.
- **Done**:
  - Task 0 (code): `google_mlkit_text_recognition: ^1.0.3`, `receipt_text_rows.dart` (3/3 tests).
  - Task 1: `receipt_models.dart`, `receipt_keywords.dart`, `money_parser.dart`, `row_classifier.dart` (13/13 tests).
  - Task 2: `item_row_parser.dart`, `rule_based_receipt_parser.dart` (13/13 unit tests), `receipt_fixtures_test.dart` (skip).
  - Task 3: `expense_item_detail.dart`, `receipt_applier.dart` (9/9 tests).
  - Task 4: `receipt_preview_sheet.dart`, `receipt_scanner.dart`, `ios/Runner/Info.plist` (4/4 tests; `ios/Podfile` chưa có trong repo).
  - Task 5 (tích hợp UI): `receipt_flow.dart`, `create_expense_screen.dart`, `receipt_ocr_lab_screen.dart` (chỉ hiện khi `kDebugMode`).
- **Verification**:
  - `flutter analyze`: 0 errors; `flutter test`: 109 passed, 1 skipped (`Chưa có fixture hoá đơn thật`).
- **In progress**: Chờ fixture thật để chạy kiểm tra độ chính xác.
- **Next**: Khi có dữ liệu OCR từ hoá đơn thật (qua `ReceiptOcrLabScreen`), tạo `rNN.rows.txt` + `rNN.expected.json` và tinh chỉnh parser đạt ngưỡng $\ge 80\%$ tổng, $\ge 85\%$ món.
- **Blockers**: Chưa có fixture hoá đơn thật.
