# Quét hoá đơn (OCR trên máy + bộ phân tích quy tắc) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

> **Cập nhật 2026-11-26:** plan cũ (DeepSeek, backend, quota) đã bị **thay thế hoàn toàn**. Không làm gì ở backend.

**Goal:** Người dùng chụp hoặc chọn ảnh hoá đơn. ML Kit đọc chữ offline, bộ phân tích quy tắc viết bằng Dart tách món, giá, VAT, giảm giá và tổng. App hiện màn xem trước rồi tự điền vào chế độ Chia theo món. Chi phí 0 đồng, không gọi mạng.

**Architecture:** Toàn bộ nằm trong `frontend/lib/features/expenses/receipt/`. `buildReceiptRows` gom chữ thành từng hàng, `RuleBasedReceiptParser` (implements `ReceiptParser`) tạo `ParsedReceipt`, `ReceiptApplier` phân bổ phụ phí cho tổng khớp, `ReceiptPreviewSheet` hiển thị xem trước. Độ chính xác đo trên bộ fixture lấy từ hoá đơn thật.

**Tech Stack:** Flutter, Riverpod 2.5, `image_picker` (đã có), `google_mlkit_text_recognition` (thêm mới), flutter_test.

**Spec:** `docs/superpowers/specs/2026-11-24-receipt-ocr-design.md` (bản cập nhật 2026-11-26). **Đọc toàn bộ spec trước.** Từ khoá, quy tắc, chuỗi tiếng Việt và ngưỡng lấy **nguyên văn** từ spec.

## Global Constraints

- Dependency mới duy nhất được phép: `google_mlkit_text_recognition`. **Không sửa backend.**
- Không đọc, sửa hay commit `.env`. **Không commit `frontend/android/gradle.properties`.** Không push.
- **Không đưa ảnh hoá đơn gốc vào repo.** Fixture chỉ chứa chữ, đã che SĐT, tên nhân viên và mã thẻ.
- Logic thuần (gom dòng, phân tích, phân bổ) không import `google_mlkit_*` hay `flutter/material.dart`, để test chạy thuần Dart.
- Widget có test lấy chữ từ `Theme.of(context).textTheme`, không dùng `AppTypography`/`GoogleFonts`. Màu và khoảng cách lấy từ `AppColors`/`AppDimensions`.
- Chuỗi hiển thị tiếng Việt có dấu, viết hoa kiểu câu, không emoji.
- Mỗi task một commit. Cập nhật `docs/PROGRESS.md` sau mỗi task.
- Kiểm tra: `cd frontend; flutter analyze` (0 error) và `flutter test`.
- Plan hoặc spec mơ hồ, hoặc không khớp với code: dừng lại và hỏi.

## Review Focus

1. **Hoá đơn có "Tiền khách đưa 500.000 / Tiền thừa 164.400":** tổng phải là số tiền thanh toán, không phải 500.000 (Task 2, có fixture).
2. **"Bia 333  3  15.000  45.000":** tên "Bia 333", số lượng 3, thành tiền 45.000 (Task 2).
3. **Hoá đơn ghi "Đã bao gồm VAT 8%":** không cộng VAT thêm (Task 2).
4. **Parser bỏ sót một món:** form vẫn lưu được (tổng bằng Σ món), màn xem trước có cảnh báo lệch (Task 3, Task 4).
5. **Đã nhập tay 2 món rồi quét:** có hỏi trước khi thay, bấm Huỷ thì giữ nguyên (Task 5).

---

### Task 0: Thu thập hoá đơn thật làm fixture

- [ ] **Step 1:** Thêm `google_mlkit_text_recognition` vào `pubspec.yaml` và chạy `flutter pub get`.
- [ ] **Step 2:** Viết `receipt_text_rows.dart` (`OcrLine`, `buildReceiptRows`, theo spec 5.2) **kèm test trước**, `frontend/test/receipt_text_rows_test.dart`:
```dart
test('lines with close centers merge left to right')   // OcrLine('Bò', top 100,bottom 120,left 10) + OcrLine('240.000', top 102,bottom 121,left 300) → ['Bò  240.000']
test('lines on different rows stay separate')
test('empty rows are dropped and limits applied')        // 200 hàng → 150; hàng 300 ký tự → 200
```
- [ ] **Step 3:** Làm một màn tạm (không commit): chọn ảnh, chạy ML Kit (`TextRecognitionScript.latin`), chuyển kết quả sang `OcrLine`, rồi `buildReceiptRows`, in ra console.
- [ ] **Step 4:** Chụp **10–15 hoá đơn quán ăn thật** (nhiều quán khác nhau). Với mỗi hoá đơn, tạo `frontend/test/fixtures/receipts/rNN.rows.txt` (đúng đầu ra, đã che thông tin cá nhân) và `rNN.expected.json` (gõ tay từ hoá đơn) theo đúng schema:
```json
{ "storeName": "…|null", "receiptDate": "yyyy-MM-dd|null", "totalAmount": 335600, "subtotal": 320000,
  "items": [ { "name": "Thịt bò ba chỉ", "quantity": 2, "totalPrice": 240000 } ],
  "adjustments": [ { "type": "vat", "amount": 25600 } ] }
```
- [ ] **Step 5:** Ghi vào `docs/PROGRESS.md`: số hoá đơn, loại (in nhiệt hay A5), và nhận xét về chất lượng đọc dấu tiếng Việt của ML Kit. **Nếu số tiền đọc sai nhiều** (hơn 1/3 số tiền bị đọc sai chữ số) thì **dừng lại và báo**.
- [ ] **Step 6: Commit** (chỉ `pubspec.yaml`, `pubspec.lock` nếu repo đang theo dõi, `receipt_text_rows.dart`, test và fixture). Không commit màn tạm. `git commit -m "feat(receipt): OCR row builder and real receipt fixtures"`

### Task 1: Đọc số tiền và phân loại hàng

**Files (Create):** `receipt/receipt_models.dart` (`ParsedReceipt`, `ParsedItem`, `ParsedAdjustment`, `AdjustmentType`, `ReceiptUnreadable`, theo spec 5.3), `receipt/receipt_keywords.dart`, `receipt/money_parser.dart`, `receipt/row_classifier.dart`
**Test:** `frontend/test/money_parser_test.dart`, `frontend/test/row_classifier_test.dart`

**Interfaces (Produces):**
```dart
String normalizeForMatch(String s);                       // bỏ dấu, chữ thường, gộp khoảng trắng
class MoneyToken { final int value; final int start; final int end; }
List<MoneyToken> parseMoneyTokens(String row);            // theo thứ tự xuất hiện; chỉ token hợp lệ theo spec 5.4 bước 2
enum RowKind { ignore, total, subtotal, vat, service, discount, item, text }
RowKind classifyRow(String row, {required bool hasMoney});
```

- [ ] **Step 1: Viết test thất bại.**
```dart
// money_parser_test.dart
test('parses dot, comma, space and plain thousands')   // '120.000','120,000','120 000','120000' → 120000
test('parses k suffix and currency suffixes')          // '45k','45K' → 45000; '1.250.000đ','1,250,000 VND' → 1250000
test('fixes OCR letters only inside numeric tokens')   // '12O.OOO' → 120000; 'Bia SOL' → không có token
test('rejects decimals and out-of-range values')       // '12.5' → []; '500' → []; '200.000.000' → []
test('returns multiple tokens in order')               // '2  120.000  240.000' → [120000, 240000] (2 bị loại vì < 1000)
test('normalizeForMatch strips Vietnamese marks')      // 'Tổng Thanh Toán' → 'tong thanh toan'
// row_classifier_test.dart
test('cash given and change are ignored')              // 'Tiền khách đưa 500.000', 'Tiền thừa 164.400' → ignore
test('column header without money is ignored')         // 'Tên món  SL  Đơn giá  Thành tiền' → ignore
test('final total vs subtotal')                         // 'Tổng thanh toán 335.600' → total; 'Tổng tiền hàng 320.000' → subtotal
test('vat included is ignored, vat amount is vat')      // 'Đã bao gồm VAT 8%' → ignore; 'VAT 8%  25.600' → vat
test('service and discount')                            // 'Phí dịch vụ 5% 16.000' → service; 'Giảm giá 10.000' → discount
test('item row')                                        // 'Thịt bò ba chỉ  2  120.000  240.000' → item
test('phone and address are ignored')                   // 'ĐT: 0901 234 567', 'Địa chỉ: 12 Lê Lợi' → ignore
```
- [ ] **Step 2: FAIL. Step 3: Viết code.** **Step 4: PASS.**
- [ ] **Step 5: Commit.** `git commit -m "feat(receipt): money token parser and row classifier"` (nhớ `git add`).

### Task 2: Tách món và ráp `RuleBasedReceiptParser`

**Files (Create):** `receipt/item_row_parser.dart`, `receipt/rule_based_receipt_parser.dart` (`abstract class ReceiptParser { ParsedReceipt parse(List<String> rows); }` cùng bản cài)
**Test:** `frontend/test/item_row_parser_test.dart`, `frontend/test/rule_based_receipt_parser_test.dart`, `frontend/test/receipt_fixtures_test.dart`

**Interfaces (Produces):**
```dart
ParsedItem? parseItemRow(String row);                     // theo spec 5.4 bước 4
class RuleBasedReceiptParser implements ReceiptParser { ParsedReceipt parse(List<String> rows); } // ném ReceiptUnreadable khi không có món
```

- [ ] **Step 1: Viết test thất bại.**
```dart
// item_row_parser_test.dart
test('qty, unit price, total')        // 'Thịt bò ba chỉ  2  120.000  240.000' → name 'Thịt bò ba chỉ', qty 2, unit 120000, total 240000
test('only total')                    // 'Nước lẩu Thái  80.000' → qty 1, unit null, total 80000
test('x2 notation')                   // 'Trà đá x2  10.000' → qty 2, total 10000
test('number inside name stays in name')  // 'Bia 333  3  15.000  45.000' → name 'Bia 333', qty 3; 'Combo 2 người  299.000' → name 'Combo 2 người', qty 1
test('qty without unit price')        // 'Cơm chiên  2  90.000' → qty 2, total 90000, unit null (chỉ gán unit khi có token đơn giá thoả qty × unit ≈ total)
// rule_based_receipt_parser_test.dart (rows viết tay trong test)
test('full receipt with vat, discount and change')  // có 'Tiền khách đưa 500.000' → totalAmount = dòng 'Tổng thanh toán'
test('wrapped item name is merged')                 // 'Lẩu hải sản chua cay' / 'đặc biệt  350.000' → name 'Lẩu hải sản chua cay đặc biệt'
test('percent discount uses subtotal')              // 'Tổng tiền hàng 300.000' + 'Giảm giá 10%' → adjustment -30000
test('store name skips phone and address lines')
test('date formats')                                // '07/10/2026', '07-10-2026', '07.10.26' → 2026-10-07
test('mismatch adds warning')                       // món 300.000, tổng 320.000, không có adjustment → warnings không rỗng
test('no total line sums items and warns')
test('no items throws ReceiptUnreadable')
```
`receipt_fixtures_test.dart`: đọc mọi `test/fixtures/receipts/*.rows.txt`, chạy parser, so với `.expected.json`. In ra bảng chỉ số (tổng khớp, tỉ lệ số tiền món đúng, số món đúng) bằng `print`, rồi **assert đúng các ngưỡng ở spec mục 6**, kể cả điều kiện "mọi hoá đơn có lệch tổng đều có warning". Ghép món theo thứ tự xuất hiện. Một món được tính là đúng khi `totalPrice` bằng nhau.
- [ ] **Step 2: FAIL. Step 3: Viết code.** Khi fixture fail, sửa quy tắc hoặc bổ sung từ khoá ở `receipt_keywords.dart`. **Không** sửa `.expected.json` để test pass, trừ khi chính file đó gõ sai so với hoá đơn (ghi rõ lý do trong commit).
- [ ] **Step 4: PASS.** Ghi bảng chỉ số thật vào `docs/PROGRESS.md`.
- [ ] **Step 5: Commit.** `git commit -m "feat(receipt): rule-based receipt parser with fixture accuracy gate"` (nhớ `git add`).

### Task 3: `ReceiptApplier`

**Files (Create):** `receipt/receipt_applier.dart` (`AppliedReceipt`, `ReceiptApplier.apply(ParsedReceipt, DateTime now)`, theo spec 5.5). Dùng lại class `ExpenseItemDetail` hiện có. Nếu class đó nằm trong `create_expense_screen.dart` thì chuyển sang `features/expenses/models/expense_item_detail.dart` và sửa import (không đổi các trường).
**Test:** `frontend/test/receipt_applier_test.dart`

- [ ] **Step 1: Viết test thất bại.**
```dart
test('VAT 8% over 3 items sums exactly')            // món 100000, 150000, 70000; VAT 25600 → Σ price == 345600
test('negative discount is spread')                 // giảm 10000
test('single item takes everything')
test('rounding remainder goes to the most expensive item')
test('quantity > 1 renders as "name xN"')
test('fallback title "Hoá đơn dd/MM"')              // storeName null, receiptDate 2026-10-07 → 'Hoá đơn 07/10'
test('future receipt date is ignored')              // receiptDate = now + 1 ngày → expenseDate null
test('when items miss money, form total equals sum of items')  // totalAmount 400000, Σ món sau phân bổ 345600 → applied.totalAmount == 345600
test('assigned members start empty')
```
- [ ] **Step 2–4:** FAIL, viết code, PASS. **Step 5: Commit.** `git commit -m "feat(receipt): proportional adjustment applier"`

### Task 4: `ReceiptPreviewSheet` và `ReceiptScanner`

**Files (Create):** `receipt/receipt_preview_sheet.dart`, `receipt/receipt_scanner.dart` (`Future<List<String>> scan(ImageSource source)`: `image_picker`, rồi ML Kit, rồi `buildReceiptRows`; luôn `close()` recognizer; người dùng huỷ chọn ảnh thì trả `[]`)
**Modify:** `frontend/ios/Runner/Info.plist`, thêm `NSCameraUsageDescription` = "SplitDebt dùng camera để chụp hoá đơn và ảnh đại diện." và `NSPhotoLibraryUsageDescription` = "SplitDebt cần truy cập thư viện để bạn chọn ảnh hoá đơn hoặc ảnh đại diện.". Nếu đã có thì thống nhất đúng chữ này. `ios/Podfile`: nâng `platform :ios` theo README plugin nếu file tồn tại; nếu không có file thì ghi chú vào PROGRESS.
**Test:** `frontend/test/receipt_preview_sheet_test.dart` (bọc trong `MaterialApp` thường)

- [ ] **Step 1: Viết test thất bại.**
```dart
testWidgets('shows store, date, items, adjustments and total')
testWidgets('shows warnings when present')
testWidgets('shows allocation note only when adjustments exist')   // 'VAT/phí/giảm giá sẽ được chia theo tỉ lệ giá từng món.'
testWidgets('buttons return rescan / use result')                   // pop với enum PreviewAction.rescan / .use
```
- [ ] **Step 2–4:** FAIL, viết code, PASS. `ReceiptScanner` không cần unit test (phụ thuộc plugin) và chỉ kiểm tra bằng tay ở Task 5.
- [ ] **Step 5: Commit.** `git commit -m "feat(receipt): preview sheet, scanner, iOS usage descriptions"` (nhớ `git add`).

### Task 5: Tích hợp vào `CreateExpenseScreen`

**Files:** Modify `frontend/lib/features/expenses/create_expense_screen.dart`. Thay `_scanReceiptOCR` giả bằng luồng thật **theo đúng spec 5.7**. Logic điều phối nên tách vào `receipt/receipt_flow.dart` để file màn hình (đã hơn 1.500 dòng) không to thêm.

- [ ] **Step 1:** Viết luồng: action sheet (Chụp ảnh / Chọn từ thư viện), trạng thái "Đang đọc hoá đơn…" kèm khoá nút, `scan`, `parse`, `ReceiptPreviewSheet`. "Quét lại" thì quay về action sheet. "Dùng kết quả" thì hỏi trước nếu đã có món nhập tay, rồi `apply` và gán vào form.
- [ ] **Step 2:** Các lỗi: rows rỗng thì SnackBar "Không đọc được chữ trên ảnh. Hãy chụp rõ hơn."; `ReceiptUnreadable` thì SnackBar với thông báo của exception; mọi lỗi khác thì "Không quét được hoá đơn. Vui lòng thử lại.". **Form giữ nguyên dữ liệu.**
- [ ] **Step 3:** `flutter analyze`, `flutter test` PASS.
- [ ] **Step 4: Commit.** `git commit -am "feat(receipt): wire receipt scanning into create expense"` (nhớ `git add` file mới).

---

## Hoàn tất: kiểm thử thủ công

- [ ] Android cắm USB: quét **5 hoá đơn thật** từ đầu tới lúc **lưu thành công**. Không gặp lỗi "tổng các món phải bằng tổng khoản chi".
- [ ] Thử: ảnh không có chữ; huỷ chọn ảnh; đã có món nhập tay rồi quét (Huỷ và Đồng ý); hoá đơn bị parser bỏ sót món (thấy cảnh báo, sửa tay được).
- [ ] iOS: quét ít nhất 1 lần khi có máy Mac. Nếu chưa có thì ghi rõ vào `docs/PROGRESS.md`.
- [ ] Ghi vào `docs/PROGRESS.md` bảng chỉ số chính xác thật (từ `receipt_fixtures_test`) để dùng khi thuyết trình. Báo lại danh sách commit.
