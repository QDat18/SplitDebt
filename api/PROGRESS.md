# 📊 BÁO CÁO TIẾN ĐỘ THỰC HIỆN DỰ ÁN - DEV 2 (ĐẠT)

**Dự án**: SplitDebt API & Mobile Frontend  
**Nhân sự**: Dev 2 (Đạt) - Team IUMAITRUONG  
**Tài khoản Git**: QDat18  
**Nhánh Git (Branch)**: `dev2-dat`  
**Cập nhật gần nhất**: 06/09/2026  

---

## 📈 1. TỔNG QUAN TIẾN ĐỘ THỰC HIỆN (HOÀN THÀNH 100%)

| Module / Chỉ số | Trạng thái | Chi tiết triển khai |
| :--- | :---: | :--- |
| **Tổng số Task Backend** | **100% HOÀN THÀNH** | 4 Tasks chính (`BE2-EXP-01`, `BE2-SET-01`, `BE2-SET-02`, `BE2-EXP-02`) + Module Settings |
| **Toàn bộ Tầng Backend (Full Stack API)** | **100% HOÀN THÀNH** | 13 JPA Entities + 13 Repositories + 18 DTOs + 4 Services + 3 REST Controllers |
| **Thuật toán Chia Tiền (5 Modes)** | **100% HOÀN THÀNH** | `EQUAL`, `AMOUNT`, `PERCENT`, `WEIGHT`, `ITEM` với scale tự động & bảo đảm tổng số tiền chính xác |
| **Thuật toán Tối ưu Dòng tiền (Min-Cash-Flow)** | **100% HOÀN THÀNH** | `BE2-SET-01`: Rút gọn chuỗi giao dịch nợ vòng quanh |
| **Quy trình Thanh toán 2 Chiều** | **100% HOÀN THÀNH** | `BE2-SET-02`: Luồng Payer $\rightarrow$ Receiver xác nhận 2 bước |
| **Quy tắc Khóa sổ Khoản chi** | **100% HOÀN THÀNH** | `BE2-EXP-02`: Vô hiệu hóa Sửa/Xóa khi khoản chi đã chốt quyết toán |
| **Kết nối Supabase Cloud PostgreSQL** | **100% THÀNH CÔNG** | Kết nối qua IPv4 Connection Pooler (`aws-0-ap-northeast-1.pooler.supabase.com:6543`) + H2 Local DB |
| **Swagger UI & Postman Collection** | **100% HOÀN THÀNH** | Tài liệu OpenAPI OpenAPI 3.0 & File Import Postman đầy đủ |
| **Toàn bộ Mobile Frontend (Flutter UI)** | **100% HOÀN THÀNH** | Full Design Tokens + Bottom Navigation Bar 4 Tabs + Bypass Auth Demo Mode |

---

## 🎨 2. CHI TIẾT CÁC MÀN HÌNH MOBILE FRONTEND (FLUTTER)

### 1️⃣ Khung Điều Hướng Chính (`main_layout_screen.dart`):
- Tích hợp **Bottom Navigation Bar 4 Tabs** chuyển đổi màn hình 0-lag bằng `IndexedStack`.
- Chế độ Bypass Auth cho phép truy cập thẳng vào ứng dụng để kiểm thử.

### 2️⃣ Tab 0: Trang chủ Dashboard (`dashboard_screen.dart`):
- Lời chào cá nhân, Thẻ tổng số dư nợ ròng (`+340.000 ₫ - Cần nhận lại tiền`).
- Danh sách Nhóm chi tiêu (*Du Lịch Hà Giang*) & Các khoản chi gần đây.

### 3️⃣ Tab 1: Tạo Khoản Chi Mới (`create_expense_screen.dart`):
- Ô nhập số tiền lớn (36pt), các chip bấm cộng nhanh (`+50K`, `+100K`...).
- 5 Chế độ chia tiền linh hoạt + Trích xuất bill tự động bằng AI OCR Scan.

### 4️⃣ Tab 2: Quyết Toán Nợ Nhóm (`group_settlement_screen.dart`):
- Dư nợ ròng từng người & Danh sách nợ rút gọn qua Thuật toán Min-Cash-Flow (`BE2-SET-01`).
- Nút **"CHỐT SỔ QUYẾT TOÁN NHÓM"** chuyển trạng thái đóng băng sổ sách.

### 5️⃣ Màn hình Chi Tiết Khoản Chi (`expense_detail_screen.dart`):
- Bảng phân rã nợ chi tiết, xem ảnh hóa đơn bill.
- Tích hợp Quy tắc khóa `BE2-EXP-02` (vô hiệu hóa Sửa/Xóa khi đã chốt sổ).

### 6️⃣ Màn hình Xác Nhận Thanh Toán 2 Chiều (`settlement_confirmation_screen.dart`):
- Mã VietQR ngân hàng MBBank tự động.
- Quy trình xác thực 2 bước `BE2-SET-02` (Người trả $\rightarrow$ Người nhận duyệt).

### 7️⃣ Tab 3: Cài Đặt Nhóm & Cá Nhân (`settings_screen.dart`):
- Đổi đơn vị tiền tệ (`VND/USD/EUR`), Hạn mức ngân sách nhóm, Ngày tự động đóng băng sổ.
- Cài đặt Dark Mode, Sinh trắc học FaceID & Thông báo nhắc nợ.

---

## 📁 3. DANH SÁCH MÃ NGUỒN TRONG COMMIT GIT

1. **Tầng Backend (`/api`)**:
   - Entities, DTOs, Repositories, Services, Controllers, OpenAPI Config, Postman Collection, `.env`, `application.yaml`, `pom.xml`.
2. **Tầng Frontend (`/frontend`)**:
   - `AppColors`, `AppTypography`, `AppDimensions`, `AppTheme`.
   - `main.dart`, `main_layout_screen.dart`.
   - `create_expense_screen.dart`, `expense_detail_screen.dart`.
   - `group_settlement_screen.dart`, `settlement_confirmation_screen.dart`.
   - `dashboard_screen.dart`, `settings_screen.dart`, `login_screen.dart`.

---

## 🎯 4. KẾT LUẬN

Toàn bộ các task backend & frontend phân công cho **Dev 2 (Đạt)** đã hoàn thành và sẵn sàng ghép nối hệ thống với toàn đội!
