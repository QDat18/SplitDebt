# Bộ dữ liệu hoá đơn ngoài (External Datasets)

Tài liệu này ghi nhận nguồn gốc, giấy phép và quy tắc lưu trữ các bộ dữ liệu hoá đơn bên ngoài dùng để kiểm thử và tinh chỉnh tính năng quét hoá đơn (OCR trên thiết bị + bộ phân tích quy tắc).

## 1. VietReceipt OCR (Kaggle)

- **Tên bộ dữ liệu:** `hpgiakhang1405/vietreceipt-ocr`
- **Quy mô:** 2.530 ảnh hoá đơn tiếng Việt, khoảng 102.000 vùng chữ có toạ độ đa giác, nội dung kiểm duyệt và nhãn độ rõ (`legibility`). Bộ dữ liệu không có sẵn nhãn tên quán, món ăn hay tổng tiền.
- **Nguồn gốc (hai bộ dữ liệu gốc):**
  - **MC-OCR 2021** — DOI: `10.1109/RIVF51545.2021.9642077`
  - **UIT-MLReceipts** — DOI: `10.21553/rev-jec.330`

## 2. Điều khoản sử dụng

- Chỉ sử dụng cho mục đích **nghiên cứu, học tập và phi thương mại**, tuân thủ điều khoản của hai bộ dữ liệu gốc (MC-OCR 2021 và UIT-MLReceipts).

## 3. Quy tắc lưu trữ trong repo

- **Không commit** bất kỳ ảnh, văn bản OCR, file `.rows.txt`, hay file `.expected.json` nào lấy từ VietReceipt vào repository Git.
- Toàn bộ dữ liệu chuyển đổi hoặc gắn nhãn từ bộ dữ liệu này chỉ lưu cục bộ trong `frontend/test/fixtures/external/` (đã được chặn trong `frontend/.gitignore`).
- Khi bổ sung ca hồi quy mới phát hiện từ quá trình kiểm thử chịu tải, chỉ tự viết lại dòng mẫu minh hoạ cùng dạng lỗi, không sao chép nguyên văn nội dung từ bộ dữ liệu.
