# Review vòng 2: plan "Làm mới nền"

Review của Claude Code trên `d1473af..9f7dd4e`. Áp dụng Global Constraints của `2026-11-24-background-refresh.md`. Mỗi mục một commit.

Đây là vòng 2 trên tối đa 3. Nếu vòng 3 vẫn còn lỗi đáng kể, phần đồng bộ sẽ dừng để chuyển sang OCR.

## C1. Đổi nhóm phải xoá dữ liệu của nhóm cũ (quan trọng)

**Lỗi:** sau quy tắc "chỉ hiện spinner khi chưa có dữ liệu" (B1), đổi nhóm trong dropdown sẽ giữ nguyên công nợ của nhóm cũ nhưng hiển thị dưới tên nhóm mới. Nếu lúc đó mất mạng, dữ liệu cũ nằm đó mãi. Nguy hiểm hơn, bấm một gợi ý lúc này sẽ tạo yêu cầu thanh toán vào nhóm mới bằng dữ liệu của nhóm cũ.

**Sửa (`live_settlement_screen.dart`):**
- Thêm `int? _loadedGroupId`, chỉ gán khi `_load` thành công.
- Định nghĩa `bool get _hasData => _debt != null && _loadedGroupId == _groupId`, rồi thay mọi chỗ đang kiểm tra `_debt == null` / `_debt != null` bằng `!_hasData` / `_hasData`.
- Trong `onChanged` của dropdown, đặt `_debt = _smart = null`, `_settlements = []` trong cùng `setState` với `_groupId = v`, trước khi gọi `_load()`.

## C2. Người dùng tự bấm tải lại thì phải biết khi thất bại (quan trọng)

**Lỗi:** khi đã có dữ liệu, lỗi của nút "Tải lại", của kéo để làm mới, và của lần tải sau khi tạo yêu cầu đều bị nuốt im lặng. Nếu một lần poll silent chạy chồng lên, kết quả của lần tải do người dùng bấm còn bị bỏ qua mà không báo gì.

**Sửa (cả `live_settlement_screen.dart` và `notification_screen.dart`):**
- Đổi chữ ký thành `_load({bool silent = false, bool userInitiated = false})`.
  - Kéo để làm mới: `_load(silent: true, userInitiated: true)`. Không hiện spinner toàn màn, nhưng báo lỗi.
  - Nút "Tải lại", lần tải sau `_create`: `_load(userInitiated: true)`.
  - Poll, push tới, app quay lại foreground, hết bị che: chỉ `silent: true`.
- Thêm cờ `bool _pendingUserReload`, đặt `true` khi bắt đầu một lần tải `userInitiated`. Một lần tải bất kỳ (kể cả silent) kết thúc với `version == _version` sẽ:
  - nếu lỗi **và** (`userInitiated` hoặc `_pendingUserReload`) **và** đã có dữ liệu: hiện `SnackBar('Không tải lại được. Kiểm tra kết nối và thử lại.')`;
  - sau đó đặt `_pendingUserReload = false`.
- `_initialize` (nút Tải lại trên AppBar của màn quyết toán): khi lỗi mà đã có dữ liệu thì cũng hiện SnackBar như trên.

## C3. Quay về từ màn thanh toán luôn lấy dữ liệu mới (quan trọng)

**Lỗi:** dòng `await _load()` sau khi màn thanh toán đóng đã bị bỏ ở B4. Nếu lúc đó đang có một lần poll chạy dở (bắt đầu trước khi thanh toán), `setCovered(false)` sẽ bỏ qua, và số dư cũ còn nằm trên màn tới 20 giây.

**Sửa:** thêm lại `await _load(silent: true)` sau `Navigator.push(...)` trong `_openPayment`. Kết quả trùng lặp đã có cơ chế `_version` loại bỏ.

## C4. Dọn nhỏ

- **`VisiblePoller._resolveForeground`:** chỉ trả `false` với `paused`, `hidden`, `detached`. `inactive` và `null` được coi là foreground, cho khớp với `onLifecycle`. Thêm test `'starts running when initial state is inactive'`.
- **Đếm ký tự mô tả theo bản đã trim**, vì khi gửi app cũng trim. Validator và bộ đếm ở `create_group_dialog.dart` và `group_settings_screen.dart` dùng `val.trim().runes.length`.
- **Test emoji ở backend chưa bảo vệ được bản sửa code point.** Test hiện tại vẫn pass với code cũ. Sửa lại:
  - `descriptionWithEmojiUnder500CodePoints_isAccepted` dùng **400** emoji `😀` (800 UTF-16, 400 code point) → 200. Code cũ sẽ fail test này.
  - Thêm `description501CodePoints_isRejected` → 400.
  - Thêm một test cho `POST /api/groups` (tạo nhóm) với 400 emoji → 201.

## Kiểm tra cuối

`cd api; .\mvnw.cmd test` và `cd frontend; flutter analyze; flutter test` đều PASS. Kiểm tra bằng mắt:
1. Đổi nhóm khi đang tắt mạng: không còn hiện công nợ của nhóm cũ.
2. Bấm Tải lại khi tắt mạng: có SnackBar báo lỗi.
3. Thanh toán xong quay lại: số dư được cập nhật ngay.

Cập nhật `docs/PROGRESS.md` và báo lại danh sách commit.
