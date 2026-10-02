# Tích hợp dev3 vào dev4

## Quyết định khi giải quyết xung đột

- Dùng ID `Long` và các bảng hiện tại của dev4 cho user, nhóm và thành viên. Module nhóm của dev3 đã được chuyển sang cùng kiểu ID.
- API nhóm lấy tài khoản từ JWT, không dùng tài khoản mặc định hoặc header `X-User-Id` để xác định quyền.
- Giữ cấu trúc phản hồi `status/message/data`, bổ sung `success` cho tương thích module nhóm.
- Dùng một enum vai trò `entity.enums.GroupRole`: OWNER, ADMIN, MEMBER.
- Màn hình chính mở danh sách nhóm thật của dev3; trong chi tiết nhóm có nút thêm khoản chi và quyết toán.
- Client nhóm dùng chung Dio, URL API và JWT với các module còn lại. Model Flutter chấp nhận ID số trả về từ backend.
- Khoản chi được lưu qua API; chỉ báo thành công sau khi máy chủ lưu. Khi đổi tab, nhóm và công nợ được tải lại. Các tab chưa mở không tải dữ liệu trước.
- Thêm thành viên bằng email yêu cầu tài khoản đó đã đăng ký. Không tự tạo tài khoản không có mật khẩu.
- Quét OCR vẫn chưa được nối dịch vụ; màn hình thông báo điều này thay vì tạo hóa đơn mẫu và ID giả.

## Kiểm chứng

- Backend: `cd api` rồi `mvn clean test`: 19 test đạt, không có lỗi hoặc thất bại.
- Frontend: `flutter pub get` và `flutter build web --no-pub --no-wasm-dry-run` thành công. `dart analyze` không có error/warning; vẫn còn các thông báo lint mức info.
- Test tích hợp dùng JWT thật: tạo nhóm, thêm thành viên, ghi khoản chi chia đều, kiểm tra quyền người trả, báo đã trả, xác nhận nhận tiền và kiểm tra dư nợ hai bên về 0.
- Chrome headless với H2 riêng: tạo nhóm bằng UI, ghi khoản chi 200.000 VND cho hai người, kiểm tra công nợ +100.000/-100.000; kiểm tra desktop và viewport 390×844, không có page error hay tràn ngang trên màn hình quyết toán.
- FCM thật trên thiết bị chưa được gửi thử. FCM bị tắt trong server thử nghiệm.

## Dữ liệu database hiện tại cần lưu ý

Một lần khởi động server thử bằng Maven không nạp được resource của profile test và đã kết nối database PostgreSQL mặc định. Server đã được dừng; lần thử tiếp theo chỉ định trực tiếp URL, driver và dialect H2 trong RAM.

Log lần khởi động đầu ghi nhận Hibernate đổi các cột văn bản sang `TEXT`: `expenses.description`, `expenses.receipt_url`, `groups.description`, `notifications.content`, `user_fcm_tokens.token`, `users.avatar_url`. Các lệnh thêm khóa ngoại thất bại vì có bản ghi tham chiếu user/nhóm không còn tồn tại, gồm các ID như `1000000001`, `1000000002`, `1000000003` và user `4`. Không có thao tác tạo/xóa dữ liệu nghiệp vụ được thực hiện trong lần chạy này.

Chưa sửa hoặc xóa các bản ghi mồ côi: cần xác định dữ liệu nào phải khôi phục hoặc bỏ trước khi chỉnh database. Vì vậy build/test thành công không đồng nghĩa dữ liệu PostgreSQL hiện tại đã sạch.

## Chạy sau merge

1. Khởi động lại API bằng cấu hình database của dự án.
2. Chạy lại Flutter web và tải lại trang.
3. Đăng ký hai tài khoản, tạo nhóm rồi thêm tài khoản còn lại bằng email đã đăng ký.
4. Ghi khoản chi trong nhóm; người trả báo đã thanh toán, người nhận xác nhận trong tài khoản riêng.

Có thể ghi đè URL API khi build bằng `--dart-define=API_BASE_URL=...`; nếu không truyền, ứng dụng dùng `API_BASE_URL` trong `.env`.
