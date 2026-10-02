# Kế hoạch tái cấu trúc Frontend và đồng bộ Backend

Ngày bắt đầu: 2026-10-02

Ngày hoàn tất: 2026-10-02
Trạng thái: Hoàn tất

## Mục tiêu

- Đưa Flutter về kiến trúc `core`, `data`, `features` như README.
- Hợp nhất repository, provider, model và màn hình trùng vai trò.
- Đồng bộ request/response giữa Flutter và Spring Boot.
- Gia cố xác thực, phân quyền và validation cho nghiệp vụ tiền.
- Đưa toàn bộ khóa/cấu hình nhạy cảm vào `.env`; chỉ commit `.env.example`.
- Xác nhận dự án phân tích, kiểm thử và build Android thành công.

## Kết quả theo giai đoạn

- [x] 1. Chụp baseline cấu trúc, toolchain, test và thiết bị.
- [x] 2. Đối chiếu endpoint frontend/backend và sửa sai lệch hợp đồng.
- [x] 3. Tái cấu trúc frontend theo feature/layer, hợp nhất mã trùng lặp.
- [x] 4. Điều chỉnh backend, validation và authorization phía server.
- [x] 5. Bổ sung kiểm thử hợp đồng model và thuật toán chia tiền.
- [x] 6. Chạy formatter, static analysis, toàn bộ test và build APK debug.
- [x] 7. Cài system image, tạo AVD Android 15, cài APK và smoke-test onboarding/đăng nhập.
- [x] 8. Ghi báo cáo tại `plans/reports` và chuyển kế hoạch sang `plans/completed`.

## Tiêu chí nghiệm thu

- `flutter analyze`: không có error/warning; còn 76 lint mức info từ UI cũ.
- `flutter test`: 3/3 thành công.
- `mvn test`: 23/23 thành công.
- `flutter build apk --debug`: thành công.
- APK: `frontend/build/app/outputs/flutter-apk/app-debug.apk`.
- AVD `SplitDebt_API_35`: APK cài thành công, onboarding và đăng nhập render đúng, không có fatal/unhandled exception.
- Base URL Android Emulator mặc định sử dụng `10.0.2.2`, có thể cấu hình từ `.env`.
- Không còn import từ nhánh `features/group` hoặc `features/settlement` cũ.
- Backend lấy danh tính từ JWT cho debt/stats/settlement và kiểm tra quyền expense phía server.
- Quét file được Git theo dõi không phát hiện mẫu secret; `.env` thật được Git ignore.

## Phạm vi

Đã kiểm tra bản debug trên máy ảo Android. Không thực hiện ký bản release hoặc đưa ứng dụng lên Store theo yêu cầu hiện tại.
