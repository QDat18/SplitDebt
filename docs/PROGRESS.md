# Tiến độ SplitDebt (Receipt OCR)

## Done
- **Task 1–5 + Review vòng 1 & 2 + Bước 0 + Bước 1b + Bước 4a (S0–S6) + Review K1–K2:** Hoàn tất.
- `flutter analyze`: 0 errors. `flutter test`: 215 passed, 1 skipped (`receipt_fixtures_test.dart`).
- **Smoke test VietReceipt (200 file, `eligible=152`, `BROKEN_ROWS=48`):**

| Chỉ số | Trước (S0) | Sau (S6 + K1) | Mục tiêu / Ghi chú |
|---|---|---|---|
| `foundTotal` | 101/152 (66.4%) | 122/152 (80.3%) | >= 80% (Đạt) |
| `unreadable` | 12/152 (7.9%) | 10/152 (6.6%) | Chấp nhận, chờ đo trên fixture có nhãn |
| `BROKEN_ROWS` | 48/200 | 48/200 | Loại khỏi mẫu số |

## In progress
- Chờ fixture có nhãn (tập giữ riêng `UIT-MLReceipts` split `test` ngoài 100 file smoke + ảnh nhóm tự chụp).

## Next
- Lập fixture có nhãn vào `test/fixtures/external/labeled/` và `test/fixtures/receipts/`, chạy `receipt_fixtures_test.dart` và hoàn tất Bước 5.

## Blockers
- Chưa có fixture có nhãn; chưa chạy `pod install` cho `frontend/ios/Podfile` trên macOS.
