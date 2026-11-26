# SplitDebt Progress Tracking

- **Status**: Hoàn thành OCR Task 0 (code), Task 1, Task 2; đang làm Task 3.
- **Done**:
  - Task 0 (code): `google_mlkit_text_recognition: ^1.0.3`, `receipt_text_rows.dart` (3/3 tests).
  - Task 1: `receipt_models.dart`, `receipt_keywords.dart`, `money_parser.dart`, `row_classifier.dart` (13/13 tests).
  - Task 2: `item_row_parser.dart`, `rule_based_receipt_parser.dart` (13/13 unit tests), `receipt_fixtures_test.dart` (skip vì chưa có fixture thật).
- **Verification**:
  - `flutter analyze`: 0 issues; Task 1–2 tests: 26/26 passed, 1 skipped (`Chưa có fixture hoá đơn thật`).
- **In progress**: Task 3: `ReceiptApplier` + `ExpenseItemDetail` model extraction.
- **Next**: Task 4 (`ReceiptPreviewSheet` & `ReceiptScanner`), Task 5 (`CreateExpenseScreen` & `ReceiptOcrLabScreen`).
- **Blockers**: Chờ fixture thật để chạy kiểm tra độ chính xác.
