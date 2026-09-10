# Validation status

## Đã rà soát trong gói này

- Runtime Flutter không còn `supabase_flutter`, `flutter_dotenv` hoặc cấu hình Supabase Auth cũ.
- Backend không còn truy vấn các bảng legacy `profiles` / `debt_groups`; nghiệp vụ chính dùng `users`, `groups`, `group_members`, `expenses`, `expense_participants`, `expense_items`, `item_participants`, `debts`, `settlements`, `notifications`, `group_settings`, `user_settings`.
- API URL của Flutter dùng `--dart-define=API_URL=...`; source ZIP không cần đóng gói file `.env` phía Flutter.
- `tools/check_activity_sql.py` đã chạy thành công để kiểm tra SQL lịch sử theo quyền thành viên, thứ tự và phân trang trên fixture tối giản.
- `LedgerMath` và `api/tools/LedgerMathCheck.java` đã được biên dịch bằng `javac` và chạy 10.000 bộ dữ liệu ngẫu nhiên; kiểm tra bảo toàn tổng tiền, làm tròn chia đều/chia tỷ lệ và Smart Settlement.
- Các local import Dart trong `frontend/lib` đã được kiểm tra là trỏ tới file tồn tại.
- Source archive được tạo bằng `tools/package_source.py`; script loại `.git`, `.idea`, build/cache và các file cấu hình riêng tư, đồng thời chạy `ZipFile.testzip()` trước khi báo PASS.

## Chưa thể chạy tại môi trường bàn giao

- `mvn verify`: Maven wrapper cần tải Maven/dependencies từ Maven Central nhưng shell hiện tại không truy cập được repository.
- `flutter analyze`, `flutter test`, APK build: Flutter/Dart SDK không được cài trong môi trường bàn giao.
- E2E trên PostgreSQL/Supabase PostgreSQL thật: chưa chạy để tránh tác động dữ liệu thật của người dùng.

## Trước khi demo/nộp

1. Chạy `api\\mvnw.cmd verify` (Windows) hoặc `./api/mvnw verify`.
2. Trong `frontend/`, chạy `flutter pub get`, `flutter analyze`, `flutter test`.
3. Chạy backend và `flutter run`; Android Emulator dùng API mặc định `http://10.0.2.2:8080/api`.
4. Với điện thoại thật dùng `flutter run --dart-define=API_URL=http://<IP-LAN>:8080/api`.
5. Kiểm thử hai tài khoản theo checklist trong `docs/SETUP.md`.
