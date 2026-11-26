# Tiến độ SplitDebt (Receipt OCR)

## Done
- **Task 1–5 + Review 1–2 + S0–S6 + K1–K2 + X1–X2:** Hoàn tất (`flutter analyze`: 0 errors, `flutter test -j 1`: 233 passed, 1 skipped). X3 dừng do polygon VietReceipt không theo góc trên-trái hướng chữ.
- **Bước 2B–5 (`external/labeled` 15 `mc_ocr`; `external/holdout` 15 `uit_mlreceipts`):** Hoàn tất (labeled sau tinh chỉnh: `13/15` total, `37/38` item; holdout: `11/15` total, `34/59` item).
- **Privacy Consent Task 1–4:** Hoàn tất (`UserConsent`, `ReconsentFilter` 428, `DataExportService`, `AccountDeletionService`; `.\mvnw.cmd test`: 98 passed).

## In progress
- **Privacy Consent Task 6:** Soạn văn bản pháp lý (`docs/legal/*.md`).

## Next
- Hoàn tất Task 6 (Task 5 đã huỷ), sẵn sàng chuyển sang Task 7–9 (Flutter).

## Blockers
- X3 dừng ở converter VietReceipt; chưa chạy `pod install` trên macOS.
