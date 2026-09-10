# SplitDebt - bản đã đồng bộ database/SRS

Các thay đổi chính trong bản bàn giao:

- Chuyển xác thực từ Supabase Auth cũ sang backend Spring Boot dùng bảng `users`, password hash PBKDF2 và JWT.
- Đồng bộ nhóm/thành viên với `groups` và `group_members`, hỗ trợ OWNER/MEMBER, mã mời, thêm/xóa thành viên.
- Đồng bộ khoản chi với `expenses`, `expense_participants`, `expense_items`, `item_participants`, `expense_shares`.
- Hỗ trợ EQUAL, AMOUNT, PERCENT, WEIGHT, ITEM và kiểm tra tổng phần chia phải khớp tổng khoản chi.
- Tính công nợ từ ledger và đồng bộ bảng `debts`; Smart Settlement dựa trên net balance.
- Settlement theo luồng hai phía: người trả ghi nhận `PAID`, người nhận xác nhận `CONFIRMED`; hỗ trợ hủy khi còn chờ.
- Bổ sung notifications, statistics, activity/history, user settings và group settings.
- Flutter gọi REST API/JWT, có onboarding, nhóm, khoản chi, công nợ, settlement, thành viên, thống kê, thông báo và hồ sơ/cài đặt.
- API URL Flutter chuyển sang `--dart-define` để source ZIP không phụ thuộc `.env` riêng tư.
- Bổ sung script kiểm tra thuật toán và SQL nhẹ, cùng script đóng gói source đã loại build/cache/secret.

Xem thêm `docs/SETUP.md`, `docs/API.md`, `docs/VALIDATION.md`.
