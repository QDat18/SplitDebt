# SplitDebt UI/UX v4 - giao diện theo bộ prototype "Lập trình di động"

Bản v4 áp dụng trực tiếp ngôn ngữ giao diện từ bộ prototype PDF người dùng cung cấp, đồng thời giữ nguyên luồng API/backend hiện tại.

## Màn hình đã đồng bộ giao diện

- Splash: nền tím, logo trung tâm, animation scale/fade.
- Onboarding 3 bước: ghi chi tiêu, xén nợ, theo dõi minh bạch.
- Login/Register: layout tối giản, input bo góc, CTA tím, responsive web/mobile.
- Home Dashboard: thẻ tổng quan nợ/được nhận, nhóm cuộn ngang, khoản nợ gần đây.
- Group List: card nhóm, số thành viên, số dư màu xanh/đỏ.
- Create Group / Add Member: form gọn, mô tả rõ luồng thao tác.
- Group Detail: thẻ tổng chi tiêu nền tím đậm, số tiền phải trả/được nhận, CTA Thêm chi/Thanh toán.
- Add Expense: category chips, số tiền nổi bật, lựa chọn kiểu chia, phần của bản thân.
- Expense Detail: số tiền trung tâm, thông tin người trả/danh mục/ngày, danh sách phần chia.
- Debt / Smart Settlement: danh sách số dư, đề xuất giao dịch và trạng thái chờ xác nhận.
- Payment: chọn phương thức bằng radio card.
- Payment Success: màn hình thành công toàn trang với animation check.
- Statistics: bộ lọc Tuần/Tháng/Tất cả, tổng chi, progress bar theo danh mục, top người chi.
- Transactions: bộ lọc Tất cả/Chi tiêu/Thanh toán/Nhận tiền.
- Profile: danh sách cài đặt dạng card, theme, hướng dẫn, giới thiệu, đăng xuất.
- Notifications: card theo trạng thái success/warning/error/info.

## Thiết kế

- Primary: `#6C55EA`
- Primary Dark: `#2B1E70`
- Background: `#F7F8FC`
- Success: `#12C98A`
- Error: `#FF4B55`
- Warning: `#FFA21A`
- Material 3, bo góc 16-30px, elevation nhẹ, hỗ trợ dark mode.
- Hover/press/tilt 3D giữ lại từ v3 trên các surface quan trọng.

## Luồng không thay đổi

Backend, REST API, JWT, schema PostgreSQL/Supabase và business logic không bị thay đổi. Bản v4 chỉ bổ sung/thay đổi Flutter UI/UX và feedback giao diện.

## Chạy thử

```powershell
cd frontend
flutter clean
flutter pub get
flutter run -d chrome
```

Backend:

```powershell
cd api
.\mvnw.cmd spring-boot:run
```
