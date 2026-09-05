# ✂️ SplitDebt (Xén Nợ)

SplitDebt là ứng dụng quản lý chi tiêu nhóm thông minh, giúp tự động hóa việc tính toán và tối ưu hóa các khoản nợ chéo (Smart Settlement) giữa các thành viên. Dự án được phát triển bởi **Nhóm *****.

## 🏗 Kiến trúc dự án (Monorepo)

Dự án được phân tách thành 2 phân hệ độc lập để dễ dàng bảo trì và mở rộng:

*   **[`/frontend`](./frontend/)**: Ứng dụng di động đa nền tảng (Android/iOS) được xây dựng bằng **Flutter**. Xử lý giao diện người dùng, trạng thái (Riverpod) và tương tác trực tiếp.
*   **[`/api`](./api/)**: Máy chủ RESTful API được xây dựng bằng **Java Spring Boot 3**. Đảm nhiệm logic nghiệp vụ phức tạp, phân quyền, và thực thi thuật toán tối ưu hóa công nợ.

## 🚀 Công nghệ sử dụng

*   **Frontend:** Flutter, Riverpod, Google Fonts, Supabase Flutter.
*   **Backend:** Java 21, Spring Boot 3.3.0, Spring Data JPA, Lombok.
*   **Database:** PostgreSQL (Lưu trữ trên Supabase).
*   **Authentication:** Supabase Auth.

## ⚙️ Hướng dẫn cài đặt chung

Để chạy toàn bộ dự án, bạn cần thiết lập cả Frontend và Backend chạy song song trên 2 cổng khác nhau.

1.  **Clone dự án:**
    ```bash
    git clone [https://github.com/QDat18/SplitDebt.git](https://github.com/QDat18/SplitDebt.git)
    cd SplitDebt
    ```
2.  **Thiết lập Frontend:**
    Vui lòng đọc hướng dẫn chi tiết tại [`frontend/README.md`](./frontend/README.md).
3.  **Thiết lập Backend:**
    Vui lòng đọc hướng dẫn chi tiết tại [`api/README.md`](./api/README.md).

## 📄 Giấy phép
Dự án được phát triển phục vụ mục đích học tập và nghiên cứu.