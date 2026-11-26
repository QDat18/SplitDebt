# Tiến độ SplitDebt (Receipt OCR)

## Done
- **Task 1–5 + Review vòng 1 & 2 (O1–O10, R0–R10) + Bước 0 (0.1–0.3) + Bước 1b (1, 2, 3, 5):** Hoàn tất và đã kiểm tra (`flutter analyze`: 0 errors, `flutter test`: 195 passed).
- **Bước 1b Smoke test (200 file từ `mc_ocr` 100 + `uit_mlreceipts` 100, lưu cục bộ bị gitignore):**
  - `External Smoke Report (200 files): foundTotal=103/160 (64.4%), unreadable=40/200 (20.0%)`
  - Không có exception ngoài `ReceiptUnreadable`; mọi hoá đơn lệch tổng đều có warning (`All tests passed!`).

## In progress
- Chờ dữ liệu ML Kit + nội dung đúng + loại hoá đơn cho các ảnh đã chọn (phần 2) để lập fixture vào `test/fixtures/external/labeled/` và `test/fixtures/receipts/` rồi chạy Bước 3 → 5.

## Next
- Nhận dữ liệu `[dán dữ liệu]` từ chủ dự án → lập fixture → đo chỉ số ban đầu (Bước 3) → tinh chỉnh theo dữ liệu (Bước 4) → báo cáo (Bước 5).

## Blockers
- Phần (2) chưa có dữ liệu OCR + nhãn gửi kèm (`[dán dữ liệu]`); chưa chạy `pod install` cho `frontend/ios/Podfile` trên macOS.
