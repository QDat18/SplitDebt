# Báo cáo tái cấu trúc SplitDebt

Ngày: 2026-10-02

## Kết quả chính

- Hợp nhất cấu trúc Flutter vào `features/groups` và `features/settlements`; repository xác thực dùng một nguồn duy nhất tại `data/repositories`.
- Đồng bộ API công nợ, thống kê và thanh toán để backend xác định người dùng từ JWT thay vì tin `userId` do client gửi.
- Bổ sung kiểm tra thành viên nhóm, vai trò quản trị, payer, participant, số tiền, tỷ lệ, trọng số và item split cho expense.
- Gia cố đăng ký/đăng nhập: chuẩn hóa email, kiểm tra email, họ tên và độ dài mật khẩu.
- Loại bỏ truy vấn balance N+1 ở thẻ nhóm và log chứa dữ liệu phản hồi xác thực.
- Chuyển Firebase, JWT, database, CORS và URL API sang `.env`; tạo `.env.example`; bỏ các file cấu hình Firebase chứa khóa khỏi Git.
- Cập nhật README, tài liệu API, Postman, Maven Wrapper Windows và Android toolchain.

## Kiểm thử và build

| Hạng mục | Kết quả |
|---|---|
| Backend `mvn test` | 23/23 pass |
| Frontend `flutter test` | 3/3 pass |
| Flutter analyze | 0 error, 0 warning, 76 info lint |
| Android debug APK | Build thành công |
| Secret scan file tracked | 0 mẫu secret |
| Android emulator | Pass: Android 15 / Pixel 6, onboarding và đăng nhập render đúng |

APK debug được tạo tại `frontend/build/app/outputs/flutter-apk/app-debug.apk` (184,945,584 bytes).

## Ghi chú vận hành

- Backend dùng JDK 21 và chạy cổng 8081.
- Android Emulator truy cập backend máy host qua URL mặc định `http://10.0.2.2:8081/api` trong `.env` frontend.
- Thiết bị Android thật phải đặt URL API thành IP LAN của máy chạy backend.
- Đã tạo AVD `SplitDebt_API_35`; có thể mở trực tiếp từ Android Studio Device Manager.
- Smoke test phát hiện và đã sửa lỗi tên biến Firebase Android trong `.env` khiến app dừng trước `runApp`.
- Các cảnh báo nâng cấp Gradle/AGP/Kotlin là cảnh báo tương lai của Flutter; cấu hình hiện tại build thành công.
