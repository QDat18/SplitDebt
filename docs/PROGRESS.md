# Tiến độ SplitDebt (Receipt OCR)

## Done
- **Task 1–5 + Review vòng 1 & 2 (O1–O10, R0–R10) + Bước 0 + Bước 1b + Bước 4a (S0–S6):** Hoàn tất.
- `flutter analyze`: 0 errors. `flutter test`: 212 passed, 1 skipped (`receipt_fixtures_test.dart`).
- **Smoke test VietReceipt (200 file, `eligible=152`, `BROKEN_ROWS=48`):**

| Chỉ số | Trước (S0) | Sau (S6) | Mục tiêu |
|---|---|---|---|
| `foundTotal` | 101/152 (66.4%) | 122/152 (80.3%) | >= 80% |
| `unreadable` | 12/152 (7.9%) | 10/152 (6.6%) | <= 5% |
| `BROKEN_ROWS` | 48/200 | 48/200 | Loại khỏi mẫu số |

## In progress
- Chưa đạt ngưỡng `unreadable <= 5%` (hiện 6.6%); đã báo 10 file `NOTOTAL`/`UNREAD` đầu tiên để quyết định hướng tiếp theo.

## Next
- Nhận fixture có nhãn (tập giữ riêng `UIT-MLReceipts` split `test` ngoài 100 file smoke + ảnh nhóm tự chụp) để đo độ chính xác cuối.

## Blockers
- Chưa có fixture có nhãn; chưa chạy `pod install` cho `frontend/ios/Podfile` trên macOS.
