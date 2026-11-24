# Làm mới nền không làm gián đoạn màn hình

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Việc tự làm mới mỗi 20 giây (`VisiblePoller`, commit `43ea67e`) phải diễn ra âm thầm. Không nháy spinner, không xoá dữ liệu khi lỗi mạng, và chỉ chạy khi màn hình thực sự đang hiển thị.

**Architecture:** Mỗi màn tách việc "tải lần đầu hoặc người dùng bấm tải lại" (có spinner, có màn lỗi) khỏi "làm mới nền" (giữ nguyên dữ liệu cũ). `VisiblePoller` theo dõi thêm việc route có bị màn khác che hay không, thông qua một `RouteObserver` dùng chung.

**Tech Stack:** Flutter, flutter_test (`fake_async`).

**Spec:** Review cuối của Claude Code trên `e39b351..ce56b1b` (ngày 2026-11-24).

## Bối cảnh (review đã xác nhận)

- **Spinner nháy mỗi 20 giây.** `live_settlement_screen.dart:110-118`: `_load()` luôn đặt `_loading = true`. Khi đó build thay cả thân màn bằng spinner, mất vị trí cuộn, ẩn thanh hành động bên dưới.
- **Lỗi mạng xoá sạch dữ liệu đang xem.** Ở cả 2 màn, một lần poll thất bại sẽ thay toàn bộ dữ liệu bằng màn lỗi (`notification_screen.dart:72`).
- **Vẫn poll khi bị che.** `VisiblePoller` chỉ theo dõi vòng đời app. Khi `PaymentDialog` hoặc `NotificationScreen` mở đè lên, màn bên dưới vẫn tiếp tục gọi API.
- **Web ngừng poll khi chỉ mất focus.** Trên web, lifecycle chuyển sang `inactive` mỗi khi cửa sổ mất focus, trong khi `VisiblePoller` dừng ở mọi trạng thái khác `resumed`.
- **Lỗi trong `onTick` thoát ra ngoài.** `_tick` chỉ có `try/finally`, không có `catch`.
- **Thông báo vừa đọc lại hiện là chưa đọc.** Một lần poll bắt đầu trước khi PATCH đánh dấu đã đọc xong có thể trả về bản cũ và ghi đè lên.

## Global Constraints

- Không đổi API backend, ngoại trừ Task 4. Không thêm dependency. Không đụng `.env`. Không push.
- **Không commit `frontend/android/gradle.properties`.**
- Mỗi task một commit. Cập nhật `docs/PROGRESS.md` sau mỗi task.
- Kiểm tra: `cd frontend; flutter analyze` (0 error) và `flutter test` (PASS). Task 4 thêm `cd api; .\mvnw.cmd test`.
- Plan mơ hồ hoặc không khớp với code: dừng lại và hỏi.

## Review Focus

1. **Đang cuộn danh sách nợ** đúng lúc poll chạy: vị trí cuộn giữ nguyên, thanh hành động vẫn hiện (kiểm tra bằng mắt ở Task 2).
2. **Mất mạng 1 phút** khi đang mở màn thông báo: danh sách cũ vẫn còn, có lại mạng thì tự cập nhật (Task 3).
3. **Mở `PaymentDialog` từ màn quyết toán:** màn bên dưới ngừng gọi API; đóng dialog thì tải lại ngay (Task 1, 2).
4. **Đang mở màn thông báo**, bấm đọc 1 thông báo đúng lúc poll chạy: thông báo không quay lại trạng thái chưa đọc (Task 3).
5. **Trên web**, click sang cửa sổ khác trong khi màn quyết toán vẫn hiển thị: vẫn tiếp tục cập nhật (Task 1).

---

### Task 1: `VisiblePoller` biết khi nào màn hình bị che

**Files:**
- Create: `frontend/lib/core/navigation/route_observer.dart` chứa `final RouteObserver<ModalRoute<void>> appRouteObserver = RouteObserver<ModalRoute<void>>();`
- Modify: `frontend/lib/main.dart`: thêm `navigatorObservers: [appRouteObserver]` vào `MaterialApp`.
- Modify: `frontend/lib/core/utils/visible_poller.dart`
- Test: `frontend/test/visible_poller_test.dart` (bổ sung)

**Interfaces (Produces), thêm vào `VisiblePoller`:**
```dart
void setCovered(bool covered);   // true → dừng; false → nếu app đang foreground thì start() và gọi onTick ngay 1 lần
// onLifecycle: resumed → start (trừ khi đang covered); hidden/paused/detached → stop; inactive → không làm gì
// _tick: try { await onTick(); } catch (e) { debugPrint('VisiblePoller: $e'); } finally { _running = false; }
```

- [ ] **Step 1: Viết test thất bại.**
```dart
test('covered route stops ticking and uncover ticks immediately')
  // start(); setCovered(true); elapse(60s) → 0 lần; setCovered(false) → 1 lần ngay; elapse(21s) → 2 lần
test('inactive does not stop polling')
  // start(); onLifecycle(AppLifecycleState.inactive); elapse(41s) → 2 lần
test('resumed while covered stays stopped')
  // setCovered(true); onLifecycle(resumed); elapse(60s) → 0 lần
test('onTick error is swallowed and polling continues')
  // onTick ném Exception; elapse(41s) → gọi 2 lần, không có exception thoát ra (tester/fakeAsync không báo lỗi)
```
- [ ] **Step 2: Chạy.** `flutter test test/visible_poller_test.dart`. Kỳ vọng FAIL.
- [ ] **Step 3: Sửa code** theo Interfaces. Tạo `route_observer.dart`, sửa `main.dart`.
- [ ] **Step 4: Chạy lại.** PASS, `flutter analyze` 0 error.
- [ ] **Step 5: Commit.** `git commit -m "feat(sync): pause VisiblePoller when route is covered; ignore web inactive"` (nhớ `git add` file mới).

### Task 2: Màn quyết toán làm mới âm thầm

**Files:**
- Modify: `frontend/lib/features/settlements/live_settlement_screen.dart`

**Interfaces:** Consumes `appRouteObserver`, `VisiblePoller.setCovered` từ Task 1.

- [ ] **Step 1: Thêm tham số `silent`.** Đổi `_load()` thành `Future<void> _load({bool silent = false})`.
  - `silent == false` (lần đầu, nút tải lại, kéo để làm mới, push tới): giữ hành vi hiện tại.
  - `silent == true`: **không** đặt `_loading`. Nếu thành công thì chỉ cập nhật dữ liệu. Nếu lỗi mà đã có dữ liệu thì giữ nguyên dữ liệu và `_error`, chỉ `debugPrint`. Nếu lỗi mà chưa có dữ liệu thì hành xử như `silent == false`.
  - Giữ cơ chế `_version` để bỏ kết quả cũ.
- [ ] **Step 2: Poller gọi bản âm thầm.** `VisiblePoller(onTick: () => _load(silent: true))`. Listener `onMessage` và lifecycle resumed vẫn gọi `_load()` như cũ.
- [ ] **Step 3: Theo dõi route.** Mix `RouteAware`. Trong `didChangeDependencies`, gọi `appRouteObserver.subscribe(this, ModalRoute.of(context)!)` (chỉ một lần). Trong `dispose`, gọi `unsubscribe`. Các hàm `didPushNext` → `_poller.setCovered(true)`, `didPopNext` → `_poller.setCovered(false)`.
- [ ] **Step 4: Kiểm tra.** `flutter analyze`, `flutter test` PASS. Chạy app: mở màn quyết toán, cuộn xuống, chờ hơn 40 giây. Màn không nháy, vị trí cuộn giữ nguyên. Mở `PaymentDialog` thì log không còn request định kỳ.
- [ ] **Step 5: Commit.** `git commit -am "fix(settlement): silent background refresh keeps data and scroll"`

### Task 3: Màn thông báo làm mới âm thầm và không mất trạng thái đã đọc

**Files:**
- Modify: `frontend/lib/features/notifications/notification_screen.dart`
- Create: `frontend/lib/features/notifications/notification_merge.dart`
- Test: `frontend/test/notification_merge_test.dart`

**Interfaces (Produces):**
```dart
List<Map<String, dynamic>> applyPendingReads(
    List<Map<String, dynamic>> fetched, Set<Object> pendingReadIds);
// trả về bản sao; mọi item có item['id'] thuộc pendingReadIds được đặt isRead = true
```

- [ ] **Step 1: Viết test thất bại.**
```dart
test('pending read ids override stale isRead=false')   // fetched [{id:1,isRead:false},{id:2,isRead:false}], pending {1} → id1 true, id2 false
test('does not mutate input list')                     // fetched[0]['isRead'] vẫn false sau khi gọi
test('empty pending returns equal content')
```
- [ ] **Step 2: Chạy.** FAIL. **Step 3:** Viết `applyPendingReads`. **Step 4:** PASS.
- [ ] **Step 5: Sửa màn hình.**
  - Thêm `final Set<Object> _pendingReadIds = {}`.
  - `_read(id)`: thêm id vào set **trước** khi gọi PATCH. Thành công thì giữ id trong set cho tới lần tải kế tiếp có `isRead == true` từ server. Lỗi thì xoá id khỏi set.
  - `_load({bool silent = false})`: cùng quy tắc với Task 2. Kết quả trả về được đưa qua `applyPendingReads(fetched, _pendingReadIds)`. Sau đó xoá khỏi set những id mà server đã trả `isRead == true`.
  - Poller gọi `_load(silent: true)`. Thêm `RouteAware` giống Task 2, Step 3.
- [ ] **Step 6: Kiểm tra.** `flutter analyze`, `flutter test` PASS. Chạy app: tắt Wi-Fi 1 phút khi đang mở màn thông báo, danh sách vẫn còn. Bật lại thì danh sách tự cập nhật.
- [ ] **Step 7: Commit.** `git add` các file và `git commit -m "fix(notifications): silent refresh, keep data on poll error, preserve pending reads"`

### Task 4: Test đường xoá nhóm thật + giới hạn độ dài mô tả

**Files:**
- Modify: `api/src/test/java/com/splitdebt/api/controller/SettingsSecurityTest.java`
- Modify: `api/src/main/java/com/splitdebt/api/service/impl/GroupServiceImpl.java` (`createGroup`, `updateGroup`)
- Modify: `frontend/lib/features/groups/screens/group_settings_screen.dart` (ô mô tả: `maxLength: 500`)

- [ ] **Step 1: Viết test.**
  - **Giữ** test INACTIVE hiện có.
  - Thêm `adminWhoLeft_cannotDeleteGroup`: B được thêm làm ADMIN, B gọi `DELETE /api/groups/{id}/members/me` (200), rồi B gọi `DELETE /api/groups/{id}` → 403.
  - Thêm `descriptionOver500Chars_isRejected`: chủ nhóm gọi PUT `/api/groups/{id}` với mô tả 501 ký tự → 400.
- [ ] **Step 2: Chạy.** `.\mvnw.cmd test -Dtest=SettingsSecurityTest`. Kỳ vọng: `adminWhoLeft` PASS ngay (đây là test hồi quy), `descriptionOver500Chars` FAIL.
- [ ] **Step 3: Thêm kiểm tra** `description != null && description.length() > 500` thì ném `IllegalArgumentException("Mô tả nhóm tối đa 500 ký tự")` trong `createGroup` và `updateGroup`. Kiểm tra `GlobalExceptionHandler` đã map `IllegalArgumentException` → 400 chưa; nếu chưa thì dừng lại và hỏi. Ở app, thêm `maxLength: 500` cho ô mô tả.
- [ ] **Step 4: Kiểm tra.** `.\mvnw.cmd test` và `flutter test` PASS.
- [ ] **Step 5: Commit.** `git commit -am "test(group): cover leave-then-delete path; limit description to 500 chars"`

---

## Không làm (đã cân nhắc)

- Các đường đọc dữ liệu (`getGroupById`, `getGroupMembers`) chưa kiểm tra trạng thái INACTIVE. Code chính hiện không có chỗ nào đặt INACTIVE (rời nhóm hay bị xoá đều xoá hẳn bản ghi), nên chưa cần xử lý.

## Hoàn tất

- [ ] `cd api; .\mvnw.cmd test` và `cd frontend; flutter analyze; flutter test` đều PASS. Cập nhật `docs/PROGRESS.md`, báo lại danh sách commit.
