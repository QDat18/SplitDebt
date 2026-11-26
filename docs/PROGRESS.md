# Tiến độ SplitDebt (Receipt OCR)

## Done
- **Task 1–5 + Review 1–2 + S0–S6 + K1–K2 + X1–X2:** Hoàn tất (`flutter analyze`: 0 errors, `flutter test -j 1`: 233 passed, 1 skipped). X3 dừng do polygon VietReceipt không theo góc trên-trái hướng chữ.
- **Bước 2B–5 (`external/labeled` 15 `mc_ocr`; `external/holdout` 15 `uit_mlreceipts`):** Hoàn tất (labeled sau tinh chỉnh: `13/15` total, `37/38` item; holdout: `11/15` total, `34/59` item).
- **Privacy Consent Task 1–4, Task 6 & Review vòng 1 (P1–P3, Task 5 đã huỷ):** Hoàn tất (`purgeGroup` khi xoá tài khoản chủ duy nhất, 400 `WRONG_PASSWORD`, chuẩn hoá `platform`/`appVersion`; `.\mvnw.cmd test`: 101 passed).

- **Privacy Consent Task 7 (Flutter):** Hoàn tất (`legal_texts`, `LegalDocumentScreen`, `RegisterConsentState`, `RegisterScreen` 3 checkbox, `ReconsentScreen` + interceptor 428; `flutter analyze` 0 error, `flutter test -j 1` 236 passed, 1 skipped).

## In progress
- **Privacy Consent Task 8:** Xin quyền thông báo đúng ngữ cảnh (`PushNotificationService`, `NotificationRationaleSheet`, `Info.plist`).

## Next
- Thực hiện Task 8, Task 9, kiểm thử thủ công trên `Pixel_8a`, hoàn tất checklist.

## Blockers
- X3 dừng ở converter VietReceipt; chưa chạy `pod install` trên macOS; `GroupServiceImpl.deleteGroup` có lỗi khoá ngoại từ trước khi nhóm có khoản chi (ngoài phạm vi plan).
