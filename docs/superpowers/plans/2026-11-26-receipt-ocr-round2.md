# Review vòng 2: Quét hoá đơn

Review của Claude Code trên `ebd35ef..dafa7a2`. Áp dụng Global Constraints của `2026-11-25-receipt-ocr.md`.

Ghi nhận: O8 đặt iOS 15.0 là **đúng**, vì README của `google_mlkit_text_recognition` 1.0.3 ghi tối thiểu 15.0.

**Vấn đề chính:** phần lớn lỗi vòng này do các bản sửa ở vòng 1 gây ra (vá chỗ này hỏng chỗ khác). Vì vậy vòng 2 bắt đầu bằng việc dựng một bộ test hồi quy cố định (R0). Từ nay mọi thay đổi của parser đều phải giữ cho cả bộ này PASS.

Đây là **vòng 2 trên tối đa 3**. Sau vòng này **dừng tự nghĩ thêm trường hợp tổng hợp**, và chỉ tinh chỉnh dựa trên hoá đơn thật (fixture).

Hai thay đổi đang chưa commit (`ios/Podfile`, `test/receipt_flow_test.dart`) chỉ là dòng trống cuối file. Hãy commit hoặc bỏ trước khi bắt đầu.

## R0. Bộ test hồi quy cố định (làm đầu tiên, một commit riêng)

Tạo `frontend/test/receipt_regression_corpus_test.dart`. Dữ liệu là một bảng `(mô tả, rows, kỳ vọng)` và một vòng lặp chạy `RuleBasedReceiptParser` (hoặc `parseMoneyTokens`/`classifyRow`/`parseItemRow` tuỳ dòng).

- Đưa vào bảng **mọi dòng mẫu** đã có ở `2026-11-26-receipt-ocr-round1.md` (O1–O10), với kỳ vọng đúng như file đó ghi.
- Đưa vào bảng **mọi dòng mẫu ở mục R1–R9 bên dưới**.

Lúc đầu các ca của R1–R9 sẽ FAIL. Đánh dấu chúng bằng `skip: 'R?'`, và bỏ `skip` dần khi sửa xong từng mục.

**Quy tắc:** sau này phát hiện thêm dòng sai thì thêm vào bảng này, **không bao giờ xoá** một ca đã có. Nếu hai ca mâu thuẫn nhau thì dừng lại và hỏi.

## R1. Giá đứng sau dấu chấm dẫn hoặc dính dấu câu

Vòng 1 thêm điều kiện xung quanh `(?<![0-9A-Za-z.,])` / `(?![0-9A-Za-z.,])`, làm mất những số tiền đứng sát dấu chấm hoặc dấu phẩy.

**Kỳ vọng:**
- `parseMoneyTokens('Phở bò.........50.000')` → `[50000]`
- `'Tổng cộng: 145.000.'` → `[145000]`
- `'50.000,-'` → `[50000]`
- `'12.5'` → `[]` (vẫn từ chối số thập phân)

**Sửa:** ở hai biên chỉ loại trừ chữ số và chữ cái. Trước khi đối chiếu, xoá các chuỗi dấu chấm dẫn từ 2 dấu trở lên (`\.{2,}` → dấu cách), và xoá dấu `.`/`,`/`-` treo ở cuối token.

## R2. Bộ lọc SĐT xoá nhầm giá

**Kỳ vọng:**
- `parseMoneyTokens('Trà đá 02 5000 10000')` → `[5000, 10000]`
- `'Phở 02 25 000 50 000'` → `[25000, 50000]`
- `'Tổng cộng 19000000'` → `[19000000]`
- Vẫn giữ kết quả cũ: `'DT 0901 234 567'` → `[]`, `'Tel: 028 3822 1234'` → `[]`, `'Hotline 1900 1234'` → `[]`

**Sửa:** chỉ coi là SĐT khi **(a)** trong hàng có từ khoá SĐT (`dt`, `sdt`, `tel`, `phone`, `hotline`, `dien thoai`), **hoặc (b)** chuỗi có dạng nhóm SĐT chuẩn **và** hàng không có phần chữ giống tên món đứng trước. Dạng nhóm chuẩn gồm: `0\d{2,3}[ .-]?\d{3}[ .-]?\d{3,4}`, hoặc 10–11 chữ số liền bắt đầu bằng `0`, hoặc `1800|1900` theo sau là dấu cách hoặc dấu chấm rồi 4 chữ số. Bỏ quy tắc cho phép dấu phân cách giữa mọi chữ số.

## R3. Đơn giá và thành tiền viết kiểu nghìn bằng dấu cách bị gộp

**Kỳ vọng:**
- `parseMoneyTokens('Bia 120 000 240 000')` → `[120000, 240000]`
- `'Bia 2 125 000 250 000'` → `[125000, 250000]`, và `parseItemRow` cho qty 2, unit 125000, total 250000
- `'1 250 000'` → `[1250000]`

**Sửa:** tìm ứng viên theo dạng nghìn bằng dấu cách rồi **kiểm tra lại**. Nếu giá trị vượt ngưỡng hoặc làm hỏng điều kiện `qty × unit ≈ total`, tách ứng viên tại ranh giới nhóm 3 chữ số để có hai token hợp lệ. Cách tách: thử mọi điểm cắt, chọn cách cắt mà cả hai phần đều nằm trong khoảng [1.000; 100.000.000] và ưu tiên phần sau bằng phần trước nhân với một số nguyên nhỏ. Không có cách cắt hợp lệ thì giữ cách xử lý cũ. Viết thành hàm thuần riêng, test kỹ.

## R4. Dòng thanh toán bằng thẻ thành món

**Kỳ vọng:** rows `['Mon A 300.000','Tổng cộng 300.000','Thẻ: 300.000']` → 1 món, `totalAmount` 300000. `classifyRow('Thẻ: 300.000')`, `'VISA 300.000'`, `'ATM 300.000'` → `ignore`. Vẫn giữ: `'Banh mi the 20.000'` → `item`.

**Sửa:** thêm vào nhóm bỏ qua các mẫu `^the\b` (thẻ ở đầu hàng), `the:`, `visa`, `master`, `atm`, `the tin dung`, `momo`, `zalopay`, `vnpay`, `chuyen khoan`. So khớp theo ranh giới từ.

## R5. Dòng tiêu đề cột và số bàn bị dán vào tên món

**Kỳ vọng:**
- rows `['Món SL Giá T.Tiền','Phở bò 50.000']` → món `'Phở bò'`
- rows `['Bàn A1','Phở bò 50.000']` → món `'Phở bò'`
- Vẫn giữ: `'The Coffee House'` không bị bỏ qua.

**Sửa:**
- Thêm vào nhóm "bỏ qua khi hàng không có tiền" các từ đứng riêng `sl`, `gia`, `t.tien`, `tt`, `mat hang`, `ten hang`.
- Thêm mẫu `^ban\s*[a-z]?\d+` (bàn A1, bàn 12).
- Một hàng chứa từ 2 từ tiêu đề cột trở lên thì luôn bị bỏ qua.

## R6. Nhãn tổng kết tách dòng thành món giả

**Kỳ vọng:** rows `['Phở 100.000','Tiền hàng','100.000','Tổng cộng 100.000']` → 1 món, `totalAmount` 100000.

**Sửa:**
- Chỉ ghép "hàng chữ + hàng toàn số" thành món khi cặp đó nằm **trước** hàng tổng, tạm tính hoặc adjustment đầu tiên.
- Thêm `tien hang`, `can tra`, `khach can tra`, `so luong` vào từ khoá: `tien hang` vào nhóm tạm tính; `can tra` và `khach can tra` vào nhóm tổng cuối; `so luong` vào nhóm bỏ qua.
- Hàng chữ khớp bất kỳ từ khoá nào thì không bao giờ được ghép.

## R7. Món đầu tiên bị nhận nhầm là tên quán

**Kỳ vọng:** rows `['HÓA ĐƠN BÁN HÀNG','Bun bo hue','2 50.000 100.000','Com tam 45.000']` → `storeName == null`, có món `'Bun bo hue'` 100000.

**Sửa:** không chọn làm tên quán một hàng mà **ngay sau** nó là hàng toàn số hoặc hàng món. Chỉ chọn hàng nằm trước hàng món đầu tiên **ít nhất 1 hàng**.

## R8. Thứ tự ưu tiên của dòng tổng

**Kỳ vọng:**
- rows `['Món 500.000','Tổng cộng 500.000','VAT 10% 50.000','Tổng tiền thanh toán 550.000']` → `totalAmount` 550000
- rows `['Món 300.000','Tổng tiền 300.000','Giảm giá 30.000','Thanh toán 270.000']` → 270000
- Vẫn giữ (O6): `'Khách thanh toán 600.000'` sau `'Tổng cộng 550.000'` → 550000

**Sửa:** chọn tổng cuối theo quy tắc **"dòng tổng thấp nhất, không phải dòng khách trả hay tiền thừa"**, thay cho bảng ưu tiên theo từ khoá. Ngoại lệ: nếu dòng thấp nhất có giá trị **nhỏ hơn** tổng các món trừ giảm giá quá 1.000 trong khi một dòng tổng phía trên lại khớp, thì dùng dòng khớp đó.

## R9. Món "Tên SL Thành tiền" mất số lượng

**Kỳ vọng:**
- `parseItemRow('Bia Tiger  3  45.000')` → name `'Bia Tiger'`, qty 3
- `'Cơm chiên  2  90.000'` → name `'Cơm chiên'`, qty 2
- Vẫn giữ (O10): `'Combo 2  99.000'` → name `'Combo 2'`, qty 1
- Vẫn giữ: `'Bia 333  3  15.000  45.000'` → name `'Bia 333'`, qty 3

**Sửa:** khi chỉ có một token tiền, số nguyên 1–99 đứng trước nó được coi là **số lượng** nếu cách tên **từ 2 dấu cách trở lên** (dấu hiệu tách cột, do `buildReceiptRows` nối các ô bằng `"  "`) **và** tên không kết thúc bằng các từ `combo`, `set`, `suat`, `phan`, `size`. Số chỉ cách tên **một** dấu cách thì thuộc về tên.

## R10. Cảnh báo lệch ở màn xem trước (nhỏ)

- Chỉ hiện "Tổng in trên hoá đơn…" khi chênh lệch **lớn hơn 1.000**, cùng ngưỡng với parser.
- Khi `adjustmentSkipped` là `true`, chỉ hiện cảnh báo về giảm giá/phụ phí, không hiện "có thể đã sót món".
- Test: `'no printed-total warning within 1000'`, `'only adjustment warning when skipped'`.

## Kiểm tra cuối

- `flutter analyze` 0 error. `flutter test` PASS, **bộ hồi quy R0 không còn ca nào bị skip**, test fixture vẫn bỏ qua khi chưa có dữ liệu.
- Cập nhật `docs/PROGRESS.md` và báo lại danh sách commit.
- **Sau vòng này:** chỉ tinh chỉnh parser khi có fixture hoá đơn thật.
