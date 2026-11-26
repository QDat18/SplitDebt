# Tiến độ SplitDebt (Receipt OCR)

## Done
- **Task 1–5 + Review vòng 1 & 2 + Bước 0 + Bước 1b + Bước 4a (S0–S6) + K1–K2:** Hoàn tất.
- **Xoay/nghiêng ảnh (X1–X2):** Đã thêm `OcrPoint`/`corners` vào `OcrLine`, truyền `cornerPoints` từ ML Kit, và cài `deskewLines` (xoay theo trung vị góc, PASS 90°/180°/270°/12°).
- `flutter analyze`: 0 errors. `flutter test`: 218 passed, 1 skipped (`receipt_fixtures_test.dart`).
- **Smoke test VietReceipt (200 file):**

| Chỉ số | Trước X1–X3 | Sau (X3 dừng) | Ghi chú |
|---|---|---|---|
| `BROKEN_ROWS` | 48 / 200 | 48 / 200 | X3 dừng vì polygon VietReceipt không bắt đầu từ trên-trái |
| `foundTotal` | 122 / 152 (80.3%) | 122 / 152 (80.3%) | Đạt >= 80% trên `eligible=152` |
| `unreadable` | 10 / 152 (6.6%) | 10 / 152 (6.6%) | Chấp nhận, chờ đo trên fixture có nhãn |

## In progress
- Đã nhận nhãn đúng cho `uit_mlreceipts/images/001872` (Bách Hóa Xanh), đang chờ các dòng OCR từ Phòng thử OCR để lập fixture.

## Next
- Nhận thêm các dòng OCR + nhãn đúng của ảnh giữ riêng (`UIT-MLReceipts` split `test` và ảnh tự chụp) để chạy Bước 3–5.

## Blockers
- X3 dừng ở converter VietReceipt do thứ tự điểm `polygon` không đúng góc trên-trái theo hướng chữ (X1–X2 vẫn giữ cho ML Kit trên app thật); chưa chạy `pod install` trên macOS.
