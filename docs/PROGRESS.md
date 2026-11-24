# SplitDebt Progress Tracking

- **Status**: Hoàn thành tái thiết kế toàn diện theo chuẩn Apple HIG (Nhóm, Lịch sử, Trang chủ).
- **Done**:
  - Avatar Upload Backend (`177fbbc`) & Frontend (`bd34e02`): Đổi avatar qua Supabase Storage.
  - Groups Redesign Apple HIG (`73faa66`):
    - `GroupCard`, `GroupsScreen`, `CreateGroupDialog`, `GroupDetailScreen`.
  - History Screen Redesign Apple HIG:
    - Nền `AppColors.n100`, iOS AppBar, `CupertinoSlidingSegmentedControl` thay thế `PdfTabs`.
    - Group selector thẻ phẳng bo góc 12px, danh sách giao dịch Inset Grouped với squircle icons và format số dư rõ ràng.
    - Chế độ Thống kê: Thẻ tổng chi tiêu nổi bật, thanh tiến độ danh mục bo tròn, bảng xếp hạng thành viên với huy hiệu hạng (#1, #2, ...).
  - Home Dashboard Redesign Apple HIG:
    - Hero Financial Card phong cách Apple Card (tổng số dư ròng, badge trạng thái, số tiền lớn 32px w800).
    - Quick actions Inset Grouped (Tạo chi tiêu, Quyết toán), thẻ nhóm phẳng iOS Inset Grouped đồng bộ.
- **Verification**:
  - `flutter analyze` 0 errors.
  - `flutter test` 40/40 tests passed (bao gồm `history_screen_test.dart`).
- **In progress**: Hoàn tất các hạng mục theo yêu cầu.
- **Next**: Kiểm tra trải nghiệm thực tế trên máy ảo / thiết bị hoặc tiếp tục tính năng OCR.
- **Blockers**: Không có.
