# Tiến độ SplitDebt (Receipt OCR)

## Done
- **Task 1–5 + Review 1–2 + S0–S6 + K1–K2 + X1–X2:** Hoàn tất (`flutter analyze`: 0 errors, `flutter test -j 1`: 233 passed, 1 skipped). X3 dừng do polygon VietReceipt không theo góc trên-trái hướng chữ.
- **Bước 2B–5 (`external/labeled` 15 `mc_ocr`; `external/holdout` 15 `uit_mlreceipts`):** Hoàn tất (labeled sau tinh chỉnh: `13/15` total, `37/38` item; holdout: `11/15` total, `34/59` item).
- **Privacy Consent Task 1–4, Task 6 & Review vòng 1 (P1–P3, Task 5 đã huỷ):** Hoàn tất (`purgeGroup` khi xoá tài khoản chủ duy nhất, 400 `WRONG_PASSWORD`, chuẩn hoá `platform`/`appVersion`; `.\mvnw.cmd test`: 101 passed).

- **Privacy Consent Task 7–9 (Flutter):** Hoàn tất (`RegisterScreen`, `ReconsentScreen`, 428 gate, `NotificationPromptPolicy` + `NotificationRationaleSheet`, `PrivacyCenterScreen`, `DataExportScreen`, `DeleteAccountFlowScreen`; `flutter analyze` 0 error, `flutter test -j 1` 242 passed, 1 skipped).

## In progress
- Kiểm thử thủ công trên máy ảo `Pixel_8a`.

## Next
- Hoàn tất kiểm thử thủ công trên `Pixel_8a` và tổng kết mục "Hoàn tất".

## Blockers
- X3 dừng ở converter VietReceipt; chưa chạy `pod install` trên macOS; `GroupServiceImpl.deleteGroup` có lỗi khoá ngoại từ trước khi nhóm có khoản chi (ngoài phạm vi plan).
