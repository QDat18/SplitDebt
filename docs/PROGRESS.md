# Tiến độ SplitDebt (Receipt OCR)

## Done
- **Task 1–5 + Review 1–2 + S0–S6 + K1–K2 + X1–X2:** Hoàn tất (`flutter analyze`: 0 errors, `flutter test -j 1`: 233 passed, 1 skipped). X3 dừng do polygon VietReceipt không theo góc trên-trái hướng chữ.
- **Bước 2B–5 (`external/labeled` 15 `mc_ocr` sau 100 dòng đầu; `external/holdout` 15 `uit_mlreceipts >= 001600`, bỏ 15 file `<= 6` hàng + 3 file mơ hồ `001628, 001639, 001651`):** Đo trên **văn bản chuẩn do con người gõ** trong VietReceipt (chưa tính lỗi đọc chữ ML Kit):
  - **Trước tinh chỉnh (`labeled`, 15):** `totalMatch=11/15 (73.3%)`, `itemPriceMatch=22/38 (57.9%)`, `exactItemCount=6/15`, `unreadable=0`.
  - **Sau 2 lượt tinh chỉnh (`labeled`, 15):** `totalMatch=13/15 (86.7%)`, `itemPriceMatch=37/38 (97.4%)`, `exactItemCount=11/15`, `unreadable=1` (supermarket `10/12` total, `31/32` item; restaurant `3/3` total, `6/6` item — đạt ngưỡng 80%/85%).
  - **Tập giữ riêng (`holdout`, 15, chạy 1 lần):** `totalMatch=11/15 (73.3%)`, `itemPriceMatch=34/59 (57.6%)`, `exactItemCount=7/15`, `unreadable=1` (restaurant `7/9` total, `31/44` item; supermarket `4/6` total, `3/15` item).

## In progress
- Chưa có fixture ML Kit thật (ảnh `001863` / ảnh tự chụp) trong `test/fixtures/receipts/`.

## Next
- Thêm fixture ML Kit thật vào `test/fixtures/receipts/` khi có ảnh quét qua ML Kit để đo thêm một dòng riêng; push nhánh khi chủ dự án sẵn sàng.

## Blockers
- X3 dừng ở converter VietReceipt; chưa chạy `pod install` trên macOS.
