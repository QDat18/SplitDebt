# Thiết kế: Quét hoá đơn (OCR + AI đọc hiểu)

**Ngày:** 2026-11-24 · **Trạng thái:** chờ duyệt · **Thay thế:** phần kiến trúc trong `OCR.md` (Cloud Vision + regex)

## 1. Mục đích

Người dùng chụp hoặc chọn ảnh hoá đơn quán ăn thật. App tự điền tên quán, ngày, danh sách món và giá vào màn "Tạo khoản chi" ở chế độ **Chia theo món**. Người dùng xem lại, sửa, gán món cho từng người rồi tự bấm lưu.

- **Để làm gì:** đây là tính năng "wow" khi bảo vệ đồ án. Nó cũng giúp người dùng thật bỏ qua việc gõ tay từng món khi app lên CH Play và App Store.
- **Thế nào là thành công:** demo trên điện thoại cắm USB, quét hoá đơn quán ăn thật. Trong vài giây, danh sách món hiện ra gần đúng, tổng khớp với hoá đơn, và lưu được ngay sau khi gán người.

## 2. Mục tiêu / Không làm / Thất bại dù chạy được

**Mục tiêu**
- Chạy được trên Android và iOS, cùng một luồng.
- Đọc được: tên quán, ngày, các món (tên, số lượng, đơn giá, thành tiền), VAT, phí dịch vụ, giảm giá, tổng tiền.
- Điền sẵn vào chế độ Chia theo món sao cho **tổng các món bằng tổng hoá đơn**, để qua được validation hiện có ở cả app và backend.
- Chi phí AI gần như bằng 0. API key chỉ nằm trên server.

**Không làm (lần này)**
- Không lưu ảnh hoá đơn lên server (trường `receiptUrl` để trống).
- Không tự gán món cho người.
- Không hỗ trợ hoá đơn nhiều trang hay nhiều ảnh, không xử lý PDF.
- Không chạy model AI trên điện thoại, không dùng ONNX.

**Thất bại dù kỹ thuật vẫn chạy**
- Tự lưu khoản chi mà người dùng chưa xác nhận.
- Điền xong nhưng bấm lưu bị lỗi "tổng các món phải bằng tổng khoản chi".
- Lộ API key DeepSeek trong APK hoặc IPA.
- Một người spam quét làm cạn tiền API.
- Mất dữ liệu đã nhập tay khi quét lỗi.

## 3. Ràng buộc

- Backend: Spring Boot 3.3.0, Java 17. App: Flutter, Riverpod 2.5, Dio.
- DeepSeek API chỉ nhận văn bản. Đây là giả định cần xác minh trong Bước 0. Vì vậy OCR phải chạy trên điện thoại.
- Backend sẽ deploy lên server công khai, vì app phát hành trên store. Khi demo bằng USB, dùng `adb reverse tcp:8081 tcp:8081`.
- App đã bắt buộc tổng món bằng tổng tiền (`create_expense_screen.dart:266-277`), và backend `ExpenseServiceImpl.validateItems` cũng kiểm tra như vậy.
- Model món trong app (`ExpenseItemDetail`) chỉ có `name`, `price`, `assignedMemberIds`. App luôn gửi `quantity: 1`.
- Chữ trên hoá đơn được gửi tới DeepSeek (bên thứ ba). Khi lên store, phải ghi việc này vào chính sách quyền riêng tư, vào mục Data safety của CH Play và vào privacy label của App Store.
- Dependency mới được phép, chỉ cho tính năng này: `image_picker`, `google_mlkit_text_recognition` (Flutter). Backend **không** thêm SDK mới; gọi DeepSeek bằng `RestClient` có sẵn trong Spring 6.1.

## 4. Các phương án đã cân nhắc

| Phương án | Ưu | Nhược | Kết luận |
|---|---|---|---|
| Cloud Vision + regex (OCR.md cũ) | Có toạ độ chữ tốt | Phải bật Billing; regex vỡ với hoá đơn thật | Loại: người dùng chọn AI đọc hiểu |
| Gửi ảnh → backend → Claude (Opus/Haiku) | Chính xác nhất, ít code | Tốn tiền theo lượt quét | Loại: người dùng thấy đắt |
| Model local (PaddleOCR + Ollama, hoặc ONNX trên máy) | Miễn phí | Không phục vụ được người dùng store; LLM trên điện thoại không thực tế | Loại |
| **ML Kit trên máy → chữ → backend → DeepSeek → JSON** | OCR miễn phí, offline; AI rẻ vì chỉ gửi chữ; key ở server | Hoá đơn mờ hoặc nhàu đọc kém hơn; dấu tiếng Việt cần thử | **Đã chọn** |

## 5. Thiết kế

### 5.1 Luồng

```
[App] Quét bill → chọn Camera/Thư viện (image_picker)
   → ML Kit TextRecognizer(script: latin) → RecognizedText (blocks/lines + boundingBox)
   → gom dòng theo toạ độ Y → List<String> rows (trái→phải, trên→dưới)
   → POST /api/v1/receipts/parse {rows}
[Backend] ReceiptController → ReceiptService
   → kiểm tra quota → DeepSeekClient (JSON mode) → validate + chuẩn hoá → ReceiptParseResponse
[App] Hiện màn xem trước kết quả → "Dùng kết quả" → điền vào form Chia theo món
```

### 5.2 App: gom dòng (`receipt_text_rows.dart`, hàm thuần, test được)

Hoá đơn thường có tên món bên trái và giá bên phải, nhưng ML Kit có thể tách chúng thành hai block khác nhau. Cách xử lý:
- Lấy mọi `TextLine` kèm `boundingBox`.
- Sắp theo tâm Y.
- Hai line thuộc cùng một hàng nếu chênh tâm Y nhỏ hơn `0.5 × chiều cao trung bình của line`.
- Trong mỗi hàng, sắp theo X rồi nối bằng `"  "` (hai dấu cách).

Kết quả là `List<String>`, mỗi phần tử một hàng. Bỏ hàng rỗng. Tối đa 150 hàng, mỗi hàng tối đa 200 ký tự.

Hàm có signature `List<String> buildReceiptRows(List<OcrLine> lines)`, trong đó `OcrLine {String text; double top, bottom, left;}` là kiểu riêng để test không phụ thuộc ML Kit.

### 5.3 Backend: API

`POST /api/v1/receipts/parse` (cần JWT)

Request:
```json
{ "rows": ["NHÀ HÀNG ABC", "Thịt bò ba chỉ  2  120.000  240.000", "VAT 8%  25.600", "TỔNG CỘNG  345.600"] }
```

Response 200, theo envelope `ApiResponse` giống các controller khác:
```json
{
  "storeName": "Nhà hàng ABC",
  "receiptDate": "2026-10-07",
  "currency": "VND",
  "items": [
    { "name": "Thịt bò ba chỉ", "quantity": 2, "unitPrice": 120000, "totalPrice": 240000 }
  ],
  "adjustments": [
    { "type": "VAT", "label": "VAT 8%", "amount": 25600 },
    { "type": "DISCOUNT", "label": "Giảm giá thành viên", "amount": -10000 }
  ],
  "totalAmount": 345600,
  "warnings": ["Tổng các món và phụ phí lệch 1.000đ so với tổng hoá đơn"]
}
```

- `type` ∈ `VAT | SERVICE | DISCOUNT | OTHER`. `DISCOUNT` luôn âm, các loại khác dương.
- Tiền là số (`BigDecimal`), không có dấu phân cách.
- `storeName`, `receiptDate` có thể là `null`.

Lỗi:
| Mã | Khi nào | Thông báo (tiếng Việt) |
|---|---|---|
| 400 | `rows` rỗng hoặc quá giới hạn | "Không đọc được chữ trên ảnh. Hãy chụp rõ hơn." |
| 422 | AI không tìm thấy món nào hoặc JSON không hợp lệ sau 1 lần thử lại | "Không nhận ra hoá đơn. Hãy thử ảnh khác hoặc nhập tay." |
| 429 | Vượt quota ngày | "Bạn đã dùng hết lượt quét hôm nay (20 lượt)." |
| 503 | DeepSeek lỗi, timeout, hoặc chưa cấu hình key | "Dịch vụ quét đang bận. Vui lòng thử lại sau." |

### 5.4 Backend: các thành phần

- `ReceiptController`: chỉ nhận request, lấy user hiện tại, gọi service, bọc `ApiResponse`.
- `ReceiptService`: điều phối 4 việc: kiểm tra quota → gọi extractor → validate và chuẩn hoá → tăng quota (chỉ khi thành công).
- `ReceiptExtractor` (interface): `ReceiptParseResponse extract(List<String> rows)`. Bản cài: `DeepSeekReceiptExtractor`. Interface này cho phép sau này đổi nhà cung cấp mà không sửa service.
- `DeepSeekReceiptExtractor`: `RestClient` gọi `POST {base-url}/chat/completions`, `model` lấy từ cấu hình, `response_format: {"type":"json_object"}`, `temperature: 0`.
  - System prompt mô tả đúng schema ở 5.3, quy tắc tiền Việt ("120.000" và "120,000" đều là 120000), và yêu cầu bỏ qua địa chỉ, SĐT, số bàn, mã hoá đơn.
  - Timeout 20 giây.
  - JSON parse lỗi thì thử lại 1 lần, vẫn lỗi thì trả 422.
- `ReceiptNormalizer` (hàm thuần, test kỹ nhất):
  - Bỏ món có `totalPrice ≤ 0` hoặc tên rỗng.
  - Nếu thiếu `totalPrice` thì tính `quantity × unitPrice`.
  - Ép dấu của adjustment theo `type`.
  - Làm tròn về số nguyên (VND).
  - Nếu `totalAmount` null thì gán bằng tổng món cộng tổng adjustment.
  - Nếu `|tổng món + tổng adjustment − totalAmount| > 1000` thì thêm warning.
  - Không còn món nào thì ném lỗi 422.
- `OcrUsage` (entity, bảng `ocr_usage`): `userId`, `usageDate` (LocalDate), `count`, ràng buộc unique trên (`userId`, `usageDate`). Quota mặc định **20 lượt/người/ngày**.
- Cấu hình trong `application.yaml`, giá trị lấy từ biến môi trường:
  ```yaml
  app.receipt:
    deepseek-api-key: ${DEEPSEEK_API_KEY:}
    deepseek-base-url: ${DEEPSEEK_BASE_URL:https://api.deepseek.com}
    deepseek-model: ${DEEPSEEK_MODEL:deepseek-chat}
    daily-quota: ${RECEIPT_DAILY_QUOTA:20}
  ```
  Key rỗng thì endpoint trả 503; ứng dụng vẫn khởi động bình thường.
- 422/429/503 cần exception riêng (ví dụ `ReceiptUnreadableException`, `ReceiptQuotaExceededException`, `ReceiptServiceUnavailableException`) và handler tương ứng trong `GlobalExceptionHandler`, trả `ApiResponse.error(code, message)`.
- Không log nội dung `rows` hay phản hồi AI ở mức INFO, vì hoá đơn có thể chứa tên hoặc SĐT. Chỉ log độ dài và thời gian xử lý.

### 5.5 App: điền vào form

`ReceiptApplier` (hàm thuần trong `features/expenses/receipt/`), test kỹ:
- **Phân bổ adjustment vào món theo tỉ lệ thành tiền.** Mỗi món nhận `round(totalAdjustment × totalPrice_i / Σ totalPrice)`. Phần dư do làm tròn cộng vào món đắt nhất. Nhờ vậy `Σ price == totalAmount` chính xác đến từng đồng.
- Mỗi món thành một `ExpenseItemDetail(name: <tên> hoặc "<tên> x<qty>" nếu qty > 1, price: <giá đã phân bổ>, assignedMemberIds: [])`.
- Sau khi điền:
  - `_totalAmount = totalAmount`.
  - `_titleController` = `storeName` (nếu trống thì `"Hoá đơn dd/MM"`).
  - `_expenseDate` = `receiptDate` nếu có và không nằm ở tương lai.
  - `_splitMode = SplitMode.item`.
- Nếu form đang có món nhập tay, hỏi trước khi ghi đè: "Thay danh sách món hiện tại bằng kết quả quét?"

### 5.6 App: màn xem trước (bottom sheet)

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
│ ⚠ Tổng lệch 1.000đ, hãy kiểm tra │
├──────────────────────────────────┤
│ VAT/phí/giảm giá sẽ được chia    │
│ theo tỉ lệ giá từng món.         │
│  [ Quét lại ]   [ Dùng kết quả ] │
└──────────────────────────────────┘
```

Trạng thái:
- **Đang đọc ảnh, đang phân tích:** spinner kèm chữ "Đang đọc hoá đơn…". Nút Quét bị khoá trong lúc này.
- **Lỗi:** SnackBar hiện thông báo theo bảng ở 5.3, form giữ nguyên dữ liệu.
- **ML Kit không ra chữ nào:** báo lỗi ngay, không gọi backend.

### 5.7 Nền tảng

- **Android:** `image_picker` không cần thêm quyền với Photo Picker. Camera thì `image_picker` tự xử lý. ML Kit Latin dùng model kèm trong app (bundled), nên app nặng thêm vài MB.
- **iOS:** thêm `NSCameraUsageDescription` và `NSPhotoLibraryUsageDescription` (bằng tiếng Việt) vào `Info.plist`. ML Kit đòi iOS deployment target tối thiểu theo tài liệu của plugin (kiểm tra ở bước làm), có thể phải nâng `platform :ios` trong Podfile. Phải build trên máy Mac.

## 6. Bước 0: xác minh trước khi code (spike, không giữ code)

1. **DeepSeek:** xác nhận API chỉ nhận text, endpoint `/chat/completions` tương thích OpenAI, `response_format: json_object` chạy được với model đang chọn, và giá hiện tại.
2. **ML Kit tiếng Việt:** chụp 5 hoá đơn thật và in `rows` ra console. Tiêu chí đạt: số tiền đúng ≥ 90%, tên món đọc được (sai dấu chấp nhận được). Nếu không đạt thì dừng lại và quay về bàn phương án.
3. **Một lần gọi tay:** gửi `rows` thật tới DeepSeek với prompt ở 5.4, kiểm tra JSON trả về.

## 7. Kiểm thử

- **Backend unit:**
  - `ReceiptNormalizer`: ép dấu, tính thiếu `totalPrice`, cảnh báo lệch, không có món → lỗi.
  - `DeepSeekReceiptExtractor` với `MockRestServiceServer`: JSON hợp lệ; JSON hỏng rồi thử lại; timeout → 503; key rỗng → 503.
- **Backend tích hợp (MockMvc, profile test, extractor mock):** 401 khi không có token; 400 khi rows rỗng; 429 ở lượt thứ 21 trong ngày; quota không tăng khi extractor lỗi.
- **App unit:**
  - `buildReceiptRows`: hai line cùng hàng được gộp, khác hàng được tách.
  - `ReceiptApplier`: phân bổ VAT 8% trên 3 món cho tổng khớp từng đồng; giảm giá âm; một món duy nhất; tổng không chia hết.
- **Thủ công:** 5 hoá đơn thật trên Android qua USB, và ít nhất 1 lần trên iOS.

## 8. Quyết định của Claude (bạn kiểm tra giúp)

1. VAT, phí dịch vụ, giảm giá **được chia theo tỉ lệ giá món**, thay vì thành một dòng riêng chia đều cho mọi người.
2. Quota **20 lượt/người/ngày**, lưu trong DB, chỉ trừ khi quét thành công.
3. Món có số lượng > 1 thành **một dòng** "Tên x2", không tách thành nhiều dòng (dù app chỉ hỗ trợ gán cả dòng cho một nhóm người).
4. Không lưu ảnh hoá đơn.
5. Endpoint đặt ở `/api/v1/receipts/parse`, theo kiểu `/api/v1/expenses`.

## 9. Để người triển khai tự quyết

Tên class và file chi tiết, cách viết system prompt (miễn đúng schema), giao diện bottom sheet (theo `AppColors`), cách tách `create_expense_screen.dart` (1.566 dòng) để thêm logic mà không làm file to thêm, ví dụ đưa code quét vào `features/expenses/receipt/`.
