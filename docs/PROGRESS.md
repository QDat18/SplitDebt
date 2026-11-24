# SplitDebt Progress Tracking

- **Status**: Hoàn thành tái thiết kế phân hệ Nhóm (Groups) theo Apple HIG / iOS Design.
- **Done**:
  - Avatar Upload Backend (`177fbbc`) & Frontend (`bd34e02`): Đổi avatar qua Supabase Storage.
  - Groups Redesign Apple HIG:
    - `GroupCard`: Inset Grouped card, squircle icon tím, typography cân đối, chevron navigation, loại bỏ viền thô và popup menu rườm rà.
    - `GroupsScreen`: Nền `AppColors.n100`, bỏ `FloatingActionButton`, nút `+` & Search trên iOS AppBar, search bar bo tròn mượt mà.
    - `CreateGroupDialog`: iOS Form modal sheet với nút Huỷ/Tạo trên navigation bar, nhóm input phẳng.
    - `GroupDetailScreen`: Hero card tài chính thanh lịch, `CupertinoSlidingSegmentedControl` cho 3 tab, danh sách chi tiêu và thành viên phẳng gọn.
- **Verification**:
  - `flutter analyze` 0 errors.
  - `flutter test` 38/38 tests passed.
- **In progress**: Đánh giá & thiết kế lại màn hình Lịch sử (History) và Trang chủ (Home/Dashboard) theo chuẩn Apple HIG.
- **Next**: Redesign `history_screen.dart` (segmented control, iOS card list) & `dashboard_screen.dart`.
- **Blockers**: Không có.
