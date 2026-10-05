# Kế hoạch sửa đăng nhập Google và kiểm chứng runtime

## Mục tiêu

- Đối chiếu cấu trúc Flutter thực tế với `frontend/README.md` và sửa tài liệu sai lệch.
- Hoàn thiện đăng nhập Google theo luồng Google ID token -> Java API xác minh -> JWT nội bộ.
- Không hard-code hoặc commit khóa/bí mật; mọi cấu hình được lấy qua biến môi trường.
- Kiểm thử backend, Flutter, APK và chạy thử trên Android Emulator.
- Chỉ push mã nguồn cần thiết lên `dev1-huy`; loại cấu hình IDE/máy cá nhân khỏi Git.

## Các bước

- [x] Kiểm tra README, cây thư mục và nguyên nhân nút Google không hoạt động.
- [x] Bổ sung luồng Google Sign-In ở Flutter và endpoint xác minh token ở Java API.
- [x] Cập nhật `.env.example`, README frontend/backend và kiểm thử tự động.
- [x] Build APK, chạy backend, cài/chạy APK trên Android Emulator và kiểm tra log.
- [x] Rà soát secret/file máy cá nhân và chuẩn bị đúng tập tin để commit/push `dev1-huy`.

## Tiêu chí hoàn tất

- Token Google không được tin cậy trước khi backend xác minh chữ ký, issuer và audience.
- API chỉ phát JWT nội bộ cho email Google đã xác minh.
- Test backend, `flutter analyze`, `flutter test`, `flutter build apk --debug` đạt.
- Ứng dụng mở được trên AVD; backend health trả HTTP 200.
- Không có `.env`, service-account, `google-services.json`, `.idea` hoặc artifact máy cá nhân trong commit.

## Kết quả kiểm chứng

- Backend: 25/25 test đạt; riêng 6/6 test auth đạt sau khi bổ sung ca chống chiếm tài khoản bằng Google subject khác.
- Frontend: 3/3 test đạt; `flutter analyze` không có error/warning, còn lint mức `info` có sẵn.
- APK debug build thành công, cài thành công và mở đúng `MainActivity` trên `SplitDebt_API_35`; không có crash fatal.
- Backend H2 tạm thời trả health HTTP 200 và `/api/auth/google` trả HTTP 400 với token rỗng.
- Khi local chưa có OAuth client ID, nút Google hiển thị thông báo cấu hình rõ ràng thay vì im lặng.
- Đăng nhập tài khoản Google thật cần OAuth Web client ID và SHA-1/SHA-256 được cấu hình ngoài repository.
