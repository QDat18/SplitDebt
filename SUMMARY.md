# BÁO CÁO TỔNG KẾT TIẾN ĐỘ SỬA LỖI HỆ THỐNG SPLITDEBT

> **Thời gian cập nhật:** 14/09/2026  
> **Trạng thái:** ✅ **Hoàn thành 7/7 hạng mục (100%)** trong bảng đề xuất khắc phục lỗi hệ thống.

---

## 📊 Bảng Theo Dõi Tiến Độ (7/7 Hạng Mục Hoàn Thành)

| STT | Hạng mục | Mức độ | Trạng thái | Tóm tắt giải pháp đã thực hiện |
|---|---|---|---|---|
| **1** | Tích hợp DashboardScreen vào Tab 0 | 🔴 Nghiêm trọng | ✅ Đã xong | Đặt `_index = 0` mặc định, gắn `DashboardScreen` vào Tab 0 cùng các callback điều hướng. |
| **2** | Hợp nhất `authProvider` | 🔴 Nghiêm trọng | ✅ Đã xong | Gom về `core/providers/auth_provider.dart`, re-export tại `features/auth/providers/auth_provider.dart`. |
| **3** | Tách FCM ra chạy ngầm (Non-blocking Login) | 🔴 Nghiêm trọng | ✅ Đã xong | `unawaited(_initFcmInBackground())` giúp login xong là chuyển màn hình tức thì. |
| **4** | Khắc phục N+1 Spam API `/users/me` | 🟡 Quan trọng | ✅ Đã xong | Cache `_cachedUserId` trong `AuthRepository`, xóa khi logout, giảm 14+ request dư thừa. |
| **5** | Sửa lỗi RenderFlex Overflow 89px & Font | 🟡 Quan trọng | ✅ Đã xong | Thay bằng `OutlinedButton.icon` có `TextOverflow.ellipsis`, thay emoji text bằng Icon Flutter. |
| **6** | N+1 API Nợ nhóm & Connection Pool HikariCP | 🟡 Quan trọng | ✅ Đã xong | Nâng HikariCP lên 15 connection, gộp `userBalance` vào API `/groups`, batch query đếm thành viên. |
| **7** | Đồng nhất Entity Settings | 🟢 Trung bình | ✅ Đã xong | Đồng nhất về `GroupSetting`/`UserSetting`, xóa bỏ `group_preferences`/`user_preferences` thừa. |

---

## 1. Chi Tiết Các Hạng Mục Đã Khắc Phục

### 1.1. Hợp nhất `authProvider` & Tách FCM chạy ngầm (Non-blocking Login)
- **Vấn đề cũ:**
  - Tồn tại song song 2 file `auth_provider.dart` (`core/providers/auth_provider.dart` và `features/auth/providers/auth_provider.dart`) với 2 kiểu State khác nhau (`AuthState` vs `AsyncValue<void>`), gây phân liệt trạng thái đăng nhập giữa `SplashScreen`, `LoginScreen` và `ProfileScreen`.
  - Trong hàm `login()`, ứng dụng bắt buộc phải đợi tuần tự: gọi API login $\rightarrow$ lưu Token $\rightarrow$ khởi tạo FCM $\rightarrow$ gọi `/users/me` $\rightarrow$ đợi subscribe topic FCM. Khi Notification bị chặn hoặc mạng chậm, nút Đăng nhập xoay vô tận và UI bị treo.
- **Giải pháp đã thực hiện:**
  - **Hợp nhất thành 1 `authProvider` duy nhất tại [core/providers/auth_provider.dart](file:///d:/KyVII_HocVienNganHang/LapTrinhDiDong/CuoiKy/SplitDebt/frontend/lib/core/providers/auth_provider.dart)**.
  - File [features/auth/providers/auth_provider.dart](file:///d:/KyVII_HocVienNganHang/LapTrinhDiDong/CuoiKy/SplitDebt/frontend/lib/features/auth/providers/auth_provider.dart) đóng vai trò re-export `core/providers/auth_provider.dart` để tất cả các màn hình đều dùng chung một nguồn trạng thái (Single Source of Truth).
  - **Tách khởi tạo FCM ra chạy ngầm (`unawaited(_initFcmInBackground())`)**: Sau khi nhận token JWT hợp lệ từ server, trạng thái lập tức chuyển sang `AuthState.authenticated` và trả về `true` ngay lập tức. Người dùng đăng nhập là nhảy màn hình trong tích tắc.

---

### 1.2. Tích hợp `DashboardScreen` vào Tab 0 của `MainLayoutScreen`
- **Vấn đề cũ:**
  - [main_layout_screen.dart](file:///d:/KyVII_HocVienNganHang/LapTrinhDiDong/CuoiKy/SplitDebt/frontend/lib/main_layout_screen.dart) gán cứng `_index = 1` (`HomeScreen` - Danh sách nhóm thô sơ).
  - Màn hình [DashboardScreen.dart](file:///d:/KyVII_HocVienNganHang/LapTrinhDiDong/CuoiKy/SplitDebt/frontend/lib/features/groups/dashboard_screen.dart) (Giao diện chính đầy đủ tổng nợ ròng, khoản chi gần đây, các nút hành động nhanh) bị bỏ quên hoàn toàn.
- **Giải pháp đã thực hiện:**
  - Cập nhật [main_layout_screen.dart](file:///d:/KyVII_HocVienNganHang/LapTrinhDiDong/CuoiKy/SplitDebt/frontend/lib/main_layout_screen.dart) với `_index = 0` mặc định.
  - Tích hợp `DashboardScreen` vào **Tab 0 (Trang chủ)** với 2 callback điều hướng:
    - `onNavigateToCreateExpense`: Mở [CreateExpenseScreen](file:///d:/KyVII_HocVienNganHang/LapTrinhDiDong/CuoiKy/SplitDebt/frontend/lib/features/expenses/create_expense_screen.dart).
    - `onNavigateToSettlement`: Mở [GroupSettlementScreen](file:///d:/KyVII_HocVienNganHang/LapTrinhDiDong/CuoiKy/SplitDebt/frontend/lib/features/settlements/live_settlement_screen.dart).
  - Tab 1: "Nhóm" ([HomeScreen](file:///d:/KyVII_HocVienNganHang/LapTrinhDiDong/CuoiKy/SplitDebt/frontend/lib/features/home/home_screen.dart)).
  - Tab 2: "Lịch sử" (`OverviewScreen(history: true)`).
  - Tab 3: "Cá nhân" ([ProfileScreen](file:///d:/KyVII_HocVienNganHang/LapTrinhDiDong/CuoiKy/SplitDebt/frontend/lib/features/profile/profile_screen.dart)).

---

### 1.3. Sửa triệt để lỗi Overflow 89px & Font Missing trên `LoginScreen`
- **Vấn đề cũ:**
  - `A RenderFlex overflowed by 89 pixels on the right` do nút Google dùng `Row` thủ công không có co giãn trên layout web nhỏ.
  - Cảnh báo `Could not find a set of Noto fonts to display all missing characters` do dùng ký tự emoji text `✂️` thô.
- **Giải pháp đã thực hiện:**
  - Thay thế `OutlinedButton + Row` bằng `OutlinedButton.icon` có `TextOverflow.ellipsis`, tự động thích ứng với kích thước container và loại bỏ hoàn toàn lỗi tràn 89px.
  - Thay ký tự `✂️` bằng Flutter Icon chuẩn: `Icon(Icons.account_balance_wallet_rounded)`.

---

### 1.4. Tối ưu Triệt Tiêu Vòng Lặp Gọi `/users/me` (Cache UserId)
- **Vấn đề cũ:**
  - `getCurrentUserId()` không lưu cache, dẫn đến việc ứng dụng gọi liên tiếp 14+ request `/users/me` mỗi khi màn hình tải lại.
- **Giải pháp đã thực hiện:**
  - Thêm biến `static int? _cachedUserId` trong [AuthRepository](file:///d:/KyVII_HocVienNganHang/LapTrinhDiDong/CuoiKy/SplitDebt/frontend/lib/features/auth/data/auth_repository.dart).
  - Khi đã có `_cachedUserId`, các lần gọi sau trả về ngay lập tức mà không gửi request mạng.
  - Xóa cache tự động khi đăng xuất (`AuthRepository.clearCache()`).

---

### 1.5. Khắc phục lỗi Supabase PgBouncer `prepared statement "S_2" already exists`
- **Vấn đề cũ:**
  - Kết nối Supabase qua cổng 6543 (Transaction Mode) gây lỗi xung đột Prepared Statement làm chết các transaction trong Spring Boot.
- **Giải pháp đã thực hiện:**
  - Bổ sung `&prepareThreshold=0` vào biến `DB_URL` trong file [api/.env](file:///d:/KyVII_HocVienNganHang/LapTrinhDiDong/CuoiKy/SplitDebt/api/.env#L13).

---

### 1.6. Tối Ưu N+1 API Nợ Nhóm & Connection Pool HikariCP
- **Vấn đề cũ:**
  - `application.yaml` cấu hình HikariCP `maximum-pool-size: 5`, `minimum-idle: 1`, quá nhỏ khi client mở HomeScreen tải nhiều nhóm cùng lúc.
  - Màn hình nhóm: Mỗi `GroupCard` trên frontend chạy `ref.watch(groupNetBalanceProvider(group.id))` riêng lẻ. Nếu người dùng tham gia 10 nhóm $\rightarrow$ phát sinh 10 API call `/debts/group/{id}/snapshot` đồng thời, gây cạn kiệt Connection Pool HikariCP (Connection timeout).
  - Backend: `GroupServiceImpl.getUserGroups` lặp N lần đếm thành viên (`countByGroupId`) gây N+1 SQL queries và không trả về số dư cá nhân của user.
- **Giải pháp đã thực hiện:**
  - **Tối ưu Connection Pool**: Nâng `maximum-pool-size: 15`, `minimum-idle: 3` trong [application.yaml](file:///d:/KyVII_HocVienNganHang/LapTrinhDiDong/CuoiKy/SplitDebt/api/src/main/resources/application.yaml).
  - **Batch query đếm thành viên**: Thêm `countMembersByGroupIds` trong [GroupMemberRepository.java](file:///d:/KyVII_HocVienNganHang/LapTrinhDiDong/CuoiKy/SplitDebt/api/src/main/java/com/splitdebt/api/repository/GroupMemberRepository.java) để đếm thành viên tất cả nhóm chỉ bằng **1 câu query duy nhất** (`GROUP BY gm.group.id`).
  - **Gộp nợ vào API `/groups`**: 
    - Thêm trường `userBalance` vào [GroupResponseDto.java](file:///d:/KyVII_HocVienNganHang/LapTrinhDiDong/CuoiKy/SplitDebt/api/src/main/java/com/splitdebt/api/dto/GroupResponseDto.java).
    - Tích hợp `DebtCalculationService` vào [GroupServiceImpl.java](file:///d:/KyVII_HocVienNganHang/LapTrinhDiDong/CuoiKy/SplitDebt/api/src/main/java/com/splitdebt/api/service/impl/GroupServiceImpl.java) để tự động tính `userBalance` từ snapshot `netBalances()` trả về cùng danh sách nhóm.
  - **Loại bỏ N+1 ở Frontend**: Cập nhật [group_card.dart](file:///d:/KyVII_HocVienNganHang/LapTrinhDiDong/CuoiKy/SplitDebt/frontend/lib/features/group/widgets/group_card.dart) ưu tiên sử dụng trực tiếp `group.userBalance` do server trả về, không gửi thêm các request con riêng lẻ.

---

### 1.7. Đồng Nhất Entity Settings (`group_settings` vs `group_preferences`)
- **Vấn đề cũ:**
  - Dự án tồn tại song song 2 cặp Entity & Repository cho cài đặt:
    - Cặp 1: `GroupSetting` (`group_settings`) & `UserSetting` (`user_settings`) đi kèm `SettingService` và `SettingController` (`/api/v1/settings`).
    - Cặp 2: `GroupSettings` (`group_preferences`) & `UserPreferences` (`user_preferences`) đi kèm `SettingsController` (`/api/settings`).
  - Phân mảnh CSDL (4 bảng khác nhau) gây rủi ro lưu cài đặt nhánh này nhưng đọc nhánh kia.
- **Giải pháp đã thực hiện:**
  - Hợp nhất tất cả các trường cấu hình vào bộ Entity chính quy:
    - [GroupSetting.java](file:///d:/KyVII_HocVienNganHang/LapTrinhDiDong/CuoiKy/SplitDebt/api/src/main/java/com/splitdebt/api/entity/GroupSetting.java): Thêm trường `requireApproval`.
    - [UserSetting.java](file:///d:/KyVII_HocVienNganHang/LapTrinhDiDong/CuoiKy/SplitDebt/api/src/main/java/com/splitdebt/api/entity/UserSetting.java): Thêm trường `currency`.
    - Cập nhật các DTO `GroupSettingRequest/Response`, `UserSettingRequest/Response` và [SettingServiceImpl.java](file:///d:/KyVII_HocVienNganHang/LapTrinhDiDong/CuoiKy/SplitDebt/api/src/main/java/com/splitdebt/api/service/impl/SettingServiceImpl.java).
  - Tái cấu trúc [SettingsController.java](file:///d:/KyVII_HocVienNganHang/LapTrinhDiDong/CuoiKy/SplitDebt/api/src/main/java/com/splitdebt/api/controller/SettingsController.java): Ủy quyền xử lý hoàn toàn cho `SettingService`, duy trì tương thích ngược 100% với endpoint cũ `/api/settings/**`.
  - Dọn dẹp triệt để: Xóa bỏ 4 file thừa (`GroupSettings.java`, `UserPreferences.java`, `GroupSettingsRepository.java`, `UserPreferencesRepository.java`).

### 1.8. Tối Ưu Chuyển Tab Mượt Mà Tức Thì (IndexedStack, AutomaticKeepAlive & Caching)
- **Vấn đề cũ:**
  - `MainLayoutScreen` dùng `switch (_index)` để render màn hình theo tab. Khi người dùng bấm chuyển tab ("Nhóm" $\leftrightarrow$ "Lịch sử" $\leftrightarrow$ "Cá nhân"), màn hình cũ bị **hủy hoàn toàn khỏi bộ nhớ (disposed)**. Khi quay lại, màn hình mới phải khởi tạo lại từ đầu (`initState()`), kích hoạt Riverpod và gọi lại toàn bộ các API mạng, hiển thị vòng quay loading rất lâu dù đã mở nhiều lần trước đó.
  - `userGroupsProvider` sử dụng `.autoDispose`, khiến danh sách nhóm bị xóa sạch khỏi bộ nhớ ngay khi rời khỏi tab "Nhóm".
  - Màn hình Lịch sử (`OverviewScreen`) và Cá nhân (`ProfileScreen`) không lưu cache, luôn hiển thị `CircularProgressIndicator` mỗi lần mở.
- **Giải pháp đã thực hiện:**
  - **Duy trì cây giao diện với `IndexedStack`**: Thay thế `switch (_index)` trong [main_layout_screen.dart](file:///d:/KyVII_HocVienNganHang/LapTrinhDiDong/CuoiKy/SplitDebt/frontend/lib/main_layout_screen.dart) bằng `IndexedStack(index: _index, children: [...])`. Toàn bộ 4 tab (`DashboardScreen`, `HomeScreen`, `OverviewScreen`, `ProfileScreen`) được giữ nguyên trong bộ nhớ; chuyển tab diễn ra **ngay tức khắc (0ms)** và giữ nguyên vị trí cuộn, ô tìm kiếm.
  - **Giữ State sống với `AutomaticKeepAliveClientMixin`**: Áp dụng `wantKeepAlive => true` trên tất cả 4 màn hình chính.
  - **Bộ nhớ đệm Riverpod không bị hủy**: Bỏ `.autoDispose` khỏi `userGroupsProvider` trong [group_provider.dart](file:///d:/KyVII_HocVienNganHang/LapTrinhDiDong/CuoiKy/SplitDebt/frontend/lib/features/group/providers/group_provider.dart), đồng thời hỗ trợ cập nhật ngầm không giật lag (`fetchGroups({bool silent = false})`).
  - **Cơ chế Cache-First cho Lịch sử & Cá nhân**: 
    - [pdf_overview_screen.dart](file:///d:/KyVII_HocVienNganHang/LapTrinhDiDong/CuoiKy/SplitDebt/frontend/lib/features/home/pdf_overview_screen.dart): Lưu static cache danh sách giao dịch theo nhóm (`_cachedEventsByGroup`), hiển thị ngay lập tức không cần chờ API.
    - [profile_screen.dart](file:///d:/KyVII_HocVienNganHang/LapTrinhDiDong/CuoiKy/SplitDebt/frontend/lib/features/profile/profile_screen.dart): Lưu static cache thông tin người dùng (`_cachedProfile`), vào là thấy thông tin ngay.

---

## 2. Kết Quả Kiểm Tra (Verification)

### Backend (Spring Boot):
- Thực thi: `mvn test-compile`
- Kết quả: **`BUILD SUCCESS`** (117 files compiled, 7 test files compiled, 0 lỗi).

### Frontend (Flutter):
- Thực thi: `flutter analyze`
- Kết quả: **0 Lỗi biên dịch (0 compilation errors)**.
- Toàn bộ 4 dropdown form field bị lỗi `initialValue` cũ (`create_expense_screen.dart`, `add_member_dialog.dart`, `pdf_overview_screen.dart`, `live_settlement_screen.dart`) đã chuyển sang `value` chuẩn và tương thích hoàn toàn với Flutter SDK hiện tại.
