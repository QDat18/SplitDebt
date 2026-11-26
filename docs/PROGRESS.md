# Tiến độ SplitDebt (Receipt OCR)

## Done
- **Task 1–5 + Review vòng 1 & 2 (O1–O10, R0–R10) + Bước 0 (0.1–0.3) + Bước 1b (1, 2, 3, 5):** Hoàn tất (`flutter analyze`: 0 errors, `flutter test`: 195 passed).
- **S0 Smoke baseline (200 file VietReceipt, `eligible=152`, `BROKEN_ROWS=48`):**
  - Trước sửa: `foundTotal=101/152 (66.4%)`, `unreadable=12/152 (7.9%)`, `noTotal=39`, `BROKEN_ROWS=48`.

## In progress
- Đang thực hiện Bước 4a (`S1 → S6`) theo `2026-11-26-receipt-ocr-smoke-fixes.md`.

## Next
- Hoàn tất S1 → S6, chạy `flutter analyze`, `flutter test`, và chạy lại smoke test để đối chiếu bảng trước/sau.

## Blockers
- Chưa có fixture có nhãn (tập giữ riêng); chưa chạy `pod install` cho `frontend/ios/Podfile` trên macOS.
