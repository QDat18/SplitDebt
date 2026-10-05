# Báo cáo Google Login và runtime

## Kết quả

- README frontend đã được đối chiếu và viết lại theo cây thư mục Dart/Flutter thực tế; loại mô tả Supabase/local database không tồn tại.
- Nút Google không còn là callback rỗng. Flutter lấy Google ID token và gửi tới `POST /api/auth/google`.
- Java API xác minh chữ ký, issuer, hạn token, email verified và audience; lưu Google `sub` làm định danh OAuth ổn định rồi phát JWT nội bộ.
- Firebase được khởi tạo bất đồng bộ để không chặn khung hình đầu. ANR do chờ Firebase trước `runApp` đã được loại bỏ.
- `.env.example` của frontend/backend có placeholder `GOOGLE_WEB_CLIENT_ID`; key thật chỉ nằm trong `.env` bị ignore.
- Cấu hình IDE `.idea`/`.vscode` và ảnh/XML runtime không được đưa vào commit.

## Kiểm thử đã chạy

- Backend Maven: 25 test, 0 failure, 0 error.
- Frontend Flutter: 3 test, tất cả đạt.
- Flutter analyze: không có error/warning; còn 73 lint mức info cũ.
- APK debug: build thành công.
- Android Emulator `SplitDebt_API_35`: cài APK thành công, hiển thị onboarding/login, không còn ANR/FATAL/Unhandled.
- Backend runtime H2: `/api/health` trả HTTP 200.
- Khi chưa đặt OAuth client ID, nút Google hiển thị hướng dẫn cấu hình có kiểm soát thay vì im lặng hoặc crash.

## Cấu hình ngoài repository

Để kiểm thử Google end-to-end với tài khoản thật, cần OAuth Web client ID của đúng Google Cloud/Firebase project và SHA-1/SHA-256 của keystore Android. Không ghi giá trị này vào báo cáo, README, source hoặc Git.
