# Implemented UI/UX — SplitDebt

Bản UI/UX này giữ nguyên nghiệp vụ SplitDebt nhưng nâng cấp toàn bộ trải nghiệm theo hướng premium, trực quan và thân thiện với người mới.

| Khu vực | Source chính | Nâng cấp UI/UX |
|---|---|---|
| Theme | `frontend/lib/core/theme/app_theme.dart` | Light/Dark/System, typography, form, button, card, navigation và transition thống nhất |
| Premium primitives | `frontend/lib/core/widgets/premium_ui.dart` | Animated background, glass surface, brand mark, entrance/motion primitives |
| Shared UI | `frontend/lib/widgets/design.dart` | 3D Surface/Hero, CTA interaction, feedback 4 trạng thái, success dialog, status pill, tutorial card |
| Onboarding | `frontend/lib/main.dart` | 4 trang giới thiệu lợi ích, glass card, progress và CTA rõ ràng |
| Đăng nhập | `features/auth/login_screen.dart` | Premium background + glass form, lỗi thân thiện |
| Đăng ký | `features/auth/register_screen.dart` | Premium form + dialog thành công và hướng về đăng nhập |
| First-login guide | `features/help/quick_guide_screen.dart` | Tutorial 4 bước, mini prototype, connector/mũi tên và tips |
| Trang chủ | `features/home/home_screen.dart` | Help button, prompt hướng dẫn lần đầu, tutorial card, feedback khi tạo/tham gia nhóm |
| Nhóm & công nợ | `features/home/group_screen.dart` | Premium surfaces, success/info/error feedback, settlement trạng thái rõ ràng |
| Forms | `features/home/forms.dart` | Step pills, giải thích từng kiểu chia, hướng dẫn inline, validation rõ ràng |
| Notifications | `features/home/home_screen.dart` | Card thông báo, trạng thái mới/đã đọc, icon theo loại sự kiện |
| API feedback | `frontend/lib/data/api.dart` | Thông báo timeout/kết nối/session bằng tiếng Việt dễ hiểu |

## Các luồng đã có feedback trực quan

- Đăng ký thành công / đăng nhập thất bại.
- Tạo nhóm / tham gia nhóm / sao chép mã mời.
- Thêm thành viên / xóa thành viên.
- Thêm hoặc sửa khoản chi.
- Sai tổng số tiền, sai 100%, trọng số không hợp lệ, item thiếu người tham gia.
- Ghi nhận thanh toán / xác nhận thanh toán / hủy settlement.
- Cập nhật group settings.
- Timeout, backend không truy cập được và phiên đăng nhập hết hạn.

## Luồng hướng dẫn người mới

```text
Đăng nhập lần đầu
      ↓
Prompt “Hướng dẫn nhanh”
      ↓
Trang chủ → Lập nhóm → Thêm khoản chi → Smart Settlement
      ↓
Hoàn tất / có thể mở lại bằng nút ?
```

Phần mini prototype trong tutorial được dựng bằng widget Flutter nên không phụ thuộc ảnh raster hay tài nguyên online.
