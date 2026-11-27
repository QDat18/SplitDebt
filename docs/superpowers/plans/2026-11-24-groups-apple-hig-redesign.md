# Kế hoạch Triển khai: Thiết kế lại Phân hệ Nhóm (Groups) theo chuẩn Apple HIG

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Chuyển đổi toàn bộ phân hệ Nhóm (Danh sách nhóm, Thẻ nhóm, Màn hình tạo nhóm, Chi tiết nhóm) sang ngôn ngữ thiết kế Apple Human Interface Guidelines (iOS Design), loại bỏ các thành phần Material thô kệch (như FAB), chống tràn màn hình, đảm bảo tính thẩm mỹ thanh lịch và nhất quán với phân hệ Cá nhân/Cài đặt.

**Architecture & Design Rules:**
- **Nền & Khối:** Nền trang dùng `AppColors.n100` (iOS grouped background `#F2F2F7`). Thẻ/danh sách dùng `AppColors.n0` (trắng phẳng), bo góc `12-14px`, **không viền thô, không shadow nặng**.
- **Màu nhấn:** Tím thương hiệu `AppColors.p500`. Trạng thái: Xanh `AppColors.success` (+ nhận tiền), Đỏ `AppColors.error` (- nợ), Xám `AppColors.n500` (cân bằng).
- **Navigation:** Nút tạo mới (`+`) đặt ở AppBar góc trên bên phải theo chuẩn iOS. Loại bỏ hoàn toàn `FloatingActionButton`.
- **Thành phần iOS:** Sử dụng `CupertinoSlidingSegmentedControl` cho tab, search bar phong cách iOS, icon chevron `Icons.chevron_right` cho các hàng điều hướng.

---

## Danh sách Task

### Task 1: Thiết kế lại `GroupCard` (iOS Inset Grouped Style)
- [ ] File: `frontend/lib/features/groups/widgets/group_card.dart`
  - Thay thế card viền 1.5 và shadow đen bằng thẻ phẳng nền trắng bo góc 14px, đổ bóng siêu nhẹ `AppDimensions.shadowSm`.
  - Icon nhóm: Avatar vuông bo góc tròn mềm mại (`ContinuousRectangleBorder` hoặc bo 12px) màu tím nhạt `AppColors.p50`, icon nhóm `Icons.group_rounded` màu tím `AppColors.p500` (bỏ emoji ngẫu nhiên).
  - Typography: Tên nhóm `16px, FontWeight.w600, color: AppColors.n800`; phụ đề `13px, color: AppColors.n500`.
  - Hiển thị số dư: Badge hoặc text rõ ràng (xanh `success`, đỏ `error`, xám `n500`).
  - Mũi tên điều hướng `Icons.chevron_right` màu `AppColors.n400`. Bỏ popup menu 3 chấm thừa.

### Task 2: Làm mới `GroupsScreen` (Chuẩn iOS NavigationBar & Search)
- [ ] File: `frontend/lib/features/groups/screens/groups_screen.dart`
  - Đổi nền sang `AppColors.n100`.
  - AppBar chuẩn iOS: Tiêu đề "Nhóm", nút hành động góc phải gồm icon Tìm kiếm (`Icons.search_rounded`) và nút Tạo nhóm mới (`Icons.add_rounded`).
  - Xoá bỏ hoàn toàn `FloatingActionButton.extended`.
  - Khi tìm kiếm: hiển thị thanh tìm kiếm bo tròn phong cách iOS mượt mà dưới tiêu đề.
  - Sử dụng ListView danh sách nhóm sạch sẽ với khoảng cách giữa các card là 10px.

### Task 3: Làm mới `CreateGroupDialog` (iOS Modal Form)
- [ ] File: `frontend/lib/features/groups/screens/create_group_dialog.dart`
  - AppBar: Nút "Huỷ" (`AppColors.n600`) ở góc trái và nút "Tạo" (chữ đậm màu tím `AppColors.p500`) ở góc phải.
  - Form nhóm chuẩn iOS Inset Grouped: Khối thẻ trắng phẳng chứa ô nhập *Tên nhóm* và *Mô tả*, có đường kẻ mảnh phân cách.
  - Khối thông tin thành viên hiển thị người tạo là Trưởng nhóm trang nhã, không dùng emoji cồng kềnh.

### Task 4: Làm mới `GroupDetailScreen` (iOS Hero Card & Segmented Control)
- [ ] File: `frontend/lib/features/groups/screens/group_detail_screen.dart`
  - Thẻ tóm tắt tài chính: Chuyển từ khối tím đen `p900` chữ in HOA sang thẻ tài chính thanh lịch: Nền trắng phẳng bo góc 16px, chữ "Tổng chi tiêu nhóm" viết thường cỡ 13 `n600`, số tiền lớn `w700`, phân tách 2 cột "Bạn đang nợ" và "Bạn được nhận".
  - Nút hành động chính: 2 nút bo tròn 12px ("Thêm chi tiêu" màu tím `p500` và "Thanh toán").
  - Tab chuyển đổi: Dùng `CupertinoSlidingSegmentedControl` cho 3 mục `Chi tiêu`, `Thành viên`, `Số dư nợ`.
  - Danh sách chi tiêu / thành viên: Bọc trong thẻ danh sách phẳng iOS với icon danh mục và số tiền rõ ràng.

### Task 5: Kiểm thử toàn diện & Cập nhật Tiến độ
- [ ] Chạy kiểm thử: `flutter test` và `flutter analyze --no-fatal-infos`.
- [ ] Cập nhật `docs/PROGRESS.md` (giữ <= 30 dòng).

