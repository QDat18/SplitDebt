# SplitDebt UI/UX Design System — Premium Interactive

Phiên bản giao diện hiện tại sử dụng Flutter Material 3, hỗ trợ Light / Dark / System và ưu tiên trải nghiệm rõ ràng cho người dùng mới. Phong cách chính là **premium fintech**, nền sáng dịu, gradient tím, glass surface, chiều sâu 3D vừa phải và phản hồi tương tác ngắn để không gây rối mắt.

## 1. Design tokens

| Token | Giá trị | Mục đích |
|---|---|---|
| Primary | `#7157F5` | CTA, trạng thái được chọn, điểm nhấn |
| Primary Alt | `#9A6BFF` | Gradient, glow |
| Accent Blue | `#55A7FF` | Thông tin, secondary accent |
| Champagne | `#D8B46D` | Điểm nhấn phụ |
| Primary Tint | `#EDE9FF` | Chip, avatar, selected state |
| Light Background | `#F6F7FC` | Nền ứng dụng |
| Dark Background | `#0E1220` | Nền dark mode |
| Primary Text | `#201F36` | Tiêu đề/nội dung chính |
| Secondary Text | `#6F6A86` | Nội dung phụ |
| Success | `#13856E` | Thanh toán/lưu thành công |
| Error | `#D15067` | Lỗi/thất bại |
| Warning | `#E7A63A` | Cảnh báo dữ liệu cần kiểm tra |
| Info | `#4279E8` | Hướng dẫn/thông tin |
| Card radius | 24 px | Card/Surface |
| Dialog radius | 28 px | Dialog/bottom sheet |
| Input/Button radius | 18–19 px | Form control |
| Page inset | 22–24 px | Khoảng cách lề chính |

Typography dùng system sans-serif để không phụ thuộc font tải ngoài. Heading chính dùng weight 800–900; body ưu tiên line-height 1.5 để dễ đọc trên mobile.

## 2. Thành phần UI dùng chung

- `PremiumBackground`: nền nhiều lớp có glow chuyển động chậm, tạo chiều sâu nhưng không cạnh tranh với nội dung.
- `GlassSurface`: glassmorphism nhẹ, blur + border + shadow.
- `Surface`: card có hover/lift 3D nhẹ trên web/desktop; vẫn hoạt động bình thường trên mobile.
- `HeroCard`: card gradient tím có highlight và khối cầu ánh sáng.
- `Orb`: icon tile gradient có entrance animation.
- `BrandButton`: CTA có hover/press scale, lift và shadow.
- `FeedbackBanner`: thông báo nổi 4 trạng thái `success/error/warning/info`.
- `StatusPill`: chip trạng thái dùng trong onboarding, tutorial và notifications.
- `TutorialPromoCard`: điểm vào cố định cho phần hướng dẫn nhanh.

Tất cả animation chính kiểm tra `MediaQuery.disableAnimationsOf(context)` ở những thành phần tương tác quan trọng để giảm motion khi người dùng yêu cầu.

## 3. Feedback & thông báo

Hệ thống feedback không dùng Snackbar văn bản đơn thuần. Mỗi trạng thái có icon, màu, tiêu đề, nội dung và shadow riêng:

| Trạng thái | Ví dụ |
|---|---|
| Success | Tạo tài khoản, tạo nhóm, tham gia nhóm, lưu khoản chi, xác nhận thanh toán |
| Error | Timeout, backend không kết nối, dữ liệu chia không hợp lệ, lỗi API |
| Warning | Dữ liệu cần kiểm tra / hành động có rủi ro |
| Info | Hủy settlement, hướng dẫn thao tác, thông tin hệ thống |

Đăng ký thành công sử dụng dialog riêng để người mới hiểu rõ bước tiếp theo thay vì chỉ hiện một toast ngắn.

## 4. First-login guide

Người dùng mới sau khi đăng nhập lần đầu sẽ thấy bottom sheet giới thiệu **Hướng dẫn nhanh**. Người dùng luôn có thể mở lại từ:

- Nút `?` trên trang chính.
- `TutorialPromoCard` trên tab Tổng quan.

Tutorial có 4 bước:

1. Trang chủ — đọc tổng quan số dư và nhóm.
2. Lập nhóm — tạo nhóm, chia sẻ mã mời, thêm thành viên.
3. Thêm khoản chi — nhập tổng tiền, người tham gia, kiểu chia, kiểm tra trước khi lưu.
4. Smart Settlement — hiểu người trả/người nhận và xác nhận thanh toán hai phía.

Mỗi bước chứa mini prototype dựng trực tiếp bằng Flutter và sơ đồ bước có connector dạng vector/icon.

## 5. Interaction guidelines

- Hover/lift chỉ 1–3 px, rotate 3D cực nhỏ để giữ cảm giác premium.
- Press scale khoảng 0.975–0.985 để tạo phản hồi xúc giác thị giác.
- Không dùng animation liên tục cho nội dung nghiệp vụ quan trọng.
- CTA chính luôn có nhãn rõ; icon chỉ đóng vai trò hỗ trợ.
- Empty/error/loading state phải giải thích người dùng nên làm gì tiếp theo.
- Thanh toán trong UI chỉ là ghi nhận giao dịch bên ngoài hệ thống, không mô phỏng việc tự động chuyển tiền.
