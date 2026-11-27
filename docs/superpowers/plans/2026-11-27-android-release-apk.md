# Xuất file APK để cài lên máy Android

**Mục tiêu:** có file `.apk` bản release mà bạn bè hoặc giảng viên tải về, cài lên điện thoại Android thật, đăng nhập và dùng được mọi tính năng.

## Hiện trạng (Claude Code đã kiểm tra)

| Mục | Hiện tại | Vấn đề khi phát hành |
|---|---|---|
| Ký app | Bản release ký bằng **khoá debug** | Mỗi máy build có khoá debug khác nhau, nên bản cập nhật build trên máy khác **không cài đè được** (phải gỡ app, mất dữ liệu đăng nhập) |
| Backend | `API_BASE_URL` mặc định `http://10.0.2.2:8081/api` | Địa chỉ này **chỉ có trên máy ảo Android**. Điện thoại thật không gọi tới được |
| HTTP | Bản release đặt `usesCleartextTraffic="false"` | Bản release **chặn `http://`**, nên backend phải là `https://` |
| Tên app | `android:label="split_debt"` | Màn hình chính của điện thoại hiện chữ "split_debt" |
| Application ID | `com.example.split_debt` | Google Play từ chối `com.example`. Cài APK thì vẫn được. Đổi về sau thì thành một app khác, người dùng phải gỡ bản cũ |
| `.env` | Được đóng gói vào APK | Chỉ chứa cấu hình Firebase phía client (công khai được), nên không sao. **Tuyệt đối không thêm khoá bí mật vào `frontend/.env`** |
| Quyền | Có `INTERNET`, `POST_NOTIFICATIONS` | Ổn |
| OCR Lab | Chỉ hiện khi `kDebugMode` | Tự ẩn ở bản release, ổn |

## Điều kiện trước: backend phải truy cập được qua https

Plan này **không** gồm việc deploy backend. Chọn một trong hai:
- **Deploy backend** (ví dụ Render, Railway, VPS) và có URL `https://…/api`. Đây là cách nên làm nếu nhiều người cùng dùng thử. Cần một plan riêng.
- **Tunnel tạm khi demo:** chạy backend trên laptop rồi mở `cloudflared tunnel --url http://localhost:8081` để có URL https. Chỉ dùng được khi laptop đang bật.

Có URL rồi thì truyền vào lúc build (xem A4). Không sửa giá trị mặc định trong code.

## Phần Antigravity làm

Áp dụng Global Constraints chung: không thêm dependency, không đọc hay commit `.env`, không commit `key.properties` hay file `.jks`. Mỗi mục một commit. Không push.

### A1. Đổi Application ID thành `vn.hvnh.splitdebt` (chỉ làm khi chủ dự án đồng ý trong prompt)

Thống nhất với Bundle ID iOS.
- `android/app/build.gradle.kts`: `namespace` và `applicationId` đổi thành `vn.hvnh.splitdebt`.
- Chuyển `android/app/src/main/kotlin/com/example/split_debt/MainActivity.kt` sang `kotlin/vn/hvnh/splitdebt/MainActivity.kt` và sửa dòng `package`. Xoá thư mục cũ.
- Tìm toàn repo chuỗi `com.example.split_debt` và sửa hết chỗ còn sót (trừ trong `docs/`).
- **Ghi vào PROGRESS:** chủ dự án phải thêm app Android `vn.hvnh.splitdebt` vào Firebase và cập nhật `FIREBASE_ANDROID_APP_ID` trong `.env`. Nếu không, push trên Android ngừng hoạt động (app vẫn chạy).

### A2. Ký bản release bằng khoá riêng

Trong `android/app/build.gradle.kts`:
- Đọc `android/key.properties` nếu file tồn tại (`storeFile`, `storePassword`, `keyAlias`, `keyPassword`), rồi tạo `signingConfigs.create("release")`.
- `buildTypes.release.signingConfig`: dùng `release` nếu có `key.properties`. Nếu không có thì dùng `debug` và in cảnh báo ở bước configure ("Không tìm thấy key.properties, bản release đang ký bằng khoá debug"), để máy khác vẫn build được.
- Tạo `android/key.properties.example` (không có mật khẩu thật) mô tả 4 trường.
- Xác nhận `android/.gitignore` đã chặn `key.properties`, `*.jks`, `*.keystore` (hiện đã có).

### A3. Tên app và phiên bản

- `AndroidManifest.xml`: `android:label="SplitDebt"`.
- Phiên bản đang nằm ở hai nơi: `pubspec.yaml` (`version: 1.0.0+1`) và `AppConstants.appVersion` (`'1.0.0'`). Thêm test `test/app_version_test.dart`: đọc `pubspec.yaml`, so phần trước dấu `+` với `AppConstants.appVersion`, lệch thì FAIL. Nhờ vậy mỗi lần tăng phiên bản không bị quên một nơi.

### A4. Script build

Tạo `frontend/tool/build_apk.ps1` (PowerShell, vì máy dev là Windows):
- Tham số bắt buộc `-ApiBaseUrl` (phải bắt đầu bằng `https://`, nếu không thì dừng và báo).
- Chạy `flutter build apk --release --dart-define=API_BASE_URL=<url>`. Bản universal cài được trên mọi máy, nên dùng bản này để chia sẻ.
- Chạy thêm `flutter build apk --release --split-per-abi --dart-define=...` để có các file nhỏ hơn.
- Cuối cùng in đường dẫn, dung lượng và SHA-256 của từng file APK, và cảnh báo nếu chưa có `key.properties`.

### A5. Tài liệu `docs/android-release.md`

Gồm:
1. **Tạo khoá ký (làm một lần):** lệnh `keytool -genkey -v -keystore <đường dẫn ngoài repo>\splitdebt-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias splitdebt`, và cách điền `android/key.properties`. Cảnh báo: **mất file `.jks` hoặc mật khẩu thì không bao giờ cập nhật được app đã cài**. Hãy sao lưu file này vào chỗ an toàn, không để trong repo.
2. **Build:** `.\tool\build_apk.ps1 -ApiBaseUrl https://<domain>/api`.
3. **Phát hành bản mới:** tăng `version` trong `pubspec.yaml` (cả số sau dấu `+`) và `AppConstants.appVersion`, rồi build lại. Bản mới cài đè lên bản cũ được nếu cùng khoá ký.
4. **Chia sẻ:** tải file APK universal lên Google Drive hoặc GitHub Releases (đính kèm SHA-256).
5. **Hướng dẫn người cài:** mở link bằng điện thoại, tải APK, cho phép "Cài ứng dụng không rõ nguồn gốc" với trình duyệt hoặc ứng dụng File. Play Protect có thể cảnh báo: chọn "Vẫn cài đặt".
6. **Kiểm tra sau khi cài:** đăng ký, đăng nhập, tạo nhóm, thêm khoản chi, quét hoá đơn (camera và thư viện), chat, nhận thông báo, xoá tài khoản.

## Kiểm tra cuối (Antigravity)

- `flutter analyze` 0 error, `flutter test -j 1` PASS (gồm `app_version_test`).
- Chạy được `.\tool\build_apk.ps1 -ApiBaseUrl https://example.com/api` khi **không** có `key.properties`: build thành công, có cảnh báo khoá debug. Không cần backend thật cho bước này.
- Cập nhật `docs/PROGRESS.md`. Không push.

## Phần chủ dự án làm

1. Có URL backend https (deploy hoặc tunnel).
2. Tạo khoá ký theo `docs/android-release.md` mục 1, điền `android/key.properties`.
3. Nếu đã làm A1: thêm app Android `vn.hvnh.splitdebt` trên Firebase, cập nhật `.env`.
4. Build bằng script, cài thử lên máy ảo `Pixel_8a` (kéo file APK vào cửa sổ máy ảo), đi qua danh sách kiểm tra ở mục 6.
