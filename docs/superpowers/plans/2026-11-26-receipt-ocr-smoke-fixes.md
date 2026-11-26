# Tinh chỉnh từ smoke test VietReceipt (Bước 4a)

Claude Code đã phân tích 200 file smoke (commit `98eb7e9`): 103 file tìm được tổng, 57 file không tìm được tổng, 40 file `ReceiptUnreadable`. Đây là **dữ liệu thật**, nên việc sửa ở đây đúng tinh thần của plan tinh chỉnh (`2026-11-26-receipt-ocr-tuning-phase.md`, Bước 4). Không phải tự nghĩ thêm ca tổng hợp.

Áp dụng Global Constraints của `2026-11-25-receipt-ocr.md`.

**Ràng buộc bắt buộc:**
- **Không chép nguyên văn dòng nào từ VietReceipt vào repo** (giấy phép nghiên cứu). Ca test trong bộ hồi quy R0 phải **giữ nguyên định dạng nhưng đổi tên món, số tiền và mã số**. Các dòng mẫu dưới đây đã được đổi sẵn.
- Bộ hồi quy R0 chỉ được thêm ca, không xoá ca. Nếu hai ca mâu thuẫn nhau thì dừng lại và hỏi.
- Mỗi mục: viết test, xác nhận FAIL, sửa, xác nhận PASS. Mỗi mục một commit.

## S0. Báo cáo smoke chi tiết (làm đầu tiên)

`test/receipt_external_smoke_test.dart`:
- Ghi một dòng cho mỗi file vào `test/fixtures/external/smoke_report.tsv` (thư mục này đã bị gitignore), gồm: trạng thái `OK` / `NOTOTAL` / `UNREAD` / `BROKEN_ROWS`, tên file, số hàng, số món, tổng.
- **`BROKEN_ROWS`**: file có **6 hàng trở xuống**. Đây phần lớn là ảnh xoay hoặc nghiêng làm việc gom hàng gộp cả hoá đơn vào vài hàng (ví dụ `UIT-MLReceipts_test_001301`), do dữ liệu chứ không phải lỗi parser. Đếm riêng loại này và **loại khỏi mẫu số** khi tính tỉ lệ.
- In ra: `foundTotal` trên số file đọc được, `unreadable` trên số file đọc được, và số `BROKEN_ROWS`.
- Chạy lại một lần và ghi số liệu **trước khi sửa** vào PROGRESS.

## S1. Số tiền có phần thập phân `.00` (quan trọng nhất)

Hoá đơn Co.opMart, Co.op Food và nhiều siêu thị in tiền dạng `25,000.00`. Hiện `parseMoneyTokens` trả `[]`, nên cả hoá đơn bị coi là không đọc được.

**Kỳ vọng:**
- `parseMoneyTokens('VAT10%  3  6,000.00  18,000.00')` → `[6000, 18000]`
- `'72,350.00'` → `[72350]`
- `'5.000,00'` → `[5000]`
- `'-8,250.00'` → giá trị 8250 (dấu âm xử lý như hiện tại)
- Vẫn giữ: `'12.5'` → `[]`, `'0.670'` → `[]`

**Sửa:** trước khi đối chiếu, nếu token kết thúc bằng `.00` hoặc `,00` **và** phần đứng trước là một số có phân cách nghìn hợp lệ theo ký tự còn lại, thì bỏ đuôi đó. Chỉ chấp nhận đúng 2 chữ số `00`. Không chấp nhận phần thập phân khác 0.

## S2. Dòng số của món bắt đầu bằng `VAT10%` / `VAT05%`

Hoá đơn Co.op in mã thuế ở đầu dòng số của từng món, nằm dưới dòng `<mã vạch> <tên món>`.

**Kỳ vọng:** rows `['00000001234567 Banh quy bo hop','VAT10%  2  15,000.00  30,000.00','00000007654321 Sua chua it duong','VAT05%  1  8,500.00  8,500.00','Tong so tien thanh toan:  38,500.00']` → 2 món (`Banh quy bo hop` qty 2 total 30000; `Sua chua it duong` total 8500), không có adjustment VAT, `totalAmount` 38500.

**Vẫn giữ:** `'VAT 10% 50.000'` nằm sau dòng tổng (R8) vẫn là adjustment.

**Sửa:** một hàng bắt đầu bằng `VAT\s?\d{1,2}%` thì được coi là **hàng số của món** (bỏ phần `VATxx%` rồi xử lý như hàng toàn số, ghép với hàng chữ phía trên) khi thoả một trong hai điều kiện: **(a)** hàng có từ 2 token tiền trở lên, hoặc **(b)** hàng chữ ngay phía trên chứa mã vạch. Các trường hợp khác giữ cách xử lý cũ.

## S3. Dòng cân nặng đứng riêng sau món

**Kỳ vọng:** rows `['00000002950001 Ca rot Da Lat kg','VAT05%  30,000.00  12,600.00','0.420 KG','Tong so tien thanh toan:  12,600.00']` → 1 món tên `'Ca rot Da Lat kg (0,420 kg)'`, total 12600. Hàng `0.420 KG` không phải món và không phải tiền.

**Sửa:** hàng chỉ gồm `số thập phân + đơn vị` (`kg`, `g`, `gr`, `l`, `lit`, `ml`, không phân biệt hoa thường) và nằm ngay sau một món thì gắn vào tên món đó theo quy ước của 5.4b. Hàng như vậy đứng ở chỗ khác thì bỏ qua.

## S4. Nhãn tổng và số tiền nằm ở hai hàng khác nhau

**Kỳ vọng:**
- rows `['Mon A  50,000.00','Mon B  42,000.00','92,000.00','Tong so tien thanh toan:  4','Tong so luong hang:']` → `totalAmount` 92000. Số `4` là số lượng hàng, không phải tiền.
- rows `['Mon A  1  60,000  60,000','Mon B  1  28,000  28,000','Tổng số:  2  88,000','Tổng cộng :','Tiền khách trả:  VND  88,000']` → `totalAmount` 88000.

**Sửa:**
- Hàng tổng **không có token tiền hợp lệ** (dưới 1.000 không tính) thì lấy hàng toàn số liền **trên**, nếu hàng đó chưa thuộc món nào; nếu không có thì lấy hàng toàn số liền **dưới**. Không lấy hàng khớp từ khoá bỏ qua (khách trả, tiền thừa).
- `tong so:` theo sau là một số nhỏ và một token tiền thì là ứng viên tổng, ưu tiên thấp nhất (chỉ dùng khi không có dòng tổng nào khác).

## S5. Từ khoá bỏ qua còn thiếu

**Kỳ vọng:** `classifyRow` → `ignore` cho:
- `'Tien thoi lai ====>  -1,500.00'`
- `'Gia goc:  9,900.00'`
- `'Bao gom thue GTGT 10%:  1,200.00'`
- `'Phuong thuc thanh toan:'`
- `'So the:  XXX'`
- `'Ma HD: ABCDEF 10:20'`

**Sửa:** thêm vào nhóm bỏ qua: `tien thoi lai`, `tien thoi`, `gia goc`, `bao gom thue`, `phuong thuc thanh toan`, `so the`, `ma hd`. So khớp theo ranh giới từ.

## S6. Hoá đơn chỉ có "Cộng tiền hàng", không có dòng tổng cuối

**Kỳ vọng:** rows `['HOA DON','Nuoc rua chen 750ml','1  42,000  42,000','Cộng tiền hàng  42,000','Cám ơn quý khách']` → `totalAmount` 42000, **không** có warning `Không tìm thấy dòng tổng`.

**Sửa:** không có dòng tổng cuối, có dòng tạm tính và không có adjustment → dùng tạm tính làm tổng, không cảnh báo.

## Kiểm tra cuối

- `flutter analyze` 0 error. `flutter test` PASS, bộ hồi quy R0 không còn ca nào bị skip.
- Chạy lại smoke test. Ghi vào PROGRESS bảng **trước/sau** cho `foundTotal`, `unreadable` và `BROKEN_ROWS`.
- **Mục tiêu tham khảo** (tính trên file không thuộc `BROKEN_ROWS`): `foundTotal` ≥ 80%, `unreadable` ≤ 5%. Chưa đạt thì **báo lại 10 file `NOTOTAL`/`UNREAD` đầu tiên** cùng lý do. Không tự sửa thêm ngoài S1–S6.
- Không đổi `buildReceiptRows` và converter trong vòng này.
- Không push.

## Ghi chú về tập kiểm tra giữ riêng

Khi chọn ảnh để tạo fixture có nhãn (Bước 1b), **chỉ lấy ảnh `UIT-MLReceipts` split `test` có số từ `001600` trở lên**. Lý do: 100 file smoke đã được xem để sửa quy tắc, và dải `001502`–`001545` cũng đã bị chạy thử, liệt kê từng file lỗi (cập nhật 2026-11-26). Dải `001500`–`001599` từ nay là **tập kiểm tra phụ**: được chạy lại để so trước/sau, nhưng **không được sửa quy tắc theo từng file trong dải này**. Ảnh `MC-OCR` (split `train`) dùng cho tinh chỉnh. Độ chính xác báo cáo cuối cùng tính trên tập giữ riêng.
