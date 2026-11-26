# Thiết kế: Quét hoá đơn (OCR trên máy + bộ phân tích quy tắc)

**Ngày:** 2026-11-24 · **Cập nhật:** 2026-11-26 (bỏ DeepSeek, chuyển sang bộ phân tích quy tắc chạy trong app) · **Trạng thái:** đã duyệt hướng đi
**Thay thế:** phần kiến trúc trong `OCR.md` (Cloud Vision + regex trên server)

## 1. Mục đích

Người dùng chụp hoặc chọn ảnh hoá đơn thật: **hoá đơn quán ăn hoặc quán cà phê, và hoá đơn siêu thị hoặc cửa hàng tiện lợi** (bổ sung 2026-11-26). App tự điền tên quán, ngày, danh sách món và giá vào màn "Tạo khoản chi" ở chế độ **Chia theo món**. Người dùng xem lại, sửa, gán món cho từng người rồi tự bấm lưu.

Thành công khi: demo trên điện thoại cắm USB, quét hoá đơn in nhiệt của quán thật. Danh sách món hiện ra gần đúng, tổng khớp hoá đơn (hoặc có cảnh báo rõ ràng khi lệch), và lưu được ngay sau khi gán người.

Khi thuyết trình, gọi tính năng là **"OCR trên thiết bị + bộ phân tích quy tắc"**. Đây không phải AI.

## 2. Mục tiêu / Không làm / Thất bại dù chạy được

**Mục tiêu**
- Chạy được trên Android và iOS. **Hoàn toàn offline, chi phí 0 đồng,** không gọi mạng ra ngoài, không cần API key.
- Đọc được: tên quán, ngày, các món (tên, số lượng, đơn giá, thành tiền), VAT, phí dịch vụ, giảm giá, tổng tiền.
- Điền sẵn vào chế độ Chia theo món sao cho **tổng các món bằng tổng hoá đơn**.
- **Đo được độ chính xác** trên bộ hoá đơn thật (mục 6), không dùng con số đoán.

**Không làm**
- Không dùng LLM hay dịch vụ AI bên ngoài, không có endpoint backend, không có quota.
- Không lưu ảnh hoá đơn. Không tự gán món cho người. Không hỗ trợ hoá đơn nhiều ảnh hay PDF.

**Thất bại dù chạy được**
- Tự lưu khoản chi mà người dùng chưa xác nhận.
- Điền xong nhưng bấm lưu bị lỗi "tổng các món phải bằng tổng khoản chi".
- Lấy "Tiền khách đưa" hoặc "Tiền thừa" làm tổng hoá đơn.
- Coi số trong tên món ("Bia 333") là giá hay số lượng.
- Mất dữ liệu đã nhập tay khi quét lỗi.
- Hiển thị kết quả sai mà không cảnh báo, khi tổng các món lệch tổng hoá đơn.

## 3. Ràng buộc

- Flutter, Riverpod 2.5. Dependency mới được phép duy nhất là `google_mlkit_text_recognition`; `image_picker` đã có.
- App đã bắt buộc tổng món bằng tổng tiền (`create_expense_screen.dart`, khoảng dòng 266-277), và backend `ExpenseServiceImpl.validateItems` cũng kiểm tra như vậy.
- Model món trong app (`ExpenseItemDetail`) chỉ có `name`, `price`, `assignedMemberIds`.
- ML Kit nhận diện chữ chạy trên máy và miễn phí. Model Latin làm app nặng thêm vài MB.

## 4. Các phương án đã cân nhắc

| Phương án | Ưu | Nhược | Kết luận |
|---|---|---|---|
| Cloud Vision + regex (OCR.md cũ) | Toạ độ chữ tốt | Phải bật Billing | Loại |
| Gửi ảnh cho Claude | Chính xác nhất | Tốn tiền theo lượt | Loại: chi phí |
| ML Kit + DeepSeek trên backend (bản thiết kế trước) | Hiểu hoá đơn lạ tốt | Cần API key, quota, chuyển dữ liệu ra nước ngoài, phải có đồng ý riêng | Loại: chi phí, quyền riêng tư, độ phức tạp |
| Model local (PaddleOCR/ONNX/LLM trên máy) | Miễn phí | Nặng, chậm, công sức lớn | Loại |
| **ML Kit + bộ phân tích quy tắc bằng Dart trong app** | 0 đồng, offline, dữ liệu không rời máy, test được bằng unit test | Kém hơn LLM với hoá đơn lệch cột nặng hoặc viết tắt lạ | **Đã chọn** |

Có interface `ReceiptParser` để sau này thêm bản cài dùng LLM mà không phải sửa luồng.

## 5. Thiết kế (toàn bộ nằm trong `frontend/lib/features/expenses/receipt/`)

### 5.1 Luồng

```
Bấm "Quét hoá đơn" → chọn Camera hoặc Thư viện (image_picker)
 → ML Kit TextRecognizer(script: latin) → các TextLine kèm boundingBox
 → buildReceiptRows(lines) → List<String> rows
 → RuleBasedReceiptParser.parse(rows) → ParsedReceipt
 → ReceiptPreviewSheet (xem trước, có cảnh báo) → "Dùng kết quả"
 → ReceiptApplier.apply(parsed, now) → điền vào form Chia theo món
```

### 5.2 Gom dòng: `buildReceiptRows(List<OcrLine> lines) → List<String>`

`OcrLine {String text; double top, bottom, left;}` là kiểu riêng, để test không phụ thuộc ML Kit.

- Sắp các line theo tâm Y. Hai line thuộc cùng một hàng nếu chênh tâm Y nhỏ hơn `0.5 × chiều cao trung bình`.
- Trong mỗi hàng, sắp theo X rồi nối bằng `"  "` (2 dấu cách).
- Bỏ hàng rỗng. Tối đa 150 hàng, mỗi hàng tối đa 200 ký tự.

### 5.3 Kết quả phân tích: `ParsedReceipt`

```dart
class ParsedReceipt {
  String? storeName; DateTime? receiptDate;
  List<ParsedItem> items;              // ParsedItem {String name; int quantity; int? unitPrice; int totalPrice;}
  List<ParsedAdjustment> adjustments;  // ParsedAdjustment {AdjustmentType type; String label; int amount;}  // DISCOUNT âm
  int? subtotal;                       // "Tổng tiền hàng", "Tạm tính", "Cộng tiền hàng"
  int totalAmount;                     // tổng cuối
  List<String> warnings;
}
enum AdjustmentType { vat, service, discount, other }
```

Tiền là số nguyên VND.

### 5.4 Bộ phân tích quy tắc: `RuleBasedReceiptParser implements ReceiptParser`

Các bước chạy theo thứ tự. Mỗi bước là một hàm thuần, test riêng được.

1. **Chuẩn hoá hàng:** bỏ dấu tiếng Việt và đưa về chữ thường để so khớp từ khoá (`normalizeForMatch`), nhưng giữ bản gốc để hiển thị tên món.
2. **Đọc số tiền** (`parseMoneyTokens(row) → List<MoneyToken>`), lấy từ phải sang trái:
   - nhận các dạng `120.000`, `120,000`, `120 000`, `120000`, `45k`, `45K`, `1.250.000đ`, `1,250,000 VND`;
   - sửa lỗi OCR **chỉ trong token đã giống số**: `O`/`o`→`0`, `l`/`I`→`1`, `S`→`5`, `B`→`8`;
   - token có phần lẻ thập phân kiểu `12.5` **không** được coi là tiền;
   - số tiền hợp lệ khi từ 1.000 tới 100.000.000.
3. **Phân loại hàng** theo từ khoá (so trên chuỗi đã chuẩn hoá). Thứ tự ưu tiên:
   - **Bỏ qua:** `tien khach dua`, `khach dua`, `tien thua`, `tra lai`, `tien mat`, `chuyen khoan`, `the`, `don gia`, `thanh tien` khi hàng **không** có số tiền (đó là dòng tiêu đề cột), `sl`, `ban`, `gio vao`, `gio ra`, `thu ngan`, `nhan vien`, `hotline`, `dt:`, `sdt`, `mst`, `dia chi`, `wifi`, `cam on`, `hen gap lai`, `so hd`, `ma hd`, `hoa don`;
   - **Tổng cuối:** `tong thanh toan`, `thanh toan`, `tong cong`, `tong tien`, `total`, `can thanh toan`;
   - **Tạm tính:** `tong tien hang`, `tam tinh`, `cong tien hang`, `subtotal`;
   - **VAT:** `vat`, `thue`. Hàng có `da bao gom` hoặc `included` thì **bỏ qua**, không cộng VAT thêm;
   - **Phí dịch vụ:** `phi dich vu`, `service`, `phi phuc vu`;
   - **Giảm giá:** `giam gia`, `chiet khau`, `khuyen mai`, `discount`, `voucher`. Nếu có `%` mà không có số tiền thì quy ra tiền theo tạm tính, nếu không có tạm tính thì theo tổng các món;
   - **Món:** hàng còn lại có ít nhất 1 số tiền và có phần chữ (≥ 2 chữ cái) ở bên trái số tiền đầu tiên.
4. **Tách món** (`parseItemRow`):
   - số tiền cuối cùng là `totalPrice`;
   - nếu có số tiền kế cuối và `số lượng × số tiền kế cuối ≈ totalPrice` (lệch ≤ 1.000) thì đó là `unitPrice`;
   - **số lượng** là số nguyên nhỏ từ 1 tới 99, đứng ngay trước các số tiền hoặc dạng `x2`/`2x`. Không có thì bằng 1;
   - **tên món** là phần chữ bên trái phần số. Số dính liền với chữ trong tên (`Bia 333`, `Combo 2 người`, `Lẩu 3 ngăn`) **thuộc về tên** nếu nó đứng trước một chữ cái, hoặc nếu không thoả quy tắc số lượng × đơn giá.
5. **Gộp tên món xuống dòng:** hàng không có số tiền, không khớp từ khoá nào, nằm **ngay trên** một hàng món, có từ 2 tới 40 ký tự, không phải tên quán, thì nối vào đầu tên món đó.
6. **Tên quán:** trong 5 hàng đầu, lấy hàng đầu tiên có từ 4 ký tự chữ trở lên và không khớp từ khoá bỏ qua, SĐT, địa chỉ hay ngày.
7. **Ngày:** regex `dd/MM/yyyy`, `dd-MM-yyyy`, `dd.MM.yyyy`, `dd/MM/yy` trên toàn bộ hoá đơn, lấy kết quả đầu tiên hợp lệ.
8. **Tổng và tự kiểm tra:**
   - `totalAmount` = số tiền trên hàng tổng cuối cùng (nằm thấp nhất).
   - Không có hàng tổng thì `totalAmount` = tổng món + tổng adjustment, kèm warning "Không tìm thấy dòng tổng, đã cộng từ các món.".
   - Nếu `|Σ món + Σ adjustment − totalAmount| > 1.000` thì thêm warning "Tổng các món lệch {x}đ so với tổng hoá đơn. Hãy kiểm tra lại.".
   - Nếu có `subtotal` và `|Σ món − subtotal| > 1.000` thì thêm warning về tạm tính.
   - Không có món nào thì ném `ReceiptUnreadable("Không nhận ra món nào trên hoá đơn. Hãy chụp rõ hơn hoặc nhập tay.")`.

Danh sách từ khoá đặt trong một file hằng (`receipt_keywords.dart`) để bổ sung dần khi gặp hoá đơn mới.

### 5.4b Quy tắc riêng cho hoá đơn siêu thị và cửa hàng tiện lợi (bổ sung 2026-11-26)

Hoá đơn siêu thị khác hoá đơn quán ăn ở các điểm sau. Các quy tắc dưới đây được thêm vào các bước của 5.4 và không thay quy tắc cũ.

1. **Mã vạch:** một dãy liền 8–14 chữ số (EAN/UPC hoặc mã hàng) **không phải tiền**.
   - Hàng chỉ có mã vạch thì bỏ qua.
   - Mã vạch ở đầu hàng món thì cắt khỏi tên món.
   - Mã vạch đứng riêng trên hàng ngay trên tên món thì không được gộp vào tên.
2. **Hàng cân** (số lượng thập phân kèm đơn vị), ví dụ `0,512 kg x 89.000 = 45.568` hoặc `0.512 KG  89.000  45.568`:
   - `totalPrice` = số tiền cuối, `unitPrice` = số tiền kế cuối;
   - `quantity` = 1, và thêm phần khối lượng vào tên: `"<tên> (0,512 kg)"`;
   - đơn vị nhận dạng: `kg`, `g`, `gr`, `l`, `lit`, `ml`;
   - quy tắc "từ chối số thập phân" ở bước 2 vẫn giữ: khối lượng không bao giờ là token tiền.
3. **Dạng "SL x đơn giá"**, ví dụ `2 x 15.000  30.000` hoặc `2 x 15.000 = 30.000`, thường nằm ở hàng dưới tên món: dùng quy tắc ghép "hàng chữ + hàng toàn số", với `quantity` lấy từ số đứng trước `x`.
4. **Bỏ qua thêm:** `tong so luong`, `tong sl`, `so mat hang`, `so luong mat hang`, `diem tich luy`, `diem thuong`, `diem`, `ma kh`, `ma khach hang`, `the thanh vien`, `hang thanh vien`, `quay`, `pos`, `ca`, `thu ngan`, `so hd`, `so phieu`, `ngay in`. Riêng `diem`, `ca` và `quay` chỉ so theo **từ đứng riêng** ở đầu hàng.
5. **"(Đã gồm VAT)" / "Giá đã bao gồm thuế":** dòng tổng có cụm này là tổng cuối, không cộng VAT thêm. Bảng tóm tắt thuế cuối hoá đơn kiểu `Thuế suất 8%  Tiền thuế 12.345` thì **bỏ qua**, vì đó chỉ là thông tin.
6. **Khuyến mãi theo từng món** (`KM`, `CK`, `Giảm giá`, `-5.000` ngay dưới một món): coi là adjustment loại `discount` và phân bổ theo tỉ lệ như mọi adjustment khác. Không gán riêng cho món đó, để giữ đơn giản.
7. **Số lượng món lớn** (30–80 món) là bình thường. Bộ phân tích không được giới hạn số món, ngoài giới hạn 150 hàng của `buildReceiptRows`.

### 5.4c Chọn "Chỉ dùng tổng tiền" (bổ sung 2026-11-26, quyết định của Claude)

Hoá đơn siêu thị nhiều món thì chia theo từng món rất mệt. Màn xem trước có thêm nút phụ **"Chỉ dùng tổng tiền"** bên cạnh "Dùng kết quả". Bấm vào thì:
- `_totalAmount` = tổng in trên hoá đơn (`receipt.totalAmount`);
- tiêu đề và ngày lấy như ở 5.5;
- chuyển sang chế độ **chia đều** (`SplitMode.equal`), không điền món.

### 5.5 Điền vào form: `ReceiptApplier.apply(ParsedReceipt, DateTime now) → AppliedReceipt`

`AppliedReceipt {List<ExpenseItemDetail> items; int totalAmount; String title; DateTime? expenseDate;}`

- **Phân bổ adjustment vào món theo tỉ lệ thành tiền.** Mỗi món nhận `round(Σadj × totalPrice_i / Σ totalPrice)`. Phần dư do làm tròn cộng vào món đắt nhất. Nhờ vậy `Σ price == totalAmount` chính xác.
- **Nếu còn lệch giữa tổng món sau phân bổ và `totalAmount`** (do bộ phân tích bỏ sót món), **không** tự dồn tiền. Dùng `Σ price` làm `totalAmount` của form, để form luôn hợp lệ. Màn xem trước đã cảnh báo, và người dùng tự sửa.
- Tên món: `"<tên> x<qty>"` khi `qty > 1`.
- Tiêu đề: `storeName`, không có thì `"Hoá đơn dd/MM"` (theo ngày hoá đơn, không có thì theo `now`).
- `expenseDate` = `receiptDate`, trừ khi ngày đó nằm ở tương lai thì để `null`.

### 5.6 Màn xem trước: `ReceiptPreviewSheet`

```
┌──────────────────────────────────┐
│ Kết quả quét · Nhà hàng ABC      │
│ 07/10/2026                       │
├──────────────────────────────────┤
│ Thịt bò ba chỉ x2       240.000  │
│ Nước lẩu Thái            80.000  │
│ ─────────────────────────────── │
│ VAT 8%                  +25.600  │
│ Giảm giá                -10.000  │
│ TỔNG                    335.600  │
│ ⚠ Tổng các món lệch 1.000đ…      │
├──────────────────────────────────┤
│ VAT/phí/giảm giá sẽ được chia    │
│ theo tỉ lệ giá từng món.         │
│  [ Quét lại ]   [ Dùng kết quả ] │
│        Chỉ dùng tổng tiền        │  ← nút chữ, xem 5.4c
└──────────────────────────────────┘
```

Chữ lấy từ `Theme.of(context).textTheme`, màu lấy từ `AppColors`. Dòng chú thích chỉ hiện khi có adjustment.

### 5.7 Tích hợp vào `CreateExpenseScreen`

- Nút "Quét hoá đơn" (thay hàm giả `_scanReceiptOCR`). Bấm thì hiện action sheet: "Chụp ảnh" / "Chọn từ thư viện".
- Trong lúc đọc: hiện "Đang đọc hoá đơn…" và khoá nút.
- ML Kit không ra chữ nào → SnackBar "Không đọc được chữ trên ảnh. Hãy chụp rõ hơn.". Gặp `ReceiptUnreadable` → SnackBar với thông báo của exception. Dữ liệu trong form giữ nguyên.
- Form đang có món nhập tay thì hỏi trước: "Thay danh sách món hiện tại bằng kết quả quét?".
- "Dùng kết quả": gán `AppliedReceipt` vào form và chuyển `_splitMode = SplitMode.item`.

### 5.8 Nền tảng

- **iOS:** thêm `NSCameraUsageDescription` và `NSPhotoLibraryUsageDescription` (chữ thống nhất với spec quyền riêng tư mục 6.4). Có thể phải nâng `platform :ios` trong Podfile theo README của plugin ML Kit.
- **Android:** không cần quyền mới, vì `image_picker` dùng intent chụp ảnh và Photo Picker.

## 6. Dữ liệu thật và đo độ chính xác (bắt buộc)

- **Task 0:** chụp **10–15 hoá đơn quán ăn thật**, càng nhiều quán khác nhau càng tốt, cả hoá đơn in nhiệt lẫn hoá đơn in A5. Dùng một màn tạm in `rows` (đầu ra của `buildReceiptRows`) ra console, rồi lưu mỗi hoá đơn thành:
  - `frontend/test/fixtures/receipts/r01.rows.txt`: mỗi hàng một dòng, đúng như OCR trả về;
  - `frontend/test/fixtures/receipts/r01.expected.json`: kết quả đúng do người đọc hoá đơn gõ tay (tên quán, ngày, các món với `totalPrice`, adjustment, tổng).
- **Không lưu ảnh gốc vào repo.** Xoá hoặc che SĐT, tên nhân viên, mã thẻ trong file `.txt` nếu có.
- `frontend/test/receipt_fixtures_test.dart` chạy parser trên mọi fixture và in ra bảng chỉ số:
  - **tổng khớp:** `totalAmount` đúng;
  - **số tiền món đúng:** tỉ lệ món có `totalPrice` khớp, ghép theo thứ tự;
  - **số món đúng.**
- Mỗi file `expected.json` có thêm trường `"type": "restaurant" | "supermarket"`. Bảng chỉ số in **theo từng loại** và tổng chung.
- **Ngưỡng tối thiểu để test pass** (áp **riêng cho từng loại** có ít nhất 5 hoá đơn, và cho tổng chung):
  - tổng khớp ở ≥ 80% số hoá đơn;
  - số tiền món đúng ≥ 85% (tính gộp mọi món);
  - mọi hoá đơn có lệch tổng đều có warning (không có trường hợp sai mà im lặng).

  Đây là **ngưỡng tối thiểu do Claude đặt**. Con số thật được ghi vào `docs/PROGRESS.md` và dùng khi thuyết trình.

## 7. Kiểm thử

- **Unit:**
  - `parseMoneyTokens` (mọi định dạng ở 5.4 bước 2, sửa lỗi OCR, từ chối `12.5` và số dưới 1.000);
  - phân loại hàng (mỗi nhóm từ khoá, "đã bao gồm VAT", dòng tiêu đề cột);
  - `parseItemRow` (3 số, `x2`, "Bia 333", "Combo 2 người");
  - gộp tên xuống dòng; tên quán; ngày;
  - giảm giá theo %;
  - không có món → `ReceiptUnreadable`;
  - `buildReceiptRows`; `ReceiptApplier` (VAT 8% trên 3 món khớp từng đồng, giảm giá âm, 1 món, phần dư, `x2`, tiêu đề dự phòng, ngày ở tương lai, trường hợp lệch giữ `Σ price`).
- **Fixture:** như mục 6.
- **Widget:** `ReceiptPreviewSheet` (hiển thị đủ các phần, warning, dòng chú thích).
- **Thủ công:** quét 5 hoá đơn thật từ đầu tới lúc lưu thành công trên Android qua USB; thử ít nhất 1 lần trên iOS khi có máy Mac.

## 8. Quyết định của Claude

1. Bộ phân tích chạy **trong app**, không chạy ở backend.
2. Lệch tổng thì **không tự dồn tiền** vào món; dùng tổng các món làm tổng của form và cảnh báo.
3. Ngưỡng chính xác tối thiểu: **80% tổng khớp, 85% số tiền món đúng** trên bộ fixture.
4. Món có số lượng lớn hơn 1 giữ thành một dòng `"Tên xN"`.
5. Không lưu ảnh hoá đơn, không đưa ảnh gốc vào repo.
6. Hỗ trợ hoá đơn siêu thị theo 5.4b. Khuyến mãi theo món được phân bổ theo tỉ lệ cho cả hoá đơn, không gán riêng cho món.
7. Thêm nút "Chỉ dùng tổng tiền" (5.4c) cho hoá đơn nhiều món.
