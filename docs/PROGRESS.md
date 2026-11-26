# SplitDebt Progress Tracking

- **Status**: Hoàn thành OCR Task 0 (code) và Task 1; đang làm Task 2.
- **Done**:
  - Task 0 (code): `google_mlkit_text_recognition: ^1.0.3`, `receipt_text_rows.dart` (3/3 tests).
  - Task 1: `receipt_models.dart`, `receipt_keywords.dart`, `money_parser.dart`, `row_classifier.dart` (13/13 tests).
- **Verification**:
  - `flutter analyze`: 0 issues; `money_parser_test` & `row_classifier_test`: 13/13 passed.
- **In progress**: Task 2: `item_row_parser.dart`, `rule_based_receipt_parser.dart`, `receipt_fixtures_test.dart`.
- **Next**: Task 3 (`ReceiptApplier`), Task 4 (`ReceiptPreviewSheet` & `ReceiptScanner`), Task 5 (`CreateExpenseScreen` & `ReceiptOcrLabScreen`).
- **Blockers**: Chờ fixture thật để chạy kiểm tra độ chính xác.
