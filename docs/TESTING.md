# SplitDebt – kế hoạch kiểm thử đầy đủ

Tài liệu này mô tả bộ kiểm thử đi kèm source. Mục tiêu là kiểm tra từ thuật toán chia tiền đến API, giao diện Flutter, luồng end-to-end, build và các yêu cầu phi chức năng quan trọng.

> **Phạm vi hiện tại:** Android là nền tảng nghiệm thu chính; Web được dùng thêm để chạy nhanh UI/integration test. SplitDebt chỉ **ghi nhận** thanh toán thực hiện ngoài hệ thống, không kiểm thử chuyển tiền thật qua ngân hàng/MoMo/ZaloPay. Firebase push thật cũng cần project Firebase/thiết bị thật nên nằm trong checklist tích hợp thủ công; backend hiện vẫn kiểm thử bản ghi thông báo in-app.

## 1. Chạy toàn bộ trên Windows

Từ thư mục gốc `SplitDebt`:

```powershell
.\test-all.ps1
```

Bản nhanh, bỏ build Web/APK và Flutter E2E:

```powershell
.\test-all.ps1 -Fast
```

Nếu máy chưa có Android toolchain hoàn chỉnh:

```powershell
.\test-all.ps1 -SkipAndroid
```

Bỏ E2E backend tạm thời:

```powershell
.\test-all.ps1 -SkipE2E
```

Yêu cầu: Java/JDK, Flutter SDK và Python 3. Script chấp nhận cả lệnh `python` hoặc `py -3` trên Windows. Không cần Visual Studio nếu chỉ kiểm thử Android/Web.

## 2. Những lớp kiểm thử đã có

| Tầng | File / suite | Nội dung chính |
|---|---|---|
| Thuật toán | `LedgerMathTests`, `api/tools/LedgerMathCheck.java` | chia đều, largest remainder, tỷ lệ/trọng số, bảo toàn tổng tiền, Smart Settlement, 10.000 bộ dữ liệu ngẫu nhiên |
| Security primitives | `SecurityPrimitiveTests` | PBKDF2 có salt, kiểm tra mật khẩu, JWT issue/verify, token bị sửa/malformed |
| Auth HTTP | `AuthControllerContractTests` | register/login, validation, email trùng, sai mật khẩu, endpoint bảo vệ, JSON lỗi |
| Nhóm | `GroupLifecycleTests` | owner/member, invite code, add/remove, quyền, không xóa thành viên còn nợ |
| Chia tiền | `ExpenseSplitModeTests` | EQUAL, AMOUNT, PERCENT, WEIGHT, ITEM; dữ liệu sai; category/payer/participant; VND/USD |
| Sửa/xóa chi | `ExpenseMutationTests` | quyền edit/delete, cập nhật lại debt, cleanup bảng liên quan, 404 |
| Quyết toán | `SettlementLifecycleTests` | PAID → CONFIRMED, cancel, chống overpay, sai chiều, xác nhận hai phía |
| Cài đặt/thông báo/thống kê | `SettingsNotificationStatisticsTests` | user/group settings, notification ownership/preferences, statistic range, activity pagination, category seed |
| REST E2E trong JVM | `RestApiEndToEndTests` | hành trình register → login → group → expense → debt → settlement → statistics/notifications |
| REST E2E process thật | `tools/e2e_api.py` | gọi HTTP vào backend riêng trên port 18080 với cả positive/negative path |
| Flutter data/API | `frontend/test/api_test.dart` | encode/decode JSON, timeout, error, token persistence, 401 logout, `/me` restore |
| Flutter auth UI | `auth_screens_test.dart` | validate form, password visibility, login/register success, terms |
| Flutter onboarding/help | `onboarding_guide_test.dart` | skip/complete onboarding và quick guide cho người mới |
| Flutter form validation | `form_validation_test.dart` | tạo/tham gia nhóm, profile, email thành viên |
| Flutter feedback | `feedback_widget_test.dart` | success/error/warning/info và success dialog |
| Flutter smoke | `widget_test.dart` | app/session gate cơ bản |
| Flutter + API E2E | `integration_test/auth_group_flow_test.dart` | UI thật: register → login → dismiss guide → create group |
| Build/CI | `.github/workflows/verify.yml` | Maven verify + JaCoCo, REST E2E, Flutter analyze/test, Web build, APK build |

## 3. Lệnh chạy riêng

Backend:

```powershell
cd api
.\mvnw.cmd clean verify
```

Báo cáo coverage Java sau khi chạy:

```text
api/target/site/jacoco/index.html
```

Flutter:

```powershell
cd frontend
flutter pub get
flutter analyze --no-fatal-infos
flutter test --coverage
flutter build web --debug
flutter build apk --debug
```

Coverage Flutter:

```text
frontend/coverage/lcov.info
```

E2E API độc lập, không dùng Supabase thật:

```powershell
cd api
$env:SPRING_PROFILES_ACTIVE='e2e'
.\mvnw.cmd spring-boot:run
```

Terminal thứ hai:

```powershell
$env:SPLITDEBT_E2E_URL='http://127.0.0.1:18080/api'
python tools/e2e_api.py
```

Flutter integration test với backend E2E:

```powershell
cd frontend
flutter test integration_test/auth_group_flow_test.dart -d chrome --dart-define=API_URL=http://127.0.0.1:18080/api
```

## 4. Performance smoke

SRS đặt mục tiêu đề xuất màn hình chính tải khoảng 3 giây khi mạng ổn định. Backend E2E phải đang chạy trên `18080`, sau đó:

```powershell
python tools/performance_smoke.py --requests 30 --concurrency 5 --max-p95-ms 3000
```

Đây là smoke benchmark local, không thay cho load/stress test production. Kết quả phụ thuộc máy, JVM, database và mạng.

## 5. Ma trận nghiệp vụ phải pass trước nghiệm thu

| Nghiệp vụ | Positive path | Negative/boundary path |
|---|---|---|
| Đăng ký | dữ liệu hợp lệ tạo account | email sai, mật khẩu ngắn, chưa đồng ý điều khoản, email trùng |
| Đăng nhập | token hợp lệ, restore session | sai password, token lỗi/hết hạn, request không token |
| Nhóm | tạo group, owner, join invite | currency sai, invite không tồn tại, outsider truy cập |
| Thành viên | owner add/remove | member tự quản lý, remove owner, remove người còn debt |
| Expense | lưu đủ 5 split type | 0/âm/quá lớn, participant trùng/ngoài group, tổng AMOUNT sai, % != 100, weight <= 0, item sai |
| Debt | balance đúng sau add/edit/delete | không dùng local stale balance khi backend reject |
| Smart Settlement | bảo toàn tiền, giảm transfer | ledger lệch tổng, pending payment không bị đề xuất lại |
| Settlement | debtor ghi nhận, creditor confirm | self-pay, sai chiều, overpay, confirm sai người, confirm/cancel lặp |
| Notification | đúng user/type/read | user khác không mark read; preference tắt phải được tôn trọng |
| Statistics | total/category/payer/range | range sai, outsider không xem dữ liệu |
| Activity | mới nhất trước, pagination | limit/offset sai, outsider không thấy group khác |
| Settings | partial update | enum/range sai, member không sửa group settings, khóa currency sau phát sinh tài chính |

## 6. Checklist kiểm thử thủ công trên Android thật/emulator

Các mục này cần thiết bị/môi trường thực tế và không nên coi là đã pass chỉ vì unit test xanh:

- Cài APK sạch → Splash → Onboarding → Login/Register; đóng/mở lại app và kiểm tra session.
- Kích thước màn hình nhỏ/lớn, font scale lớn; không overflow; portrait/landscape nếu app hỗ trợ.
- Mất mạng giữa lúc tải/lưu; phải có loading, lỗi dễ hiểu và retry; không tạo bản ghi lặp do tap liên tục.
- Xóa expense/nhóm phải có confirmation; Back/gesture không làm mất dữ liệu ngoài ý muốn.
- Kiểm tra định dạng VND, USD/EUR và rounding bằng dữ liệu biên.
- Hai tài khoản/thiết bị: user A trả → user B xác nhận; refresh cả hai phía và đối chiếu debt.
- Token hết hạn → trở về login; tài khoản ngoài group không thấy expense/debt/notification của group.
- Nếu triển khai thực tế: HTTPS, Supabase/PostgreSQL thật, backup/restore, secret không nằm trong source/log.
- Nếu bật Firebase: kiểm tra notification foreground/background/terminated và quyền notification trên Android.

## 7. CI

Mỗi `push`/`pull_request`, GitHub Actions chạy ba job: backend tests + JaCoCo, REST E2E process thật bằng H2, và Flutter analyze/test/build. Một PR chỉ nên merge khi các job bắt buộc đều xanh.

## 8. Tiêu chí hoàn thành

Một bản build được coi là sẵn sàng demo khi:

1. `test-all.ps1` pass trên máy có đủ SDK.
2. GitHub Actions xanh.
3. Không còn lỗi `flutter analyze` mức error/warning do code của project.
4. REST E2E pass.
5. APK debug build thành công và checklist Android nghiệp vụ chính đã được chạy ít nhất một lần.
6. Không có `.env`, database password, JWT secret thật hoặc keystore secret trong commit/ZIP bàn giao.
