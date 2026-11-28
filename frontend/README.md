# SplitDebt Frontend

Ứng dụng mobile quản lý chi tiêu nhóm, chia khoản chi, theo dõi công nợ và xác nhận thanh toán. Toàn bộ mã nghiệp vụ frontend được viết bằng Dart với Flutter; thư mục `android/` chỉ chứa hạ tầng build do Flutter/Gradle sử dụng.

## Công nghệ

- Dart 3 và Flutter 3.47+
- Riverpod cho state management
- Dio cho HTTP client
- Firebase Core và Firebase Cloud Messaging
- `shared_preferences` cho JWT, tùy chọn và trạng thái onboarding
- `fl_chart` cho biểu đồ tài chính

## Chức năng

- Đăng ký, đăng nhập và duy trì phiên bằng JWT.
- Tạo nhóm, quản lý thành viên và thiết lập nhóm.
- Tạo khoản chi với các kiểu chia đều, số tiền, phần trăm, trọng số hoặc theo món.
- Xem tổng quan thu chi, số dư và lịch sử nhóm.
- Tối ưu công nợ, báo đã thanh toán và xác nhận thanh toán hai chiều.
- Nhận và quản lý thông báo Firebase.
- Xuất nội dung tổng quan và chi tiết khoản chi dạng PDF.

## Yêu cầu môi trường

- Flutter stable 3.47 hoặc mới hơn.
- Android Studio, Android SDK và JDK 21.
- Backend chạy tại cổng `8081`.
- Android Emulator hoặc thiết bị Android thật.

Kiểm tra môi trường:

```powershell
flutter doctor -v
flutter devices
```

## Cấu hình `.env`

Tạo file cấu hình local:

```powershell
Copy-Item .env.example .env
```

Các nhóm biến cần cấu hình:

| Nhóm | Mục đích |
|---|---|
| `API_BASE_URL` | Base URL của SplitDebt API |
| `FIREBASE_ANDROID_*` | Firebase client cho Android |
| `FIREBASE_WEB_*` | Firebase client cho web |
| `FIREBASE_IOS_*` | Firebase client cho iOS nếu sử dụng |
| `FCM_WEB_VAPID_KEY` | VAPID public key cho FCM web |

Không đặt database password, JWT secret hoặc Firebase service-account trong frontend.

URL theo môi trường:

- Android Emulator: `http://10.0.2.2:8081/api`
- Flutter Web: `http://localhost:8081/api`
- Thiết bị thật: `http://<IP-LAN-MAY-CHAY-BACKEND>:8081/api`

`API_BASE_URL` cũng có thể được ghi đè khi chạy:

```powershell
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8081/api
```

## Cài đặt và chạy

```powershell
flutter pub get
flutter run
```

Chạy trên AVD đã tạo cho dự án:

```powershell
flutter emulators --launch SplitDebt_API_35
flutter devices
flutter run -d emulator-5554
```

Trong Android Studio:

1. Mở thư mục `frontend`.
2. Chờ Flutter và Gradle đồng bộ dependency.
3. Mở Device Manager và khởi động `SplitDebt_API_35` hoặc một AVD khác.
4. Chọn thiết bị rồi chạy `lib/main.dart`.

## Kiến trúc mã nguồn

```text
lib/
├── core/
│   ├── api/             # API client cơ sở
│   ├── app/             # Global keys và khung hiển thị mobile
│   ├── constants/       # Cấu hình đọc từ .env/dart-define
│   ├── network/         # Dio, interceptor và response envelope
│   ├── providers/       # Trạng thái dùng chung
│   ├── storage/         # Lưu JWT qua shared_preferences
│   └── theme/           # Màu, typography, spacing và PDF components
├── data/
│   └── repositories/    # Repository dùng chung nhiều feature
├── features/
│   ├── auth/            # Onboarding, đăng ký, đăng nhập, splash
│   ├── expenses/        # Tạo và xem khoản chi
│   ├── groups/          # Nhóm, thành viên, model, provider và widget
│   ├── home/            # Tổng quan và lịch sử
│   ├── notifications/   # Inbox và Firebase Messaging
│   ├── profile/         # Hồ sơ và thiết lập cá nhân
│   └── settlements/     # Công nợ, thống kê và thanh toán
├── firebase_options.dart
├── main_layout_screen.dart
└── main.dart
```

Luồng phụ thuộc chính:

```text
Screen/Widget → Provider/Repository → DioClient → Spring Boot API
                                       ↓
                                TokenStorage (JWT)
```

Danh tính đăng nhập do JWT quyết định. Client không gửi `userId` để backend dùng làm căn cứ phân quyền.

## Quy ước comment

- Mỗi file Dart có phần `Trách nhiệm file` ở đầu file.
- Comment giải thích mục đích, quy tắc nghiệp vụ hoặc quyết định khó hiểu.
- Không comment lại cú pháp hiển nhiên và không ghi key/secret trong comment.

## Kiểm thử và build

```powershell
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

Bản debug chỉ dùng trong quá trình phát triển:

```powershell
flutter build apk --debug
```

APK debug được tạo tại `build/app/outputs/flutter-apk/app-debug.apk`.

### APK release gọn cho điện thoại

Chạy từ thư mục `frontend`:

```powershell
.\build-apk.ps1
```

Có thể ghi đè API của bản phát hành bằng URL HTTPS:

```powershell
.\build-apk.ps1 -ApiBaseUrl https://api.example.com/api
```

Script build ở chế độ release, tách APK theo kiến trúc CPU, bật tree shaking cho icon và lưu thông tin debug của Dart ngoài APK tại một thư mục riêng trong `build/symbols/` cho mỗi lần build. Cấu hình release Android bật R8 và thu gọn tài nguyên để loại mã Android và tài nguyên không được dùng. Các APK nằm tại:

```text
build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk
build/app/outputs/flutter-apk/app-x86_64-release.apk
```

| APK | Thiết bị sử dụng |
|---|---|
| `app-arm64-v8a-release.apk` | Phần lớn điện thoại Android hiện nay |
| `app-armeabi-v7a-release.apk` | Điện thoại Android dùng CPU ARM 32 bit |
| `app-x86_64-release.apk` | Thiết bị Intel hoặc emulator x86_64 |

Mỗi người dùng chỉ cần cài APK đúng kiến trúc thiết bị. Giữ lại thư mục symbols được script thông báo và `build/app/outputs/mapping/release/` cùng APK của từng bản phát hành để giải mã stack trace khi có crash. Lưu các file này trước lần build kế tiếp hoặc trước khi chạy `flutter clean`.

Nếu phân phối qua Google Play, có thể build Android App Bundle để Play cung cấp phần phù hợp với từng thiết bị:

```powershell
$releaseId = Get-Date -Format 'yyyyMMdd-HHmmss-fff'
flutter build appbundle --release --tree-shake-icons --split-debug-info="build/symbols/play-$releaseId"
```

Bundle được tạo tại `build/app/outputs/bundle/release/app-release.aab`. Cũng lưu symbols và R8 mapping riêng cho mỗi bản bundle.

### Phạm vi dọn dẹp

`build/`, `.dart_tool/` và cache Gradle là dữ liệu build trên máy phát triển; xóa chúng chỉ giải phóng dung lượng máy và khiến lần build tiếp theo cần tạo lại. Mã nguồn Dart, test, tài liệu, thư mục iOS và web không được đóng nguyên thư mục vào APK Android, nên xóa chúng không làm APK người dùng nhỏ hơn. Flutter release biên dịch mã Dart và loại phần không sử dụng.

Giữ các thư viện và model OCR/QR được đóng kèm để quét hóa đơn, quét QR vẫn hoạt động offline; giữ tính năng xuất PDF và các luồng nghiệp vụ hiện có.

## Bảo mật

- JWT hiện được lưu bằng `shared_preferences`; đây không phải kho lưu trữ được mã hóa.
- Phản hồi xác thực không được ghi nguyên văn ra log.
- Android release chặn cleartext HTTP; debug cho phép HTTP để kết nối backend local.
- `.env`, `google-services.json` và `firebase.json` không được commit.
- Firebase client identifiers vẫn có thể được quan sát trong ứng dụng đã build; dữ liệu phải được bảo vệ bằng backend authorization và Firebase Security Rules.

## Xử lý lỗi thường gặp

- Không gọi được backend trên emulator: kiểm tra backend cổng `8081` và dùng host `10.0.2.2`, không dùng `localhost`.
- Dừng ở màn hình splash: kiểm tra đầy đủ các biến `FIREBASE_ANDROID_*` trong `.env`, sau đó build lại APK.
- Không nhận FCM: kiểm tra quyền notification, Firebase project và token đăng ký trên backend.
- Gradle dùng sai Java: chọn JDK 21 trong Android Studio và kiểm tra `android/gradle.properties`.

Không chỉnh sửa hoặc commit key thật vào source. Chỉ cập nhật tên biến mẫu trong `.env.example`.
