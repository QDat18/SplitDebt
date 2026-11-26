Phiên bản: 2026-11-26
Hiệu lực từ: [CẦN ĐIỀN]

# Chính sách quyền riêng tư và xử lý dữ liệu cá nhân

> Tài liệu này là bản dự thảo kỹ thuật cho đồ án SplitDebt. Trước khi phát hành chính thức, nội dung cần được giảng viên hướng dẫn hoặc người có chuyên môn pháp lý rà soát lại.

## 1. Bên kiểm soát dữ liệu và thông tin liên hệ

- Đơn vị / nhóm phát triển: [CẦN ĐIỀN: tên nhóm hoặc người phát triển]
- Địa chỉ: [CẦN ĐIỀN]
- Email liên hệ về dữ liệu cá nhân: [CẦN ĐIỀN]

## 2. Dữ liệu cá nhân được thu thập

Khi bạn đăng ký và sử dụng SplitDebt, ứng dụng thu thập các nhóm dữ liệu sau:

- **Thông tin tài khoản:** họ tên, địa chỉ email, số điện thoại (nếu bạn tự nhập), mật khẩu đã được băm an toàn.
- **Dữ liệu nhóm và công nợ:** danh sách nhóm bạn tham gia, vai trò trong nhóm, các khoản chi tiêu, phần chia của từng thành viên, lịch sử thanh toán và xác nhận công nợ.
- **Tin nhắn trong nhóm:** nội dung tin nhắn bạn gửi trong các nhóm chi tiêu.
- **Ảnh đại diện:** hình ảnh bạn chọn tải lên làm ảnh đại diện.
- **Mã thông báo đẩy (push token):** mã thiết bị do Firebase cấp để gửi thông báo khi có khoản chi, nhắc nợ hoặc tin nhắn mới.
- **Thông tin kỹ thuật:** nền tảng thiết bị (`android`, `ios`, `web`), phiên bản ứng dụng và lịch sử các lần bạn đồng ý với Chính sách và Điều khoản.

**Lưu ý riêng về tính năng Quét hoá đơn:** Ảnh và văn bản đọc từ hoá đơn được xử lý hoàn toàn ngay trên điện thoại của bạn. Ảnh hoá đơn và nội dung thô không được gửi về máy chủ của SplitDebt hay bất kỳ bên thứ ba nào. Chỉ những món hàng và số tiền bạn tự xác nhận lưu mới được gửi lên máy chủ như một khoản chi thông thường.

## 3. Mục đích và căn cứ xử lý dữ liệu

SplitDebt xử lý dữ liệu của bạn dựa trên **sự đồng ý rõ ràng của bạn** khi đăng ký hoặc đồng ý lại phiên bản mới, và để **thực hiện dịch vụ bạn yêu cầu**:

- Tạo và xác thực tài khoản đăng nhập.
- Quản lý nhóm, tính toán công nợ, ghi nhận thanh toán và đồng bộ tin nhắn nhóm.
- Gửi thông báo đẩy khi bạn cho phép quyền thông báo.
- Lưu bằng chứng về sự đồng ý theo quy định pháp luật.

Ứng dụng không dùng dữ liệu của bạn để quảng cáo và không tích hợp công cụ theo dõi hành vi bên thứ ba.

## 4. Bên nhận dữ liệu và nơi lưu trữ

Để vận hành dịch vụ, dữ liệu của bạn có thể được xử lý qua các hạ tầng sau:

- **Firebase (Google):** nhận push token để chuyển phát thông báo đẩy. Dữ liệu có thể được lưu trữ và xử lý trên máy chủ của Google tại nước ngoài.
- **Supabase:** lưu trữ ảnh đại diện bạn tải lên. Dữ liệu có thể được lưu trữ tại nước ngoài tuỳ theo vùng máy chủ đã cấu hình ([CẦN ĐIỀN: vùng máy chủ Supabase]).
- **Nhà cung cấp hosting backend và cơ sở dữ liệu:** [CẦN ĐIỀN: tên nhà cung cấp và quốc gia/vùng đặt máy chủ] lưu trữ thông tin tài khoản, nhóm, khoản chi, thanh toán, tin nhắn và nhật ký đồng ý.

## 5. Thời gian lưu trữ và xoá dữ liệu

- Dữ liệu của bạn được lưu giữ trong suốt thời gian tài khoản còn hoạt động.
- Khi bạn thực hiện xoá tài khoản (sau khi đã thanh toán hết công nợ trong các nhóm), thông tin nhận diện cá nhân (họ tên, email, số điện thoại, ảnh đại diện), push token, cài đặt cá nhân, thông báo và nhật ký hoạt động sẽ bị xoá hoặc ẩn danh hoá ngay lập tức.
- Tin nhắn bạn đã gửi trong nhóm được thay nội dung thành "Tin nhắn đã bị xoá".
- Các khoản chi, phần chia và thanh toán đã phát sinh trong nhóm được giữ lại dưới dạng ẩn danh để không làm sai lệch sổ nợ của các thành viên khác.
- Lịch sử bản ghi đồng ý được giữ lại làm bằng chứng tuân thủ pháp luật.

## 6. Quyền của bạn và cách thực hiện trong ứng dụng

Bạn có các quyền sau đối với dữ liệu cá nhân của mình:

- **Xem và sao chép dữ liệu của mình:** vào tab Cá nhân, chọn **Quyền riêng tư**, rồi chọn **Xem dữ liệu của tôi** để xem toàn bộ dữ liệu dạng JSON và sao chép.
- **Chỉnh sửa thông tin cá nhân:** vào tab Cá nhân, chọn mục chỉnh sửa **Hồ sơ cá nhân** để cập nhật họ tên, số điện thoại hoặc ảnh đại diện.
- **Bật hoặc tắt thông báo:** xem trạng thái tại **Trung tâm Quyền riêng tư** và thay đổi trong **Cài đặt của điện thoại**.
- **Xoá tài khoản và rút lại đồng ý bắt buộc:** vào tab Cá nhân, chọn **Quyền riêng tư**, rồi chọn **Xoá tài khoản** (hoặc gửi yêu cầu qua email [CẦN ĐIỀN]).
- **Khiếu nại hoặc yêu cầu hỗ trợ khác về dữ liệu:** gửi email tới [CẦN ĐIỀN]. Thời hạn phản hồi và xử lý yêu cầu tối đa là 30 ngày kể từ ngày nhận đủ thông tin hợp lệ.

## 7. Biện pháp bảo vệ dữ liệu

- Toàn bộ kết nối giữa ứng dụng và máy chủ được mã hoá bằng HTTPS.
- Mật khẩu được băm một chiều bằng thuật toán bcrypt trước khi lưu.
- Dữ liệu nhóm, khoản chi và tin nhắn được kiểm soát quyền truy cập theo tư cách thành viên của từng nhóm.

## 8. Quy định về trẻ em

SplitDebt chỉ dành cho người dùng từ đủ 16 tuổi trở lên. Khi đăng ký, người dùng phải chủ động xác nhận đã đủ 16 tuổi. Nếu phát hiện tài khoản do người dưới 16 tuổi tạo lập, chúng tôi sẽ khoá và xử lý xoá dữ liệu theo yêu cầu hợp lệ.

## 9. Thay đổi Chính sách quyền riêng tư

Khi Chính sách này có thay đổi quan trọng, chúng tôi sẽ cập nhật số phiên bản và thông báo rõ nội dung thay đổi. Bạn cần xem và đồng ý lại với phiên bản mới trong ứng dụng trước khi tiếp tục sử dụng các tính năng nghiệp vụ.

## 10. Căn cứ pháp lý

Chính sách này được xây dựng trên cơ sở **Luật Bảo vệ dữ liệu cá nhân số 91/2025/QH15** và **Nghị định 356/2025/NĐ-CP** của pháp luật Việt Nam.
