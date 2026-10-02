# 📘 HUỚNG DẪN KẾT NỐI API & TÀI LIỆU SWAGGER / POSTMAN - TEAM IUMAITRUONG

**Tác giả**: Dev 2 (Đạt) - SplitDebt Backend  
**Dành cho**: Dev 1 (Auth/Group Backend), Dev 3 (Expense UI Flutter), Dev 4 (Settlement UI Flutter)  

---

## 1. SWAGGER OPENAPI 3.0 (Tài liệu API Trực quan Live)

Server Backend đã tích hợp sẵn **Springdoc OpenAPI 3.0**. Khi khởi chạy dự án (`mvn spring-boot:run`), tất cả các Dev có thể truy cập tài liệu API trực tiếp trên trình duyệt:

- 🔗 **Swagger UI Document**: [http://localhost:8080/swagger-ui.html](http://localhost:8080/swagger-ui.html)
- 📄 **OpenAPI JSON Spec**: [http://localhost:8080/v3/api-docs](http://localhost:8080/v3/api-docs)

---

## 2. BỘ SƯU TẬP POSTMAN (POSTMAN COLLECTION)

Đã xuất sẵn file cấu hình Postman collection tại thư mục gốc của dự án backend:
- 📁 **[SplitDebt_API.postman_collection.json](file:///d:/KyVII_HocVienNganHang/LapTrinhDiDong/CuoiKy/SplitDebt/api/SplitDebt_API.postman_collection.json)**

### Cách Import vào Postman:
1. Mở ứng dụng **Postman**.
2. Bấm nút **Import** (ở góc trên bên trái).
3. Chọn tệp `SplitDebt_API.postman_collection.json`.
4. Toàn bộ các Request mẫu (Chi tiêu 4 thuật toán, Dư nợ ròng, Quyết toán 2 chiều, Cài đặt) sẽ tự động hiển thị với sẵn biến `{{baseUrl}} = http://localhost:8080`.

---

## 3. CÁC TÍNH NĂNG & ENDPOINTS ĐÃ SẴN SÀNG KẾT NỐI

### 💳 A. Nhóm API Chi Tiêu & 4 Thuật Toán Chia Tiền (`Dev 3 - Flutter Form`)
- **`POST /api/v1/expenses`**: Tạo mới khoản chi tiêu.
  - Chế độ `EQUAL`: Chia đều cho danh sách người tham gia.
  - Chế độ `AMOUNT`: Chia theo số tiền cố định (Validate tổng số tiền).
  - Chế độ `PERCENT`: Chia theo phần trăm (Validate tổng 100%, tự động bù dư lẻ làm tròn).
  - Chế độ `WEIGHT`: Chia theo trọng số hệ số (Tự động bù dư lẻ làm tròn).
  - Chế độ `ITEM`: Chia theo dòng món ăn chi tiết.
- **`GET /api/v1/expenses/group/{groupId}`**: Lấy lịch sử chi tiêu trong nhóm.
- **`PUT /api/v1/expenses/{id}`** & **`DELETE /api/v1/expenses/{id}`**: Sửa/xóa khoản chi (tự động khóa nếu nhóm đã chốt nợ).

### 🤝 B. Nhóm API Quyết Toán & Xén Nợ Tối Ưu (`Dev 4 - Flutter Dashboard`)
- **`GET /api/v1/settlements/net-balances/group/{groupId}`**: Lấy dư nợ ròng của từng người (`netBalance = totalPaid - totalOwed`).
- **`GET /api/v1/settlements/simplified/group/{groupId}`**: Lấy bảng xén nợ tối ưu (Min-Cash-Flow) giảm tối đa số lượt trả tiền.
- **`POST /api/v1/settlements`**: Tạo yêu cầu trả tiền (`PENDING`).
- **`PUT /api/v1/settlements/{settlementId}/status`**: Cập nhật trạng thái trả tiền (`PAID` $\rightarrow$ `CONFIRMED` / `CANCELLED`).

### ⚙️ C. Nhóm API Cài Đặt (`Dev 1 & Dev 3`)
- **`GET /api/v1/settings/group/{groupId}`** & **`PUT /api/v1/settings/group/{groupId}`**: Cài đặt loại tiền tệ (VNĐ vs USD), Xén nợ, Ngân sách nhóm, Cài đặt AI/OCR.
- **`GET /api/v1/settings/user/{userId}`** & **`PUT /api/v1/settings/user/{userId}`**: Cài đặt Giao diện (Dark Mode), Ngôn ngữ (VI/EN), Thông báo, Sinh trắc học.
