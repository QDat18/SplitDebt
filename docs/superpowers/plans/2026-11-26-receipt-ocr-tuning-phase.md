# Quét hoá đơn: giai đoạn tinh chỉnh bằng hoá đơn thật

Đã đủ 3 vòng review/sửa với các trường hợp tổng hợp (round1 → round2 → review cuối trên `dafa7a2..b1b9ccd`). Theo quy tắc, **không mở thêm vòng vá dựa trên ca tự nghĩ**. Từ đây mọi thay đổi của parser chỉ dựa trên **dữ liệu thật**, cộng với bộ hồi quy cố định.

**Trạng thái hiện tại (Claude Code đã tự xác minh):**
- `flutter test`: 176 test PASS, 1 test bỏ qua (fixture).
- Bộ hồi quy R0 còn nguyên: chỉ bị bỏ `skip`, không ca nào bị xoá hay đổi kỳ vọng.
- Luồng quét → xem trước → điền form chạy được. Màn xem trước cho sửa trước khi lưu, nên lỗi phân tích không làm mất dữ liệu.

Áp dụng Global Constraints của `2026-11-25-receipt-ocr.md`.

## Bước 0: Hỗ trợ hoá đơn siêu thị (code, làm trước khi có dữ liệu)

App quét **cả hoá đơn siêu thị và cửa hàng tiện lợi**, đã ghi vào spec mục 5.4b và 5.4c. Đây là **phạm vi mới**, không phải vá thêm ca tổng hợp cho phần cũ.

- [ ] **0.1, quy tắc siêu thị (spec 5.4b, mục 1–7):**
  - Mỗi mục là một commit. Viết test trước, test **thêm vào bộ hồi quy R0**, dòng mẫu **tự viết**, không chép từ bộ dữ liệu.
  - Các ca tối thiểu:
    - `'8934563123456'` → không có token tiền, hàng bị bỏ qua;
    - `'8934563123456 Sữa tươi Vinamilk 1L  32.000'` → item `'Sữa tươi Vinamilk 1L'`;
    - `'Thịt heo ba rọi'` + `'0,512 kg x 89.000 = 45.568'` → item `'Thịt heo ba rọi (0,512 kg)'`, qty 1, total 45568;
    - `'Mì Hảo Hảo'` + `'2 x 4.500  9.000'` → item qty 2, total 9000;
    - `'Tổng số lượng: 12'`, `'Điểm tích luỹ 320'`, `'Quầy 03'`, `'Mã KH: 001234'` → ignore;
    - `'Tổng tiền (đã gồm VAT) 512.000'` → total, và không cộng VAT thêm;
    - `'Thuế suất 8%  Tiền thuế 12.345'` → ignore;
    - `'KM -5.000'` ngay dưới một món → discount 5000;
    - hoá đơn 40 món (sinh trong test bằng vòng lặp) → đủ 40 món.
  - **Toàn bộ test cũ và bộ hồi quy phải vẫn PASS.** Nếu có ca mâu thuẫn thì dừng lại và hỏi.
- [ ] **0.2, nút "Chỉ dùng tổng tiền" (spec 5.4c):**
  - `ReceiptPreviewSheet` có thêm `PreviewAction.totalOnly`.
  - `ReceiptFlow` xử lý action này: gán tổng, tiêu đề và ngày, chuyển `SplitMode.equal`, không điền món. Nếu form đang có món nhập tay thì vẫn hỏi trước như "Dùng kết quả".
  - Widget test: `'total-only button returns totalOnly'`. Nếu `ReceiptFlow` test được thì thêm test gán đúng tổng và chuyển chế độ.
- [ ] **0.3:** sửa schema `expected.json` để có `"type": "restaurant" | "supermarket"`. Sửa `receipt_fixtures_test.dart` để in và kiểm ngưỡng **theo từng loại**, theo spec mục 6.
- [ ] `flutter analyze` 0 error, `flutter test` PASS, cập nhật PROGRESS. Mỗi mục một commit.

## Bước 1: Chủ dự án thu thập dữ liệu

- **Mục tiêu có nhãn: ít nhất 8 hoá đơn siêu thị và ít nhất 6 hoá đơn quán ăn.**
  - Hoá đơn siêu thị chủ yếu lấy từ bộ dữ liệu ở Bước 1b.
  - Hoá đơn quán ăn: **ít nhất 3–5 tấm do chính nhóm chụp** (loại dùng khi demo), phần còn lại lấy từ bộ dữ liệu nếu tìm được.
  - Nếu nhóm có hoá đơn siêu thị thật (Co.op, Bách Hoá Xanh, WinMart, cửa hàng tiện lợi...) thì quét thêm 1–2 tấm.
- Mở **Phòng thử OCR** (chỉ có ở bản debug), quét từng tấm, bấm "Sao chép".
- Gửi cho Antigravity từng hoá đơn gồm hai phần: (a) các dòng OCR vừa sao chép, (b) nội dung đúng của hoá đơn, gõ tay hoặc gửi kèm ảnh để Antigravity tự đọc. Nội dung đúng gồm tên quán, ngày, từng món kèm số lượng và thành tiền, VAT/phí/giảm giá, và tổng thanh toán.

## Bước 1b: Nguồn bổ sung, bộ dữ liệu VietReceipt OCR (Kaggle)

**Bộ dữ liệu:** `hpgiakhang1405/vietreceipt-ocr`, gồm 2.530 ảnh và khoảng 102.000 vùng chữ, mỗi vùng có toạ độ đa giác và nội dung đã được người kiểm duyệt. Lấy từ hai bộ MC-OCR 2021 và UIT-MLReceipts. Định dạng JSONL: `{id, image, width, height, split, ocr: [{id, polygon, text, legibility}]}`. **Không có** nhãn tên quán, món hay tổng tiền.

**Giấy phép:** chỉ cho nghiên cứu, phi thương mại, theo điều khoản của hai bộ gốc. Vì repo có thể công khai, **không commit ảnh, chữ hay bất cứ thứ gì lấy từ bộ này.** Mọi dữ liệu từ bộ này chỉ nằm trong `frontend/test/fixtures/external/` (bị gitignore).

**Chủ dự án làm:**
- Tải bộ dữ liệu (khoảng 581 MB, cần tài khoản Kaggle) về một thư mục **ngoài repo**, ví dụ `D:\datasets\vietreceipt-ocr\`.
- Chọn **khoảng 8–10 ảnh hoá đơn siêu thị hoặc cửa hàng tiện lợi** (nhiều chuỗi khác nhau, có cả hàng cân nếu có) và **những ảnh hoá đơn quán ăn hoặc quán cà phê tìm được**, chép vào điện thoại. Mở Phòng thử OCR, bấm "Chọn từ thư viện", sao chép kết quả, rồi gửi cho Antigravity kèm tên file ảnh.

**Antigravity làm:**

1. **Chặn commit:** thêm `test/fixtures/external/` vào `frontend/.gitignore`. Commit riêng thay đổi này.
2. **Script chuyển đổi** `frontend/tool/vietreceipt_to_rows.dart`, chạy bằng `dart run tool/vietreceipt_to_rows.dart <annotations.jsonl> <out_dir> [--limit N]`. Viết bằng Dart thuần, chỉ import `receipt_text_rows.dart` của app.
   - Với mỗi ảnh: bỏ các vùng có `legibility == "unreadable"`. Mỗi vùng còn lại tạo thành `OcrLine(text, top: minY, bottom: maxY, left: minX)` theo toạ độ đa giác. Gọi `buildReceiptRows`, rồi ghi ra `<out_dir>/<id>.rows.txt`.
   - Không chép ảnh.
   - Kèm unit test cho phần chuyển đa giác sang `OcrLine`, dùng một bản ghi JSONL viết tay trong test, **không** dùng dữ liệu thật: `frontend/test/vietreceipt_converter_test.dart`.
   - Commit script và test (không có dữ liệu).
3. **Test chịu tải** `frontend/test/receipt_external_smoke_test.dart`. Đọc mọi `test/fixtures/external/smoke/*.rows.txt`; thư mục không tồn tại thì `skip` kèm lời nhắn "Chưa có dữ liệu VietReceipt (bị gitignore)". Với mỗi file:
   - parser chỉ được phép ném `ReceiptUnreadable`, mọi exception khác làm test FAIL;
   - mọi kết quả có lệch tổng (theo quy tắc ở spec 5.4 bước 8) đều phải có warning.

   Test in ra số file, tỉ lệ tìm được dòng tổng, tỉ lệ `ReceiptUnreadable`. **Không đặt ngưỡng chính xác**, vì không có nhãn. Chủ dự án chạy script với `--limit 200` để tạo dữ liệu cho thư mục `smoke/`.
4. **Fixture có nhãn từ bộ dữ liệu:** với các ảnh chủ dự án quét bằng ML Kit ở trên, lưu vào `test/fixtures/external/labeled/rNN.rows.txt` (chữ do ML Kit đọc) và `rNN.expected.json` (gõ tay từ ảnh). Sửa `receipt_fixtures_test.dart` để đọc **cả** `test/fixtures/receipts/` lẫn `test/fixtures/external/labeled/` (thư mục nào không có thì bỏ qua), và in bảng chỉ số **theo từng nguồn** cùng tổng chung. Ngưỡng ở spec mục 6 áp cho tổng chung.
5. **Ghi nguồn:** tạo `docs/datasets.md`, nêu tên bộ dữ liệu, hai bộ gốc kèm DOI (MC-OCR: 10.1109/RIVF51545.2021.9642077; UIT-MLReceipts: 10.21553/rev-jec.330), điều khoản sử dụng, và việc dữ liệu không được đưa vào repo. Dùng tài liệu này khi viết báo cáo.

Ở Bước 4, lỗi xuất hiện trong test chịu tải (exception, hoá đơn lệch tổng mà không có cảnh báo) cũng được tính là "có thật" và được sửa. Nếu thêm ca vào bộ hồi quy R0 thì **tự viết lại dòng mẫu** cùng dạng lỗi, không chép nguyên văn chữ từ bộ dữ liệu.

## Bước 2: Antigravity lập fixture

- Mỗi hoá đơn tạo `frontend/test/fixtures/receipts/rNN.rows.txt` (đúng các dòng OCR) và `rNN.expected.json` (theo schema ở Task 0 của plan OCR, **cộng thêm trường `"type"`**). Hoá đơn lấy từ VietReceipt thì đặt vào `test/fixtures/external/labeled/` thay cho thư mục trên.
- **Che** SĐT, tên nhân viên, mã thẻ và mã giao dịch bằng cách thay chữ số bằng `x`, giữ nguyên độ dài. **Không bịa** dữ liệu, không đưa ảnh vào repo.
- Commit: `test(receipt): add real receipt fixtures rNN–rMM`.

## Bước 2B: Fixture từ văn bản chuẩn của VietReceipt (phương án đang dùng, 2026-11-26)

Chủ dự án chưa quét được đủ ảnh qua ML Kit. Vì vậy Bước 3–5 chạy trên **văn bản chuẩn do con người gõ** trong VietReceipt (đầu ra của converter). Con số đo được là **độ chính xác của bộ phân tích khi chữ đã đọc đúng**, chưa tính lỗi đọc chữ của ML Kit. Báo cáo phải ghi rõ điều này.

**Chia hai tập, không được trộn:**

| Tập | Nguồn | Số lượng | Thư mục (đã gitignore) | Dùng để |
|---|---|---|---|---|
| Tinh chỉnh | `mc_ocr`, **bỏ 100 bản ghi đầu** (đã dùng cho smoke) | 15 | `test/fixtures/external/labeled/` | Bước 3, 4: được xem lỗi và sửa quy tắc |
| Giữ riêng | `uit_mlreceipts`, ảnh số **từ `001600` trở lên** | 15 | `test/fixtures/external/holdout/` | Chỉ chạy **một lần** ở Bước 5 |

**Quy tắc chọn và gắn nhãn:**
- Lấy theo thứ tự trong file JSONL, không chọn lọc theo độ dễ. Bỏ qua file có từ 6 hàng trở xuống (ảnh xoay) và ghi số file bị bỏ qua.
- `expected.json` lấy **trực tiếp từ văn bản chuẩn**: tổng thanh toán, từng món (tên, số lượng, thành tiền), adjustment, `type`. Ghi tên món đúng như văn bản (bỏ mã vạch).
- Văn bản chuẩn **thiếu hoặc mơ hồ** (mất dòng tổng, không rõ đâu là món) thì **bỏ qua hoá đơn đó**, ghi lý do. Không đoán.
- Không commit bất cứ thứ gì trong `external/`.

**Code (commit riêng):**
- Tạo `test/receipt_holdout_test.dart`: đọc `external/holdout/`, tính cùng chỉ số như `receipt_fixtures_test`, và chỉ chạy khi có `--dart-define=RUN_HOLDOUT=true` (`const bool.fromEnvironment('RUN_HOLDOUT')`). Mặc định thì `skip`. Không áp ngưỡng (chỉ in số), để không ai sửa quy tắc theo tập này.
- Không mở hay in nội dung tập giữ riêng trong lúc làm Bước 4.

Fixture ML Kit thật (ảnh `001863`, ảnh nhóm tự chụp) vẫn được thêm vào `test/fixtures/receipts/` khi có, và báo cáo thành một dòng riêng.

## Bước 3: Đo lần đầu, chưa sửa gì

- Chạy `flutter test test/receipt_fixtures_test.dart`. Ghi **bảng chỉ số ban đầu** vào `docs/PROGRESS.md`: tổng khớp, tỉ lệ số tiền món đúng, số món đúng, và danh sách hoá đơn sai kèm lý do ngắn gọn.

## Bước 4: Tinh chỉnh theo dữ liệu

Chỉ sửa những lỗi **có xuất hiện trong fixture thật**, theo thứ tự lỗi nào làm sai nhiều hoá đơn nhất thì sửa trước.

Khi sửa, đối chiếu với **danh sách ứng viên** dưới đây (từ review cuối). Ca nào thực sự gặp trong dữ liệu thật thì sửa và **thêm vào bộ hồi quy R0**. Ca nào không gặp thì để nguyên, không sửa trước.

| # | Ứng viên | Dòng mẫu | Kỳ vọng |
|---|---|---|---|
| C1 | SĐT không có từ khoá | `Liên hệ 0912 345 678`, `09 1234 5678` | không có token tiền |
| C2 | Thẻ MASTERCARD | `MASTERCARD ****1234  250.000` | ignore |
| C3 | Dòng tổng phụ phía dưới lớn hơn tổng thật | `Tổng thanh toán 180.000` rồi `Tổng tiền tích lũy 2.000.000` | total 180000 |
| C4 | "giá" tính trùng làm mất dòng giảm giá | `Giảm giá mặt hàng  -20.000`, `Giảm giá TT 10%: 20.000` | discount |
| C5 | Món tiếng Anh bắt đầu bằng "The" | `The Classic Burger  89.000` | item |
| C6 | Ghi chú khuyến mãi không có tiền chặn việc ghép món sau đó | `Khuyến mãi mua 1 tặng 1` ở giữa danh sách món | các món sau vẫn được ghép |
| C7 | Mã giao dịch dài bị tách thành tiền | `Mã GD 112 233 445 566` | không có token tiền |
| C8 | Tên món chứa "giá/tt/sl" bị bỏ | `Phở gia truyền` rồi `2  50.000  100.000` | item "Phở gia truyền" |
| C9 | Số cuối tên bị hiểu là số lượng | `Cơm tấm  Số  3  45.000` | qty 1 (chỉ sửa nếu gặp thật) |
| C10 | Ẩn cảnh báo lệch khi bỏ qua phân bổ | — | so với tổng chỉ gồm các món |

**Quy tắc tinh chỉnh:**
- Mỗi thay đổi phải giữ **toàn bộ** bộ hồi quy và mọi fixture đang PASS. Nếu một thay đổi làm fixture khác sai đi thì bỏ thay đổi đó.
- Không sửa `.expected.json` để test pass, trừ khi chính file đó gõ sai so với hoá đơn (ghi lý do trong commit).
- Dừng khi đạt ngưỡng ở spec mục 6 (80% tổng khớp, 85% số tiền món đúng, mọi hoá đơn lệch tổng đều có cảnh báo), **hoặc** sau 2 lượt tinh chỉnh mà vẫn chưa đạt. Trường hợp thứ hai thì báo lại kèm số liệu để chủ dự án quyết định.

## Bước 5: Báo cáo

- Ghi bảng chỉ số **trước và sau** tinh chỉnh vào `docs/PROGRESS.md`.
- Sau khi chốt code, chạy **một lần** `flutter test test/receipt_holdout_test.dart --dart-define=RUN_HOLDOUT=true` và ghi kết quả thành dòng riêng "Tập giữ riêng". **Đây là số liệu dùng khi thuyết trình.** Không sửa quy tắc sau khi đã xem kết quả này.
- Đánh dấu Task 5 của plan OCR là hoàn tất khi đạt ngưỡng.
- Báo lại danh sách commit.
