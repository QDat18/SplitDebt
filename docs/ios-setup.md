# Chạy SplitDebt trên iOS

Thư mục `frontend/ios` đã được cấu hình sẵn. Trên máy Mac chỉ cần làm các bước dưới đây.

## Đã cấu hình sẵn trong repo

- Deployment target iOS 15.0 (yêu cầu của ML Kit).
- Bundle ID: `vn.hvnh.splitdebt`.
- ML Kit chạy qua Swift Package Manager: đã có cờ linker `-ObjC -all_load`, và project đã tham chiếu `Runner/mlkit/LatinOCRResources.bundle`. File model được tải bằng script, không commit vào git.
- `Info.plist`:
  - câu mô tả quyền camera và ảnh;
  - `NSAllowsLocalNetworking` để gọi backend `http://` trong mạng LAN;
  - `UIBackgroundModes: remote-notification` (dùng khi bật push).
- Thiếu cấu hình Firebase iOS thì app **vẫn chạy**, chỉ không có thông báo đẩy. Dữ liệu vẫn tự làm mới.
- Trên máy ảo iOS, `API_BASE_URL=http://10.0.2.2:8081/api` tự đổi thành `localhost`.

## Cần trên máy Mac

- Xcode 15.3 trở lên (mở Xcode một lần để cài thêm thành phần, và cài một máy ảo iOS).
- Flutter (cùng kênh với máy Windows).
- CocoaPods: `brew install cocoapods`.

## Các bước

1. Lấy code: clone nhánh `dev2-dat`. **Chép file `frontend/.env` từ máy Windows sang**, vì file này không có trong git.
2. Cài đặt (một lần):
   ```
   cd frontend
   bash ios/setup_ios.sh
   ```
   Script bật Swift Package Manager, chạy `pub get`, tải model ML Kit, chạy `pod install`.
3. Ký app (một lần): `open ios/Runner.xcworkspace` → chọn target **Runner** → **Signing & Capabilities** → **Team**: chọn Apple ID của bạn (tài khoản miễn phí cũng được).
4. Chạy:
   ```
   flutter run
   ```
   Chọn máy ảo iOS hoặc iPhone đang cắm cáp.

## Backend

| Chạy app trên | `API_BASE_URL` |
|---|---|
| Máy ảo iOS, backend chạy trên chính Mac đó | giữ mặc định (`10.0.2.2` tự đổi thành `localhost`) |
| iPhone thật, backend trên máy trong cùng Wi-Fi | `flutter run --dart-define=API_BASE_URL=http://<IP-LAN>:8081/api` |
| Backend đã deploy hoặc tunnel (ngrok, cloudflared) | `flutter run --dart-define=API_BASE_URL=https://<domain>/api` |

## Firebase và thông báo đẩy (tuỳ chọn)

1. Firebase Console → thêm app **iOS** với Bundle ID `vn.hvnh.splitdebt`.
2. Điền các biến `FIREBASE_IOS_*` trong `frontend/.env` (xem `.env.example`).
3. Push trên iOS cần **tài khoản Apple Developer trả phí**:
   - Xcode → Signing & Capabilities → **+ Capability** → **Push Notifications**;
   - tạo APNs Auth Key (.p8) trên developer.apple.com và tải lên Firebase → Project settings → Cloud Messaging.

   **Không thêm capability Push Notifications khi dùng Apple ID miễn phí**, vì Xcode sẽ báo lỗi ký app.

## Lỗi thường gặp

| Lỗi | Cách xử lý |
|---|---|
| `LatinOCRResources.bundle` not found | Chạy lại `bash ios/setup_ios.sh` (cần mạng) |
| `Failed to register bundle identifier` | Bundle ID đã có người dùng. Đổi trong Xcode (Signing & Capabilities) thành ID khác, và dùng đúng ID đó khi đăng ký Firebase |
| iPhone báo "Untrusted Developer" | Trên iPhone: Cài đặt → Cài đặt chung → Quản lý VPN & thiết bị → tin cậy Apple ID của bạn |
| App mở ra báo không kết nối được máy chủ | Kiểm tra bảng Backend ở trên |
| Quét hoá đơn không ra chữ | Kiểm tra `ios/Runner/mlkit/LatinOCRResources.bundle` đã tồn tại, rồi build lại |
