# Tiến độ SplitDebt (Receipt OCR)

## Done
- **Task 1–5 + Review vòng 1 & 2 + Bước 0 + Bước 1b + S0–S6 + K1–K2 + X1–X2:** Hoàn tất (`flutter analyze`: 0 errors, `flutter test`: 218 passed, 1 skipped). X3 dừng do polygon VietReceipt không theo góc trên-trái hướng chữ.
- **Smoke 200 file (`eligible=152`, `BROKEN_ROWS=48`):** Trước/sau X1–X3 giữ nguyên `BROKEN_ROWS` `48/200`, `foundTotal` `122/152 (80.3%)`, `unreadable` `10/152 (6.6%)`.
- **Tập phụ 30 file `UIT` `001502–001545` (`eligible=19`, `BROKEN_ROWS=11`):** Trước/sau X1–X3 giữ nguyên `BROKEN_ROWS` `11/30`, `foundTotal` `11/19 (57.9%)`, `NOTOTAL` `6/19`, `unreadable` `2/19 (10.5%)`.

## In progress
- Dải `001500–001599` dùng làm tập kiểm tra phụ (không sửa quy tắc theo dải này); fixture có nhãn chỉ lấy từ `001600` trở lên.

## Next
- Nhận thêm các dòng OCR của `uit_mlreceipts/images/001872` (và các ảnh `>= 001600` / ảnh tự chụp) để chạy Bước 3–5.

## Blockers
- X3 dừng ở converter VietReceipt (X1–X2 vẫn giữ cho ML Kit); chưa chạy `pod install` trên macOS.
