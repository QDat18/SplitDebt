# Review vòng 1: Quét hoá đơn (OCR + bộ phân tích quy tắc)

Review của Claude Code trên `820b4b7..ebd35ef`. Áp dụng Global Constraints của `2026-11-25-receipt-ocr.md`.

**Quy tắc chung:** mỗi mục **bắt đầu bằng test hồi quy** dùng đúng các dòng mẫu ghi dưới đây. Các dòng này đã được chạy thử với parser hiện tại và cho kết quả sai. Viết test, xác nhận test FAIL, sửa code, xác nhận PASS. Mỗi mục một commit.

Thay đổi đang chưa commit trong working tree chỉ là thêm dòng trống cuối file. Hãy commit hoặc bỏ trước khi bắt đầu.

## O1. Số lượng hoặc đơn giá dính vào thành tiền làm mất cả món (quan trọng nhất)

**Lỗi:** regex chấp nhận một dấu cách làm dấu phân cách hàng nghìn. Vì vậy `10 15.000 150.000` bị gộp thành một token khổng lồ, vượt ngưỡng 100 triệu, và cả hàng mất hết số tiền.

**Test (`money_parser_test.dart`, `item_row_parser_test.dart`):**
```dart
test('space-separated qty / unit / total stay separate')
  // parseMoneyTokens('Bia Tiger 10 15.000 150.000') → [15000, 150000]
  // parseMoneyTokens('Lau thai 1 350.000 350.000') → [350000, 350000]
  // parseMoneyTokens('Cafe 2 125.000 250.000') → [125000, 250000]
test('space as thousands separator only when the token has no dot/comma')
  // '120 000' → [120000]; '1 250 000' → [1250000]
test('item rows with 3 numbers parse fully')
  // parseItemRow('Bia Tiger 10 15.000 150.000') → qty 10, unit 15000, total 150000
```
**Sửa:** chỉ coi dấu cách là dấu phân cách hàng nghìn khi **cả token** không chứa `.` hay `,` và mỗi nhóm sau dấu cách có đúng 3 chữ số. Nếu một token gộp vượt ngưỡng, thử tách lại theo từng khoảng trắng thay vì bỏ cả hàng.

## O2. Tên món một dòng, số tiền ở dòng dưới

**Lỗi:** hàng chỉ có số không được coi là món. Logic gộp tên món còn nối nhầm hàng chỉ có số vào tên món kế tiếp.

**Test (`rule_based_receipt_parser_test.dart`):**
```dart
test('name row followed by numbers-only row forms one item')
  // rows ['QUAN AN NGON','Bun bo hue','2  50.000  100.000','Com tam  45.000','Tong cong  145.000']
  // → items: ('Bun bo hue', qty 2, total 100000), ('Com tam', total 45000); không có tên chứa chữ số kiểu '2  50.000'
test('mostly-digit rows are never merged into a name')
```
**Sửa:**
- Hàng có số tiền mà có dưới 2 chữ cái, nằm ngay **sau** một hàng chữ (không khớp từ khoá, không phải tên quán, ngày hay SĐT), thì ghép thành một món: tên lấy từ hàng chữ, số liệu lấy từ hàng số.
- Hàng có từ 50% ký tự là chữ số trở lên thì **không bao giờ** được gộp vào tên món.

## O3. Số điện thoại thành món giả

**Lỗi:** `DT 0901 234 567` bị đọc ra token 234567 và trở thành một món.

**Test (`row_classifier_test.dart`, `rule_based_receipt_parser_test.dart`):**
```dart
test('phone numbers are not money')        // parseMoneyTokens('DT 0901 234 567') → []; 'Tel: 0901 234 567' → []; 'Hotline 1900 1234' → []
test('phone rows are ignored')             // classifyRow('ĐT 0901 234 567', ...) → ignore; 'Tel: 028 3822 1234' → ignore
```
**Sửa:**
- Trước khi tìm số tiền, xoá các chuỗi giống SĐT Việt Nam: 9–11 chữ số khi bỏ dấu cách, dấu chấm và gạch; bắt đầu bằng `0`, `+84`, hoặc `1800`/`1900`. Cách làm giống cách đang xoá ngày.
- Thêm `dt`, `tel`, `phone`, `dien thoai` vào nhóm bỏ qua. So khớp theo **từ đứng riêng**, không phải chuỗi con.

## O4. Huỷ chọn ảnh lại báo "không đọc được chữ"

**Sửa:** `ReceiptScanner.scan` trả `Future<List<String>?>`, với `null` khi người dùng huỷ (`pickImage` trả `null`). `ReceiptFlow.run` gặp `null` thì thoát im lặng. Danh sách rỗng (có ảnh nhưng không có chữ) vẫn hiện SnackBar như cũ.

**Test:** nếu `ReceiptFlow` nhận scanner qua constructor thì viết test với scanner giả trả `null` và kiểm tra không có SnackBar. Nếu không thì tách logic quyết định ra một hàm thuần `ScanOutcome classifyScan(List<String>? rows)` và test hàm đó.

## O5. Tổng ở màn xem trước khác tổng điền vào form

**Lỗi:** màn xem trước hiện `receipt.totalAmount` (dòng tổng đọc từ hoá đơn), còn form nhận tổng các món sau phân bổ. Người dùng duyệt một con số nhưng form lưu con số khác.

**Sửa (`receipt_preview_sheet.dart`):**
- Dòng **"TỔNG"** hiện **đúng số sẽ điền vào form**: tính bằng `ReceiptApplier.apply(...).totalAmount`, hoặc tách ra hàm `computeFormTotal(parsed)` dùng chung cho cả hai nơi.
- Khi số đó khác `receipt.totalAmount`, thêm ngay dưới dòng tổng: "Tổng in trên hoá đơn: {x}đ. Có thể đã sót món, hãy kiểm tra." (màu `AppColors.warning`).

**Test (`receipt_preview_sheet_test.dart`):**
- `'total shown equals amount applied to form'`;
- `'printed total shown when different'`.

## O6. Nhận nhầm dòng tổng

**Lỗi:** "Sub Total" bị coi là tổng cuối. Dòng "Khách thanh toán 600.000" (số tiền khách đưa) ghi đè lên tổng thật.

**Test:**
```dart
test('"Sub Total" with a space is subtotal')            // classifyRow('Sub Total 300.000') → subtotal
test('amount paid by customer does not override total') // rows có 'Tổng cộng 550.000' rồi 'Khách thanh toán 600.000' → totalAmount 550000, không có warning lệch do dòng này
```
**Sửa:**
- Thêm `sub total` vào nhóm tạm tính.
- Thêm `khach thanh toan`, `khach tra`, `da thanh toan` vào nhóm **bỏ qua**, đặt **trước** nhóm tổng.
- Chọn tổng theo độ ưu tiên: `tong thanh toan` hoặc `can thanh toan` > `tong cong` > `total`/`tong tien` > `thanh toan`. Cùng độ ưu tiên thì lấy dòng thấp nhất.

## O7. Từ khoá quá ngắn làm bỏ nhầm món và tên quán

**Lỗi:** `the`, `ban`, `sl` khớp trúng các từ thường. "The Coffee House" mất tên quán; "Banh mi the 20.000" bị bỏ.

**Test:**
- `classifyRow('The Coffee House', hasMoney:false)` khác `ignore`;
- `'Banh mi the 20.000'` → `item`;
- `'Thanh toán thẻ 500.000'` → `ignore`;
- `'Số bàn: 12'` → `ignore`;
- `'Bàn 5'` → `ignore`.

**Sửa:** thay các từ trần bằng cụm từ: `thanh toan the`, `quet the`, `so ban`, `ban so`, `ban:`, `sl:`. Riêng `ban` chỉ bỏ qua khi đứng đầu hàng và theo sau là số (`^ban\s*\d+`). So khớp theo ranh giới từ.

## O8. iOS không build được với ML Kit

**Sửa:**
- Nâng `IPHONEOS_DEPLOYMENT_TARGET` trong `ios/Runner.xcodeproj/project.pbxproj` lên **15.5** (mọi cấu hình).
- Tạo `ios/Podfile` từ template chuẩn của Flutter với `platform :ios, '15.5'`. Nếu không chạy được `pod install` trên Windows thì vẫn tạo file, và ghi chú vào PROGRESS là cần kiểm tra trên máy Mac.
- Đối chiếu README của phiên bản `google_mlkit_text_recognition` đang dùng. Nếu yêu cầu khác 15.5 thì dùng con số trong README.

Không có test tự động. Ghi rõ vào PROGRESS.

## O9. Món bị về 0 đồng sau phân bổ

**Sửa (`receipt_applier.dart`):** nếu sau phân bổ có món mang giá ≤ 0 thì **bỏ phân bổ adjustment** (giữ giá gốc của món), và đặt cờ `AppliedReceipt.adjustmentSkipped = true`. Màn xem trước hiện "Không áp được giảm giá/phụ phí, hãy kiểm tra lại.".

**Test:** `'oversized discount does not zero items'`. Món 150.000, giảm 200.000 → mọi món giữ giá dương, `adjustmentSkipped == true`.

## O10. Số lượng đứng giữa đơn giá và thành tiền; "Combo 2"

**Test:**
- `parseItemRow('Cafe 25.000 2 50.000')` → qty 2, unit 25000, total 50000;
- `parseItemRow('Combo 2  99.000')` → name `'Combo 2'`, qty 1.

**Sửa:**
- Khi có 2 token tiền, số nguyên nằm **giữa** hai token là ứng viên số lượng, chấp nhận nếu `qty × unit ≈ total` (lệch ≤ 1.000).
- Số nằm ngay sau tên **chỉ** được coi là số lượng khi có đơn giá thoả điều kiện trên. Nếu không, số đó thuộc về tên.
- Xoá nhánh dự phòng trùng điều kiện (code chết).

## Kiểm tra cuối

`cd frontend; flutter analyze` (0 error) và `flutter test` (PASS, test fixture vẫn được bỏ qua khi chưa có dữ liệu). Cập nhật `docs/PROGRESS.md` và báo lại danh sách commit.
