# Review vòng 1: Bước 4a (S0–S6)

Review của Claude Code trên `98eb7e9..18e208e`. Áp dụng các ràng buộc của `2026-11-26-receipt-ocr-smoke-fixes.md`.

**Đã kiểm tra:**
- `flutter analyze`: 0 error. `flutter test`: 212 passed, 1 skipped.
- S0, S1, S3, S4, S5, S6 đúng plan. `ma hd` đã có sẵn từ trước nên không cần thêm.
- Smoke: `foundTotal` 80,3% (đạt), `unreadable` 6,6% (mục tiêu 5%).

## K1. S2 làm mất VAT dạng "tiền chịu thuế + tiền thuế" (lỗi hồi quy, phải sửa)

Hoá đơn quán ăn hay in `VAT 10%  100.000  10.000` (100.000 là tiền chịu thuế, 10.000 là tiền thuế). Điều kiện (a) của S2 ("từ 2 token tiền trở lên") biến hàng này thành hàng số của món. Vì không ghép được với hàng nào, khoản VAT bị mất.

Claude Code đã chạy so sánh code trước (`98eb7e9`) và sau:

| rows | Trước | Sau |
|---|---|---|
| `['Pho bo  100.000','Tong cong  100.000','VAT 10%  100.000  10.000','Tong thanh toan  110.000']` | adjustment VAT 10000, không cảnh báo | không có adjustment, cảnh báo lệch 10.000đ |
| `['Pho bo  100.000','VAT 10%  100.000  10.000','Tong thanh toan  110.000']` | adjustment VAT 10000, không cảnh báo | không có adjustment, cảnh báo lệch 10.000đ |

Đây là lỗi do plan viết điều kiện (a) quá rộng, không phải do Antigravity làm sai.

**Sửa:** một hàng bắt đầu bằng `VAT\s?\d{1,2}%` chỉ được coi là hàng số của món khi thoả một trong hai điều kiện:
- **(b)** hàng ngay phía trên chứa mã vạch (giữ nguyên như hiện tại), **hoặc**
- **(a')** hàng có từ 2 token tiền trở lên **và** hàng ngay phía trên là hàng chữ **không có token tiền nào** và không khớp từ khoá.

**Test (thêm vào bộ hồi quy R0, không xoá ca nào):**
- Hai dòng mẫu trong bảng trên phải cho adjustment VAT 10000, `totalAmount` 110000, không cảnh báo lệch.
- `['000123456 Banh mi sandwich','VAT 10%  12.500  3  37.500','Tong cong  37.500']` → 1 món `Banh mi sandwich` qty 3 total 37500, không có adjustment.
- Ca S2 hiện có vẫn PASS.

## K2. Dòng trống cuối file chưa commit (dọn dẹp)

`docs/datasets.md`, `frontend/tool/vietreceipt_to_rows.dart` và `frontend/test/vietreceipt_converter_test.dart` đang có thay đổi chưa commit, chỉ là thêm dòng trống cuối file. Plan không cho đổi converter, nên **bỏ các thay đổi này** (`git checkout --`) hoặc commit riêng thành `chore: trailing newline`.

## Về chỉ số `unreadable` 6,6%

**Không sửa thêm để ép xuống 5%.** Chỉ còn khoảng 10 file, và theo nguyên tắc dừng của plan tinh chỉnh, tiếp tục vá theo từng file dễ làm hỏng chỗ khác. Ghi vào PROGRESS là "chấp nhận, chờ đo trên fixture có nhãn".

## Kiểm tra cuối

- `flutter analyze` 0 error. `flutter test` PASS.
- Chạy lại smoke và ghi số liệu mới vào PROGRESS. Nếu `foundTotal` tụt dưới 80% thì báo lại.
- Không push.
