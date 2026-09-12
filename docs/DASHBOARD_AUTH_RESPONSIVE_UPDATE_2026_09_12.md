# Dashboard, onboarding và auth flow update — 2026-09-12

## UX / responsive
- Splash thay kích thước logo, chữ và khoảng cách theo chiều rộng/chiều cao thiết bị để không cắt nội dung trên điện thoại ngắn hoặc màn hình hẹp.
- Onboarding 3 bước được thiết kế lại theo Luminous Depth: hình minh họa 3D có sẵn trong project, card kính, bước hiện tại, chip tính năng và CTA luôn nằm trong SafeArea.
- Onboarding dùng một cột trên điện thoại và hai cột trên tablet/desktop; nội dung trang cuộn độc lập nếu chiều cao thiết bị ngắn.
- Dashboard có lời chào + ngày hiện tại, các thao tác nhanh, tổng số dư ròng, số tiền sẽ nhận / cần trả và danh sách nhóm đang hoạt động.
- Dashboard: <600px một cột; từ 760px phần nhóm chuyển hai cột; toàn bộ nội dung giới hạn max-width 1120px trên desktop.
- Bottom navigation 6 mục tự giảm lề, khoảng trống FAB, cỡ icon/chữ trên màn hình <380px.
- Không tự bật modal hướng dẫn khi vừa vào Home; người dùng vào thẳng Dashboard.

## Đăng ký tự đăng nhập
Backend `/api/auth/register` vẫn giữ `id` và `message`, đồng thời trả thêm `token` và `user`.
Frontend `Session.register()` nhận payload này, lưu token/user giống luồng đăng nhập và đặt `Session.authenticated=true`.
`RegisterScreen` đóng ngay sau khi session được tạo nên `SessionGate` hiển thị `HomeScreen` trực tiếp.
Có fallback cho backend cũ chỉ trả `id/message`: tài khoản vẫn tạo thành công và quay về đăng nhập.

## Đăng xuất
Nút ĐĂNG XUẤT:
1. Gọi `Session.signOut()` để xóa token/user khỏi SharedPreferences.
2. `SessionGate` đổi về `LoginScreen`.
3. `Navigator.popUntil(route.isFirst)` đóng Profile/History/Group còn nằm trên Home, bảo đảm người dùng thực sự nhìn thấy màn Đăng nhập / Đăng ký.
