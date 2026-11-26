# SplitDebt Progress Tracking

- **Status**: Hoàn thành OCR Task 0 (code) → Task 3; đang làm Task 4.
- **Done**:
  - Task 0 (code): `google_mlkit_text_recognition: ^1.0.3`, `receipt_text_rows.dart` (3/3 tests).
  - Task 1: `receipt_models.dart`, `receipt_keywords.dart`, `money_parser.dart`, `row_classifier.dart` (13/13 tests).
  - Task 2: `item_row_parser.dart`, `rule_based_receipt_parser.dart` (13/13 unit tests), `receipt_fixtures_test.dart` (skip).
  - Task 3: `expense_item_detail.dart`, `receipt_applier.dart` (9/9 tests).
- **Verification**:
  - `flutter analyze`: 0 errors; Task 0–3 unit tests: 35/35 passed, 1 skipped.
- **In progress**: Task 4: `ReceiptPreviewSheet`, `ReceiptScanner`, iOS `Info.plist`.
- **Next**: Task 5: `CreateExpenseScreen` + `ReceiptOcrLabScreen`.
- **Blockers**: Chờ fixture thật để chạy kiểm tra độ chính xác.
