# Làm lại giao diện các màn Cài đặt (Cá nhân, Thông báo, Cài đặt nhóm)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ba màn cài đặt dùng chung một kiểu danh sách nhóm theo Apple HIG, bỏ các mục giả hoặc gắn nhãn sai, và chỉ dùng token từ `AppColors`/`AppDimensions`.

**Architecture:** Thêm bộ widget dùng chung `lib/core/widgets/grouped_list.dart` (section + tile + switch tile). Ba màn được viết lại bằng bộ widget này. Không đổi logic hay API: `UserPreferencesNotifier`, `userGroupsProvider`, `authProvider` giữ nguyên.

**Tech Stack:** Flutter, flutter_riverpod 2.5, flutter_test.

**Spec:** Hướng thiết kế cố định của chủ dự án (skill `apple-design`, chế độ App UI) và review giao diện ngày 2026-11-24 (mục "Bối cảnh").

## Bối cảnh (review đã xác nhận)

**`profile_screen.dart` (tab Cá nhân)**
- Hàng "Bảo mật" mở màn chỉ có 2 công tắc thông báo, tức là gắn nhãn sai.
- Hàng "Thông báo" mở hộp thư thông báo chứ không phải cài đặt thông báo. Hộp thư đã có lối vào từ chuông ở Trang chủ.
- "Tiền tệ" và "Ngôn ngữ" là bottom sheet chỉ chứa một câu chữ, trông như cài đặt nhưng không chỉnh được gì.
- `TextStyle` viết tay (`fontSize: 14/20/22`), lẫn `AppTheme.primaryColor` với `Colors.grey`.
- Nút Đăng xuất bị lặp ở cả màn này lẫn màn cài đặt.

**`settings_screen.dart`**
- Tiêu đề section viết HOA, màu tím, có letterSpacing.
- Card bo 20 kèm bóng đổ.
- Mỗi icon một màu (cam, xanh lá).
- Hiệu ứng fade 500ms chỉ để trang trí.
- Tiêu đề "Cài đặt & Cấu hình" không khớp nội dung.
- Có thêm một nút Đăng xuất thứ hai.

**`group_settings_screen.dart`**
- SnackBar dùng emoji (✅, 🗑️) và màu thô `Colors.green/red/orange`.
- Thành viên thường vẫn thấy tiêu đề "Vùng nguy hiểm" nhưng bên dưới trống.
- `TextFormField` có viền kèm icon ở đầu, không theo kiểu form nhóm.

## Quyết định thiết kế

**Chung**
- Chế độ App UI theo HIG. **Một màu nhấn duy nhất là `AppColors.p500`** (tím thương hiệu sẵn có, thay cho xanh `#007AFF`). Đỏ (`AppColors.error`) chỉ dùng cho hành động phá huỷ. Xanh lá (`AppColors.success`) chỉ dùng cho công tắc đang bật, theo HIG.
- **Nền trang `AppColors.n100`, khối danh sách `AppColors.n0`.** Bo góc `AppDimensions.r12`, **không bóng đổ, không viền**. Lề ngang 16. Khoảng cách giữa các section là 32.
- **Tiêu đề section:** viết thường kiểu câu, cỡ 13, màu `n600`, lùi vào 16 so với mép khối. **Chú thích dưới section:** cỡ 13, `n600`.

**Hàng (tile)**
- Cao tối thiểu 52.
- Icon trong ô vuông 28×28 bo 8, nền `p500`, icon trắng cỡ 18. Mọi icon dùng cùng một màu.
- Tiêu đề cỡ 16 (`w400`), phụ đề cỡ 13 `n600`.
- Bên phải: giá trị (cỡ 16 `n600`), mũi tên (`Icons.chevron_right`, cỡ 20, `n400`) khi bấm được, hoặc công tắc.
- Đường kẻ mảnh (0.5, `n200`) lùi vào tới mép chữ, không chạy hết chiều ngang.

**Công tắc:** `Switch.adaptive` với `activeTrackColor: AppColors.success`. Khi đang lưu, công tắc bị khoá (`onChanged: null`).

**Hàng phá huỷ** (Đăng xuất, Xoá nhóm): một hàng riêng, chữ đỏ căn giữa, không icon. Luôn hỏi xác nhận bằng `showAdaptiveDialog`: nút Huỷ, và nút hành động màu đỏ có `isDestructiveAction: true`.

**Bỏ:** hiệu ứng fade khi mở màn, emoji, chữ viết HOA, màu viết thẳng trong code.

**Cấu trúc tab Cá nhân:**
```
        (Avatar 64)
        Hoàng Đạt
        dat@…                         ← cỡ 22 w700 / 15 n600, căn giữa

Tài khoản
 [👤] Thông tin cá nhân        ›     → bottom sheet chỉ xem: Họ tên, Email
Ứng dụng
 [🔔] Thông báo                ›     → NotificationSettingsScreen
 [₫ ] Tiền tệ               VND     (không bấm được)
 [🌐] Ngôn ngữ        Tiếng Việt     (không bấm được)
Hỗ trợ
 [?] Trợ giúp                  ›     → bottom sheet (giữ nội dung cũ)
 [i] Giới thiệu                ›     → bottom sheet (giữ nội dung cũ)

          Đăng xuất                  ← hàng đỏ căn giữa, có hỏi xác nhận
```
- Bỏ hàng "Bảo mật".
- Hộp thư thông báo không còn lối vào từ màn này; vẫn mở được từ chuông ở Trang chủ.

**Màn Thông báo:** đổi tên file thành `notification_settings_screen.dart`, class thành `NotificationSettingsScreen`, tiêu đề "Thông báo". Gồm:
- Một section "Nhận thông báo khi" với 2 switch tile (giữ nguyên tiêu đề và phụ đề hiện có).
- Chú thích dưới section: "Thông báo trong ứng dụng vẫn được lưu kể cả khi tắt."
- Bỏ nút Đăng xuất.
- Trạng thái đang tải và lỗi nằm bên trong khối section.

**Cài đặt nhóm:**
- Section "Thông tin nhóm" có 2 hàng nhập liệu: nhãn bên trái ("Tên", "Mô tả"), ô nhập không viền bên phải, `Mô tả` cho phép nhiều dòng.
- Thành viên thường thấy chữ thường thay cho ô nhập, kèm chú thích "Chỉ trưởng nhóm hoặc quản trị viên mới sửa được."
- Nút "Lưu" trên AppBar chỉ hiện với admin và chỉ bật khi tên hoặc mô tả đã đổi.
- Hàng "Xoá nhóm" chỉ hiện với admin.
- SnackBar dạng chữ thường: "Đã lưu thay đổi.", "Đã xoá nhóm.", "Không lưu được: <lỗi>". Không emoji, không màu nền tự đặt.

## Global Constraints

- Không đổi logic nghiệp vụ, provider, API. Không thêm dependency.
- Chuỗi tiếng Việt có dấu, viết hoa kiểu câu. Không dấu chấm than, không emoji.
- Màu, khoảng cách và bo góc chỉ lấy từ `AppColors`/`AppDimensions`. Không có `Color(0x…)`, `Colors.*` (trừ `Colors.white` cho icon trên nền màu và `Colors.transparent`) hay `fontSize:` viết tay **trong các file mới hoặc file được viết lại**.
- Widget dùng chung lấy chữ từ `Theme.of(context).textTheme` (rồi `copyWith` cỡ và màu), **không** gọi `AppTypography`/`GoogleFonts`. Nhờ vậy widget test chạy được mà không tải font qua mạng.
- Mọi vùng bấm cao ≥ 44.
- Không đọc hay sửa `.env`. Không push. Mỗi task một commit. Cập nhật `docs/PROGRESS.md` sau mỗi task.
- Kiểm tra: `cd frontend; flutter analyze` (0 error) và `flutter test` (PASS).
- Plan mơ hồ hoặc không khớp với code: dừng lại và hỏi.

## Review Focus

1. **Tên hoặc email rất dài** (hơn 40 ký tự): phần đầu trang và hàng giá trị phải cắt bằng dấu "…", không tràn ra ngoài (test ở Task 1 và kiểm tra bằng mắt ở Task 2).
2. **Cỡ chữ hệ thống lớn** (textScaler 1.3): hàng tự cao lên, chữ không bị cắt mất (test ở Task 1).
3. **Bấm công tắc rồi thoát màn ngay:** không crash. Logic này đã có trong notifier; chỉ cần đảm bảo màn mới không gọi `setState` sau khi đã unmount (Task 3).
4. **Thành viên thường mở Cài đặt nhóm:** không thấy ô nhập, nút Lưu hay hàng Xoá (kiểm tra bằng mắt ở Task 4).
5. **Bấm Huỷ ở hộp xác nhận Đăng xuất hoặc Xoá nhóm:** không có gì xảy ra (Task 2, Task 4).

---

### Task 1: Bộ widget danh sách nhóm dùng chung

**Files:**
- Create: `frontend/lib/core/widgets/grouped_list.dart`
- Test: `frontend/test/grouped_list_test.dart`

**Interfaces (Produces):**
```dart
class GroupedSection extends StatelessWidget {
  const GroupedSection({super.key, this.header, this.footer, required this.children});
  final String? header;            // hiển thị nguyên văn, không tự viết hoa
  final String? footer;
  final List<Widget> children;     // tự chèn đường kẻ mảnh giữa các phần tử, lùi vào 60 (16 + 28 + 16) nếu phần tử là GroupedTile có icon, lùi 16 nếu không
}

class GroupedTile extends StatelessWidget {
  const GroupedTile({super.key, required this.title, this.subtitle, this.icon,
      this.value, this.onTap, this.trailing, this.destructive = false});
  final String title; final String? subtitle; final IconData? icon;
  final String? value;             // chữ n600 bên phải, cắt "…" khi dài
  final VoidCallback? onTap;       // có onTap và không có trailing/destructive → hiện chevron
  final Widget? trailing;          // ghi đè chevron/value
  final bool destructive;          // chữ AppColors.error, căn giữa, bỏ icon
}

class GroupedSwitchTile extends StatelessWidget {
  const GroupedSwitchTile({super.key, required this.title, this.subtitle, this.icon,
      required this.value, required this.onChanged});
  final String title; final String? subtitle; final IconData? icon;
  final bool value; final ValueChanged<bool>? onChanged;   // null = khoá
}
```

- [ ] **Step 1: Viết test thất bại.** Mỗi test bọc widget trong `MaterialApp(home: Scaffold(body: ...))`.
```dart
testWidgets('section shows header text as given and separators between rows')
  // GroupedSection(header: 'Tài khoản', children: [GroupedTile(title:'A'), GroupedTile(title:'B'), GroupedTile(title:'C')])
  // expect(find.text('Tài khoản'), findsOneWidget); expect(find.text('TÀI KHOẢN'), findsNothing)
  // expect(find.byKey(const ValueKey('grouped-separator')), findsNWidgets(2))
testWidgets('tappable tile shows chevron and is at least 52 high')
  // GroupedTile(title:'Thông báo', onTap: (){}) → find.byIcon(Icons.chevron_right) findsOneWidget;
  // tester.getSize(find.byType(GroupedTile)).height >= 52; tap → callback gọi 1 lần
testWidgets('value tile without onTap shows value and no chevron')
  // GroupedTile(title:'Tiền tệ', value:'VND') → find.text('VND') findsOneWidget; chevron findsNothing
testWidgets('destructive tile is centered red text without icon')
  // GroupedTile(title:'Đăng xuất', icon: Icons.logout, destructive: true, onTap: (){})
  // Text widget color == AppColors.error; find.byIcon(Icons.logout) findsNothing; chevron findsNothing
testWidgets('switch tile toggles and can be locked')
  // value:false, onChanged ghi lại → tap Switch → nhận true; onChanged:null → tap không gọi gì
testWidgets('long value is ellipsized and large text scale does not overflow')
  // MediaQuery(textScaler: TextScaler.linear(1.3)); GroupedTile(title:'Email', value: 'a'*80)
  // tester.takeException() == null
```
Đường kẻ mảnh phải mang `key: const ValueKey('grouped-separator')`.

- [ ] **Step 2: Chạy test, xác nhận thất bại.** `cd frontend; flutter test test/grouped_list_test.dart`. Kỳ vọng FAIL vì chưa có file.
- [ ] **Step 3: Viết `grouped_list.dart`** theo Interfaces và mục "Quyết định thiết kế". Section là `Padding(h:16)`, bên trong là `Column` [header, `ClipRRect(r12)` + `ColoredBox(n0)` chứa các hàng, footer]. Hàng dùng `InkWell` + `ConstrainedBox(minHeight: 52)`, không dùng `ListTile`, để kiểm soát padding và đường kẻ.
- [ ] **Step 4: Chạy test.** Kỳ vọng PASS. Sau đó chạy `flutter analyze`, kỳ vọng 0 error.
- [ ] **Step 5: Commit.** `git add frontend/lib/core/widgets frontend/test/grouped_list_test.dart && git commit -m "feat(ui): add HIG grouped list widgets"`

### Task 2: Viết lại tab Cá nhân

**Files:**
- Modify: `frontend/lib/features/profile/profile_screen.dart`

**Interfaces:**
- Consumes: widget từ Task 1; `NotificationSettingsScreen` từ Task 3.
- **Làm Task 3 trước Task 2**, hoặc tạm dùng `SettingsScreen` rồi đổi lại khi xong Task 3.

- [ ] **Step 1: Viết lại `build`** theo sơ đồ "Cấu trúc tab Cá nhân".
  - `Scaffold(backgroundColor: AppColors.n100)`, `ListView` có padding dọc 24.
  - Phần đầu trang: `CircleAvatar(radius: 32, backgroundColor: AppColors.p500)` chứa chữ cái đầu, tên (`maxLines: 1`, `ellipsis`), email (`maxLines: 1`, `ellipsis`).
  - Giữ nguyên `_loadProfile`, `_cachedProfile` và nội dung chữ của Trợ giúp/Giới thiệu.
  - Bottom sheet "Thông tin cá nhân" và Trợ giúp/Giới thiệu dùng `showModalBottomSheet(showDragHandle: true)`. Bên trong sheet Thông tin cá nhân là `GroupedSection` với 2 hàng chỉ xem (`value`).
- [ ] **Step 2: Đăng xuất có xác nhận.** `showAdaptiveDialog<bool>`: tiêu đề "Đăng xuất?", nội dung "Bạn sẽ cần đăng nhập lại để dùng ứng dụng.", nút "Huỷ" và "Đăng xuất" (đỏ, phá huỷ). Chỉ khi chọn `true` mới gọi `_logout()` hiện có.
- [ ] **Step 3: Xoá** hàm `_row`, các import không còn dùng (`app_theme.dart`, `notification_screen.dart`, `settings_screen.dart`) và mọi `TextStyle(fontSize: …)` viết tay.
- [ ] **Step 4: Kiểm tra.** `flutter analyze` (0 error), `flutter test` (PASS). Chạy app: mở tab Cá nhân, mở từng hàng, Huỷ rồi Đăng xuất. Thử tài khoản có email dài.
- [ ] **Step 5: Commit.** `git commit -am "refactor(ui): rebuild profile tab as HIG grouped settings"`

### Task 3: Màn Thông báo (thay `settings_screen.dart`)

**Files:**
- Move: `git mv frontend/lib/features/profile/settings_screen.dart frontend/lib/features/profile/notification_settings_screen.dart`
- Modify: file vừa chuyển. Đổi class thành `NotificationSettingsScreen` và sửa mọi import (`grep -rn "settings_screen.dart\|SettingsScreen" frontend/lib frontend/test`).

- [ ] **Step 1: Viết lại `build`.**
  - `Scaffold(backgroundColor: AppColors.n100, appBar: AppBar(title: Text('Thông báo'), backgroundColor: AppColors.n100, elevation: 0, scrolledUnderElevation: 0))`.
  - Thân là `ListView` padding dọc 24 với một `GroupedSection(header: 'Nhận thông báo khi', footer: 'Thông báo trong ứng dụng vẫn được lưu kể cả khi tắt.')`:
    - `loading`: một hàng chứa `CircularProgressIndicator.adaptive()` căn giữa, cao 52.
    - `error`: `GroupedTile(title: 'Không tải được cài đặt', trailing: TextButton('Thử lại'))`.
    - `data`: 2 `GroupedSwitchTile` (icon `Icons.payments_outlined` và `Icons.task_alt`, tiêu đề và phụ đề giữ như cũ). `onChanged` bằng `null` khi `notifier.isSaving`.
- [ ] **Step 2: Giữ nguyên hành vi lưu.** Gọi setter, `setState` trước và sau (mỗi lần kiểm tra `mounted`), SnackBar "Không lưu được cài đặt. Vui lòng thử lại." khi setter trả `false`.
- [ ] **Step 3: Xoá** `AnimationController`, `FadeTransition`, `SingleTickerProviderStateMixin`, nút Đăng xuất và các import liên quan (`login_screen.dart`, `auth_provider.dart` nếu không còn dùng).
- [ ] **Step 4: Kiểm tra.** `flutter analyze`, `flutter test` (gồm `user_preferences_test.dart`) PASS. Chạy app: bật/tắt từng công tắc, bấm rồi thoát màn ngay, không crash.
- [ ] **Step 5: Commit.** `git add -A frontend/lib/features/profile && git commit -m "refactor(ui): HIG notification settings screen"`

### Task 4: Màn Cài đặt nhóm

**Files:**
- Modify: `frontend/lib/features/groups/screens/group_settings_screen.dart`

- [ ] **Step 1: Thêm theo dõi thay đổi.** Thêm `bool get _isDirty`, so `_nameController.text.trim()` và `_descController.text.trim()` với `widget.group.name` / `widget.group.description ?? ''`. Gọi `setState` trong listener của 2 controller. Nút "Lưu" trên AppBar: chỉ hiện khi `isAdminOrOwner`, `onPressed` là `null` khi `!_isDirty || _isSaving`.
- [ ] **Step 2: Viết lại `build`.** Nền `n100`, `ListView` padding dọc 24.
  - `GroupedSection(header: 'Thông tin nhóm', footer: isAdminOrOwner ? null : 'Chỉ trưởng nhóm hoặc quản trị viên mới sửa được.')`.
  - Admin: mỗi hàng là `GroupedTile(title: 'Tên', trailing: Expanded TextFormField(textAlign: TextAlign.end, decoration: InputDecoration.collapsed(hintText: 'Bắt buộc')))`. `Mô tả` dùng `minLines: 1, maxLines: 4`, `hintText: 'Không bắt buộc'`. Giữ validator tên.
  - Thành viên thường: `GroupedTile(title: 'Tên', value: …)` và `GroupedTile(title: 'Mô tả', value: … hoặc 'Không có')`.
  - Admin còn có thêm `GroupedSection(children: [GroupedTile(title: 'Xoá nhóm', destructive: true, onTap: _deleteGroup)])`.
  - Xoá tiêu đề "Vùng nguy hiểm", `Divider` và `OutlinedButton`.
- [ ] **Step 3: Hộp xác nhận và SnackBar.**
  - `_deleteGroup` dùng `showAdaptiveDialog`: tiêu đề "Xoá nhóm này?", nội dung "Toàn bộ khoản chi và lịch sử của nhóm sẽ bị xoá. Không thể hoàn tác.", nút "Huỷ" và "Xoá" (phá huỷ).
  - SnackBar: "Đã lưu thay đổi.", "Đã xoá nhóm.", "Không lưu được: <lỗi>", "Không xoá được: <lỗi>". Bỏ `backgroundColor` và emoji.
- [ ] **Step 4: Kiểm tra.** `flutter analyze`, `flutter test` PASS. Chạy app với cả tài khoản admin và tài khoản thành viên thường: lưu khi chưa sửa thì nút bị khoá, sửa tên rồi lưu, Huỷ rồi Xoá.
- [ ] **Step 5: Commit.** `git commit -am "refactor(ui): HIG group settings screen"`

---

## Hoàn tất

- [ ] Chạy `grep -n "Color(0x\|fontSize:\|Colors\.\(red\|green\|orange\|grey\)" frontend/lib/core/widgets/grouped_list.dart frontend/lib/features/profile/*.dart frontend/lib/features/groups/screens/group_settings_screen.dart`. Kỳ vọng không có kết quả.
- [ ] Chụp màn hình 3 màn (tab Cá nhân, Thông báo, Cài đặt nhóm ở góc nhìn admin và thành viên), lưu vào `docs/screenshots/settings/` để Claude Code review.
- [ ] Cập nhật `docs/PROGRESS.md`, báo lại danh sách commit.
