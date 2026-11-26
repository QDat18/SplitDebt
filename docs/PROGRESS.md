# Tiến độ SplitDebt (Receipt OCR)

## Done
- **Task 1–5 + Review 1–2 + S0–S6 + K1–K2 + X1–X2:** Hoàn tất (`flutter analyze`: 0 errors, `flutter test -j 1`: 233 passed, 1 skipped). X3 dừng do polygon VietReceipt không theo góc trên-trái hướng chữ.
- **Bước 2B–5 (`external/labeled` 15 `mc_ocr`; `external/holdout` 15 `uit_mlreceipts`):** Hoàn tất (labeled sau tinh chỉnh: `13/15` total, `37/38` item; holdout: `11/15` total, `34/59` item).
- **Privacy Consent Task 1–4 & Task 6 (Task 5 đã huỷ):** Hoàn tất (`UserConsent`, `ReconsentFilter` 428, `DataExportService`, `AccountDeletionService`, 4 văn bản pháp lý tại `docs/legal/`; `.\mvnw.cmd test`: 98 passed).

## In progress
- Chưa thực hiện phần app Flutter (Task 7–9).

## Next
- Thực hiện Privacy Consent Task 7–9 (Flutter) khi chủ dự án yêu cầu.

## Blockers
- X3 dừng ở converter VietReceipt; chưa chạy `pod install` trên macOS.
