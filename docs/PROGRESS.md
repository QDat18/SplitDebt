# Tiến độ SplitDebt (Receipt OCR)

## Done
- **Task 1–5 + Review 1–2 + S0–S6 + K1–K2 + X1–X2:** Hoàn tất (`flutter analyze`: 0 errors, `flutter test -j 1`: 233 passed, 1 skipped). X3 dừng do polygon VietReceipt không theo góc trên-trái hướng chữ.
- **Bước 2B–5 (`external/labeled` 15 `mc_ocr`; `external/holdout` 15 `uit_mlreceipts`):** Hoàn tất (labeled sau tinh chỉnh: `13/15` total, `37/38` item; holdout: `11/15` total, `34/59` item).
- **Privacy Consent Task 1:** Hoàn tất (`UserConsent`, `ConsentService`, `LegalProperties`, `/api/auth/register` kèm `consents`, `/api/users/me` + `POST /api/users/me/consents`; `.\mvnw.cmd test`: 81 passed).

## In progress
- **Privacy Consent Task 2:** Chặn API nghiệp vụ với mã 428 (`ReconsentFilter`).

## Next
- Thực hiện Privacy Consent Task 2, 3, 4, 6 (Task 5 đã huỷ).

## Blockers
- X3 dừng ở converter VietReceipt; chưa chạy `pod install` trên macOS.
