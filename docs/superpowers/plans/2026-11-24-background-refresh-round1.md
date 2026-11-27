# Review vòng 1: plan "Làm mới nền"

Review của Claude Code trên `ce56b1b..d1473af`. Áp dụng toàn bộ Global Constraints của `2026-11-24-background-refresh.md`. Mỗi mục một commit.

## B1. Một quy tắc chung cho cả 2 màn: chỉ hiện spinner khi chưa có dữ liệu (quan trọng)

**Lỗi:**
- Màn thông báo vẫn thay cả danh sách bằng spinner khi có push, khi app quay lại foreground và khi kéo để làm mới, vì các lời gọi này dùng `_load()` không silent (`notification_screen.dart:43, 72, 84`).
- Màn quyết toán có thể kẹt spinner: một lần poll silent tăng `_version`, làm lần tải do người dùng bấm bị bỏ qua mà `_loading` không bao giờ được trả về `false` (`live_settlement_screen.dart:165`).

**Quy tắc mới, áp dụng cho cả `live_settlement_screen.dart` và `notification_screen.dart`:**
1. Build chỉ hiện spinner toàn màn khi `_loading && <chưa có dữ liệu>`. Màn quyết toán coi là chưa có dữ liệu khi `_debt == null`; màn thông báo khi `_items.isEmpty && _userId == null`. Nếu đã có dữ liệu thì vẫn hiển thị dữ liệu, kể cả khi đang tải.
2. Mọi lời gọi tự động đều dùng `_load(silent: true)`: push tới (`onMessage`), app quay lại foreground, poll, hết bị che.
3. `RefreshIndicator(onRefresh: () => _load(silent: true))`: kéo để làm mới đã có spinner riêng của nó.
4. Chỉ nút "Tải lại" và lần tải đầu tiên gọi `_load()` không silent.
5. **Mọi lần kết thúc của `_load`** (thành công hay lỗi, silent hay không) mà có `version == _version` đều đặt `_loading = false`.
6. Khi app quay lại foreground, chỉ tải lại nếu màn **không bị che**. Thêm getter `bool get isCovered` vào `VisiblePoller` và kiểm tra trước khi tải.

**Test:** không thêm widget test (GoogleFonts gọi mạng). Kiểm tra bằng mắt:
- Cuộn màn thông báo, gửi push từ tài khoản khác: danh sách không nháy.
- Đổi nhóm trong dropdown của màn quyết toán rồi tắt mạng: spinner không bị kẹt, nút Tải lại vẫn bấm được.

## B2. Đọc thông báo thất bại: khôi phục đúng item đang hiển thị (quan trọng)

**Lỗi:** nếu PATCH thất bại sau khi một lần poll đã thay `_items`, code đặt lại `isRead = false` trên map cũ đã giữ lúc bấm. Item đang hiển thị trên màn hình thì vẫn ở trạng thái đã đọc.

**Sửa:** khi lỗi, xoá id khỏi `_pendingReadIds`, rồi `setState` và tìm item theo `id` trong `_items` **hiện tại** để đặt `isRead = false`.

**Test:** thêm vào `notification_merge_test.dart` một hàm thuần `List<Map<String, dynamic>> markUnread(List<Map<String, dynamic>> items, Object id)` (trả bản sao, chỉ đổi item có id đó), kèm test `'markUnread only changes matching id'`. Màn hình dùng hàm này.

## B3. Giới hạn 500 ký tự: đếm giống nhau ở 2 phía, không cắt mất dữ liệu cũ (quan trọng)

**Lỗi:**
- Java `String.length()` đếm UTF-16, còn Flutter `maxLength` đếm grapheme. Kết quả: app cho nhập nhưng server lại từ chối.
- `maxLength` ở app còn tự cắt mô tả cũ dài hơn 500 ký tự ngay ở lần gõ đầu tiên.

**Sửa:**
- **Backend** (`GroupServiceImpl` ở 2 chỗ): đếm bằng `description.codePointCount(0, description.length()) > 500`.
- **App** (`group_settings_screen.dart` và `create_group_dialog.dart`): bỏ `maxLength`. Thêm validator `value.runes.length > 500 → 'Mô tả tối đa 500 ký tự'`, và một dòng phụ hiển thị `'${runes.length}/500'` dưới ô nhập (dùng `helperText` hoặc `counterText` của `InputDecoration`).

**Test:**
- Backend: thêm `descriptionWithEmojiUnder500CodePoints_isAccepted`. Mô tả gồm 250 emoji `😀` (500 UTF-16, 250 code point) → kỳ vọng 200.
- App: không thêm test.

## B4. Dọn nhỏ

- `VisiblePoller`: khởi tạo `_isForeground` từ `WidgetsBinding.instance.lifecycleState` (`null` hoặc `resumed` nghĩa là foreground). Thêm test `'starts stopped when app is not resumed'` bằng cách truyền lifecycle ban đầu qua tham số constructor tuỳ chọn `AppLifecycleState? initialState`, để test không phụ thuộc binding.
- `live_settlement_screen._openPayment`: bỏ `await _load()` sau khi route đóng, vì `didPopNext` đã tự gọi tick làm mới.

## Không sửa (đã cân nhắc)

- `RouteObserver` cũng coi dialog và dropdown là "bị che", nên đóng dropdown có thể sinh thêm một lần tải silent. Chi phí nhỏ, kết quả thừa đã bị bỏ nhờ cơ chế `_version`.

## Kiểm tra cuối

`cd api; .\mvnw.cmd test` và `cd frontend; flutter analyze; flutter test` đều PASS. Cập nhật `docs/PROGRESS.md`, báo lại danh sách commit.
