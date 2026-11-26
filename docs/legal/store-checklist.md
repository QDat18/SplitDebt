Phiên bản: 2026-11-26
Hiệu lực từ: [CẦN ĐIỀN]

# Checklist khai báo quyền riêng tư cho Google Play và App Store

## 1. Tài liệu công khai cần đưa lên web trước khi nộp store

- [ ] Đưa `docs/legal/privacy-policy.md` lên trang tĩnh công khai (GitHub Pages, Vercel...) và điền URL: `[CẦN ĐIỀN: URL Chính sách quyền riêng tư]`
- [ ] Đưa `docs/legal/terms.md` lên trang tĩnh công khai và điền URL: `[CẦN ĐIỀN: URL Điều khoản sử dụng]`
- [ ] Đưa `docs/legal/account-deletion.md` lên trang tĩnh công khai và điền URL: `[CẦN ĐIỀN: URL trang hướng dẫn xoá tài khoản]`

## 2. Google Play (Data safety & Account deletion)

- [ ] Điền **Privacy policy URL**: `[CẦN ĐIỀN]`
- [ ] Điền **Delete account URL** (bắt buộc cho app có tạo tài khoản): `[CẦN ĐIỀN]`
- [ ] Xác nhận app hỗ trợ xoá tài khoản ngay trong app (`Cá nhân > Quyền riêng tư > Xoá tài khoản`).
- [ ] Khai báo **Data safety**:
  - Personal info: Name, Email address, Phone number (nếu nhập).
  - Photos and videos: Ảnh đại diện (tải lên Supabase; ảnh hoá đơn chỉ xử lý trên thiết bị, không thu thập về server).
  - Messages: Tin nhắn nhóm.
  - Financial info / App activity: Khoản chi, công nợ nhóm (dữ liệu do người dùng nhập).
  - Device or other IDs: Firebase push token (dùng cho App functionality / Notifications).
  - Chia sẻ với bên thứ ba: Firebase (Google) cho thông báo đẩy; Supabase cho lưu trữ ảnh đại diện; hosting backend/database.
  - Bảo mật: Dữ liệu được mã hoá khi truyền (HTTPS); người dùng có thể yêu cầu xoá dữ liệu.

## 3. Apple App Store (App Privacy & Info.plist)

- [ ] Điền **Privacy Policy URL** trong App Store Connect: `[CẦN ĐIỀN]`
- [ ] Khai báo **App Privacy Label** (khớp danh sách dữ liệu ở mục 2, gắn mục đích *App Functionality*, không gắn *Tracking*).
- [ ] Đảm bảo tính năng xoá tài khoản ngay trong app hoạt động đầy đủ (bắt buộc theo hướng dẫn xét duyệt của Apple).
- [ ] Kiểm tra `Info.plist` có đủ mô tả mục đích quyền:
  - `NSCameraUsageDescription`: `"SplitDebt dùng camera để chụp hoá đơn và ảnh đại diện."`
  - `NSPhotoLibraryUsageDescription`: `"SplitDebt cần truy cập thư viện để bạn chọn ảnh hoá đơn hoặc ảnh đại diện."`
