# Tiến độ SplitDebt (Receipt OCR)

## Done
- **Task 1–5 (Core) + Review vòng 1 & 2 (O1–O10, R0–R10):** Hoàn tất toàn bộ parser, preview sheet, flow, debug OCR lab (`kDebugMode`).
- **Bước 0 (Siêu thị & Tổng tiền & Schema):**
  - `0.1`: Đủ 7 quy tắc siêu thị (mã vạch, hàng cân, SL x đơn giá, từ khoá bỏ qua, VAT đã gồm/bảng thuế, KM/CK, 40 món) kèm test trong bộ hồi quy R0.
  - `0.2`: Nút `"Chỉ dùng tổng tiền"` (`PreviewAction.totalOnly`), điền tổng/tiêu đề/ngày và chuyển `SplitMode.equal`.
  - `0.3`: Hỗ trợ `"type": "restaurant" | "supermarket"` và báo cáo/kiểm ngưỡng theo từng loại trong `receipt_fixtures_test.dart`.
- **Bước 1b (Hạ tầng VietReceipt, mục 1, 2, 3, 5):** Chặn commit `test/fixtures/external/` trong `.gitignore`, script `tool/vietreceipt_to_rows.dart` + test, test chịu tải tự skip `receipt_external_smoke_test.dart`, tài liệu `docs/datasets.md`.
- `flutter analyze`: 0 errors. `flutter test`: 195 passed, 2 skipped (`receipt_fixtures_test.dart`, `receipt_external_smoke_test.dart`).

## In progress
- Chờ chủ dự án thu thập dữ liệu thật (Bước 1) và chạy script VietReceipt cục bộ.

## Next
- Lập fixture thật (`test/fixtures/receipts/` và `test/fixtures/external/labeled/`), đo chỉ số ban đầu và tinh chỉnh theo dữ liệu thật.

## Blockers
- Chưa có fixture hoá đơn thật; chưa chạy `pod install` cho `frontend/ios/Podfile` trên macOS.
