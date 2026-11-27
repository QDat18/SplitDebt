Phiên bản: 2026-11-26
Hiệu lực từ: [CẦN ĐIỀN]

# Hướng dẫn xoá tài khoản và dữ liệu cá nhân SplitDebt

Trang này hướng dẫn cách yêu cầu xoá tài khoản SplitDebt trực tiếp trong ứng dụng hoặc qua email khi bạn không thể đăng nhập vào ứng dụng.

## 1. Cách xoá tài khoản ngay trong ứng dụng

1. Mở ứng dụng SplitDebt và đăng nhập vào tài khoản của bạn.
2. Chọn tab **Cá nhân**, nhấn vào mục **Quyền riêng tư**.
3. Chọn **Xoá tài khoản**.
4. Đọc kỹ thông tin về dữ liệu bị xoá và dữ liệu được giữ ẩn danh, sau đó nhập mật khẩu để xác nhận.
5. Nếu bạn vẫn còn số dư công nợ chưa thanh toán trong nhóm nào, hệ thống sẽ liệt kê các nhóm đó để bạn hoàn tất thanh toán trước khi xoá.

## 2. Yêu cầu xoá tài khoản qua email (khi không vào được ứng dụng)

Nếu bạn mất quyền truy cập vào ứng dụng, vui lòng gửi email từ địa chỉ email đã đăng ký tài khoản tới:

- Email tiếp nhận: [CẦN ĐIỀN]
- Tiêu đề thư: `Yeu cau xoa tai khoan SplitDebt`
- Nội dung: nêu rõ họ tên và địa chỉ email đăng ký tài khoản cần xoá.

Chúng tôi sẽ xác minh chủ tài khoản và xử lý yêu cầu trong thời hạn tối đa 30 ngày.

## 3. Dữ liệu nào bị xoá và dữ liệu nào được giữ lại

**Dữ liệu bị xoá hoặc ẩn danh hoá ngay khi hoàn tất:**

- Họ tên (chuyển thành "Người dùng đã xoá"), email (ẩn danh hoá), số điện thoại và ảnh đại diện.
- Ảnh đại diện lưu trên Supabase Storage.
- Mã thông báo đẩy (push token), cài đặt cá nhân, thông báo và nhật ký hoạt động tài khoản.
- Nội dung tin nhắn bạn đã gửi trong các nhóm (thay thành "Tin nhắn đã bị xoá").

**Dữ liệu được giữ lại dưới dạng ẩn danh:**

- Các khoản chi tiêu, phần chia và lịch sử thanh toán trong nhóm chung được giữ lại (chỉ trỏ tới mã người dùng đã ẩn danh) để không làm sai lệch sổ nợ của các thành viên khác.
- Bản ghi đồng ý quyền riêng tư được lưu giữ làm bằng chứng tuân thủ pháp luật.
