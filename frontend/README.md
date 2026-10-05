# SplitDebt Frontend

Ứng dụng mobile quản lý chi tiêu nhóm, chia khoản chi, theo dõi công nợ và xác nhận thanh toán. Toàn bộ mã nghiệp vụ frontend được viết bằng Dart/Flutter; thư mục `android/` chỉ là hạ tầng build do Flutter và Gradle sử dụng.

## Công nghệ

- Dart 3.13 và Flutter 3.47+
- Riverpod cho state management
- Dio cho HTTP client
- `flutter_secure_storage` cho JWT
- Google Sign-In cho đăng nhập OAuth
- Firebase Core và Firebase Cloud Messaging
- `shared_preferences` cho trạng thái onboarding
- `fl_chart` cho biểu đồ tài chính

## Chức năng

- Đăng ký, đăng nhập email hoặc Google và duy trì phiên bằng JWT.
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

| Nhóm biến | Mục đích |
|---|---|
| `API_BASE_URL` | Base URL của SplitDebt API |
| `GOOGLE_WEB_CLIENT_ID` | OAuth Web client ID dùng để yêu cầu ID token cho backend |
| `FIREBASE_ANDROID_*` | Firebase client cho Android/FCM |
| `FIREBASE_WEB_*` | Firebase client cho web |
| `FIREBASE_IOS_*` | Firebase client cho iOS nếu sử dụng |
| `FCM_WEB_VAPID_KEY` | VAPID public key cho FCM web |

Không đặt database password, JWT secret, OAuth client secret hoặc Firebase service-account trong frontend. `.env` chỉ dùng local và đã bị Git bỏ qua; `.env.example` chỉ chứa giá trị mẫu.

URL theo môi trường:

- Android Emulator: `http://10.0.2.2:8081/api`
- Flutter Web: `http://localhost:8081/api`
- Thiết bị thật: `http://<IP-LAN-MAY-CHAY-BACKEND>:8081/api`

`API_BASE_URL` cũng có thể được ghi đè khi chạy:

```powershell
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8081/api
```

## Cấu hình Google Sign-In

Google Sign-In cần cấu hình ngoài mã nguồn trước khi đăng nhập bằng tài khoản thật:

1. Tạo OAuth Web client trong Google Cloud Console và đặt ID vào `GOOGLE_WEB_CLIENT_ID` của cả `frontend/.env` và `api/.env`.
2. Tạo OAuth Android client cho package `com.example.split_debt`.
3. Đăng ký SHA-1 và SHA-256 của debug keystore; khi release phải đăng ký thêm fingerprint của release keystore.
4. Cấu hình OAuth consent screen và tài khoản test nếu ứng dụng còn ở chế độ Testing.
5. Không đưa OAuth client secret vào ứng dụng mobile hoặc Git.

Luồng xác thực:

```text
Google account -> Google ID token -> POST /api/auth/google
                                      -> backend xác minh token
                                      -> JWT nội bộ của SplitDebt
```

Backend kiểm tra chữ ký, issuer, thời hạn và audience trước khi phát JWT. Frontend không gửi email thuần để yêu cầu đăng nhập.

## Cài đặt và chạy

```powershell
flutter pub get
flutter run
```

Chạy trên AVD của dự án:

```powershell
flutter emulators --launch SplitDebt_API_35
flutter devices
flutter run -d emulator-5554
```

Trong Android Studio:

1. Mở thư mục `frontend`.
2. Chờ Flutter và Gradle đồng bộ dependency.
3. Mở Device Manager và khởi động `SplitDebt_API_35` hoặc AVD tương thích.
4. Chọn thiết bị rồi chạy `lib/main.dart`.

## Kiến trúc mã nguồn thực tế

```text
lib/
├── core/
│   ├── api/             # API client cơ sở
│   ├── app/             # Global keys và khung hiển thị mobile
│   ├── constants/       # Cấu hình đọc từ .env/dart-define
│   ├── network/         # Dio, interceptor và response envelope
│   ├── providers/       # Trạng thái dùng chung
│   ├── storage/         # Lưu JWT bảo mật
│   └── theme/           # Màu, typography, spacing và PDF components
├── data/
│   └── repositories/    # Repository dùng chung nhiều feature
├── features/
│   ├── auth/            # Onboarding, email/Google login, đăng ký, splash
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
Screen/Widget -> Provider/Repository -> DioClient -> Spring Boot API
                                         |
                                         -> TokenStorage (JWT)
```

README cũ từng mô tả các thư mục `core/database`, `domain`, `injection_container.dart` và Supabase nhưng các thành phần đó không tồn tại trong mã nguồn hiện tại. Cấu trúc ở trên đã được đối chiếu trực tiếp với thư mục `lib/`.

## Quy ước comment

- Mỗi file Dart có phần `Trách nhiệm file` ở đầu file.
- Comment giải thích mục đích, quy tắc nghiệp vụ hoặc quyết định khó hiểu.
- Không ghi key, token, secret hoặc dữ liệu người dùng vào comment/log.

## Kiểm thử và build

```powershell
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug
```

APK debug được tạo tại `build/app/outputs/flutter-apk/app-debug.apk`.

## Bảo mật

- JWT được lưu bằng `flutter_secure_storage`.
- Google ID token chỉ được backend tin cậy sau khi xác minh đầy đủ.
- Phản hồi xác thực không được ghi nguyên văn ra log.
- Android release chặn cleartext HTTP; debug cho phép HTTP để kết nối backend local.
- `.env`, `google-services.json`, service-account, `.idea`, `.vscode` và file build không được commit.
- Firebase/OAuth client identifiers vẫn có thể được quan sát trong ứng dụng đã build; dữ liệu phải luôn được bảo vệ bằng backend authorization và Firebase Security Rules.

## Xử lý lỗi thường gặp

- Không gọi được backend trên emulator: kiểm tra backend cổng `8081` và dùng host `10.0.2.2`, không dùng `localhost`.
- Google báo `clientConfigurationError` hoặc hủy ngay sau khi chọn tài khoản: kiểm tra package name, SHA fingerprint và `GOOGLE_WEB_CLIENT_ID`.
- Backend từ chối Google ID token: bảo đảm frontend/backend dùng cùng một OAuth Web client ID.
- Dừng ở splash: kiểm tra đủ biến `FIREBASE_ANDROID_*` trong `.env`, sau đó build lại APK.
- Không nhận FCM: kiểm tra quyền notification, Firebase project và token đăng ký trên backend.
- Gradle dùng sai Java: chọn JDK 21 trong Android Studio và kiểm tra `android/gradle.properties`.
