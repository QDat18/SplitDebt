# 💸 SplitDebt - Smart Group Expense & Debt Management

Ứng dụng quản lý chi tiêu nhóm tích hợp sổ công nợ, tự động phân chia chi phí và tối ưu hóa các khoản nợ bằng thuật toán Smart Settlement.

**Phát triển bởi team ErrorAtLine1**

---

## 🛠 Yêu cầu hệ thống (Prerequisites)

Trước khi chạy project, hãy đảm bảo máy tính của bạn đã cài đặt:
* **Flutter SDK**: Phiên bản ổn định mới nhất (stable channel).
* **Android Studio** hoặc **Visual Studio Code** (có cài đặt Flutter & Dart plugins).
* **Git** để quản lý mã nguồn.

---

## 🚀 Hướng dẫn cài đặt & Chạy dự án

**Bước 1: Clone mã nguồn về máy**
Mở Terminal/Git Bash tại thư mục muốn lưu project và chạy lệnh:
`git clone https://github.com/QDat18/SplitDebt.git`
`cd SplitDebt`

**Bước 2: Cài đặt các thư viện (Dependencies)**
Project sử dụng các thư viện cốt lõi như `flutter_riverpod`, `supabase_flutter`, `firebase_messaging`. Để tải toàn bộ thư viện, chạy lệnh:
`flutter pub get`

**Bước 3: Chạy ứng dụng**
Kết nối máy ảo (Emulator) hoặc thiết bị thật (Android/iOS) và chạy:
`flutter run`

---

## 📂 Cấu trúc thư mục (Project Structure)

Dự án áp dụng kiến trúc phân lớp (Layered Architecture) kết hợp quản lý trạng thái bằng **Riverpod**. Mọi code logic và UI đều nằm trong thư mục `lib/`:

* **`core/`**: Chứa các cấu hình dùng chung toàn hệ thống (theme, màu sắc, constants, routes, utilities).
* **`data/`**: Chứa các model map với Database, thao tác API (datasources) và kho lưu trữ (repositories).
* **`features/`**: Chứa các module chức năng riêng biệt. Mỗi feature sẽ có UI và Provider tương ứng:
    * `auth/`: Đăng nhập, đăng ký.
    * `groups/`: Quản lý nhóm, thành viên.
    * `expenses/`: Thêm, sửa, chia khoản chi.
    * `debts/`: Sổ công nợ tổng quan.
    * `settlements/`: Thuật toán Xén nợ (Smart Settlement) và thanh toán.
    * `statistics/`: Thống kê chi tiêu.
    * `notifications/`: Thông báo đẩy.
    * `profile/`: Thông tin cá nhân.

---

## 🔑 Lưu ý về Môi trường (Environment Variables)

*(Sẽ cập nhật sau)*
Hiện tại cấu hình **Supabase** (URL, Anon Key) và **Firebase** đang được thiết lập cứng hoặc chờ bổ sung. Khi có file `.env` hoặc file cấu hình bảo mật, các thành viên không push file đó lên GitHub mà sẽ được cấp phát riêng qua kênh nội bộ.