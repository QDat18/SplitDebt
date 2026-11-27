# Hướng dẫn xuất và phát hành APK Android (SplitDebt)

## 1. Tạo khoá ký (làm một lần)

Chạy lệnh sau (đặt file `.jks` **ngoài thư mục repo**):

```powershell
keytool -genkey -v -keystore C:\Users\<TenCuaBan>\splitdebt-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias splitdebt
```

Sau đó sao chép `frontend/android/key.properties.example` thành `frontend/android/key.properties` và điền đúng 4 trường:

```properties
storeFile=C:/Users/<TenCuaBan>/splitdebt-release.jks
storePassword=<mat-khau-keystore>
keyAlias=splitdebt
keyPassword=<mat-khau-key>
```

> **Cảnh báo:** **Mất file `.jks` hoặc quên mật khẩu thì không bao giờ cập nhật đè lên được app đã cài.** Hãy sao lưu file `.jks` và mật khẩu vào nơi an toàn, tuyệt đối **không** để trong repo hay commit lên Git.

*(Lưu ý: Vì Application ID đã đổi thành `vn.hvnh.splitdebt`, chủ dự án cần thêm app Android `vn.hvnh.splitdebt` vào Firebase Console và cập nhật `FIREBASE_ANDROID_APP_ID` trong `frontend/.env` để push notification hoạt động.)*

## 2. Build APK release

Đứng ở thư mục `frontend` và truyền URL backend `https://`:

```powershell
.\tool\build_apk.ps1 -ApiBaseUrl https://<domain>/api
```

Script sẽ build cả bản universal (`app-release.apk`) và bản tách theo ABI (`--split-per-abi`), đồng thời in đường dẫn, dung lượng và mã SHA-256 của từng file.

## 3. Phát hành bản mới

1. Tăng `version` trong `frontend/pubspec.yaml` (tăng cả số build sau dấu `+`, ví dụ `1.0.0+1` → `1.0.1+2`).
2. Cập nhật `AppConstants.appVersion` trong `frontend/lib/core/constants/app_constants.dart` cho khớp phần trước dấu `+` (bộ test `app_version_test.dart` sẽ kiểm tra đồng bộ này).
3. Chạy lại `.\tool\build_apk.ps1 -ApiBaseUrl https://<domain>/api`. Bản mới sẽ cài đè lên bản cũ và giữ nguyên dữ liệu đăng nhập nếu dùng cùng file `.jks`.

## 4. Chia sẻ file APK

- Dùng file universal `frontend/build/app/outputs/flutter-apk/app-release.apk` để chia sẻ (cài được trên mọi máy Android).
- Tải lên Google Drive hoặc GitHub Releases kèm mã SHA-256 để người nhận kiểm tra toàn vẹn.

## 5. Hướng dẫn người cài

1. Mở link chia sẻ trên điện thoại Android và tải file `.apk`.
2. Khi được hỏi, bật quyền **Cài ứng dụng không rõ nguồn gốc** (Install unknown apps) cho trình duyệt hoặc ứng dụng quản lý tệp (Files).
3. Nếu Google Play Protect hiện cảnh báo do app chưa lên Play Store, chọn **Vẫn cài đặt** (Install anyway).

## 6. Kiểm tra sau khi cài

- [ ] Đăng ký tài khoản mới
- [ ] Đăng nhập
- [ ] Tạo nhóm mới
- [ ] Thêm khoản chi
- [ ] Quét hoá đơn (chụp bằng camera và chọn từ thư viện)
- [ ] Nhắn tin trong chat nhóm
- [ ] Nhận thông báo (push notification)
- [ ] Xoá tài khoản
