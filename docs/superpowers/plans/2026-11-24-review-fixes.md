# SplitDebt — Kế hoạch sửa sau review (bảo mật, Cài đặt, dọn code, giao diện)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Vá lỗ hổng phân quyền ở API cài đặt, làm màn Cài đặt lưu thật, xoá code chết/trùng và thống nhất màu giao diện.

**Architecture:** Backend Spring Boot (`api/`) giữ một controller cài đặt duy nhất (`SettingsController`, route `/api/settings/...`) có kiểm tra quyền. Hai cờ thông báo trong `UserSetting` được `NotificationService` tôn trọng. Frontend Flutter (`frontend/`) có repository + `StateNotifier` cho cài đặt người dùng. Màu chỉ lấy từ `AppColors`.

**Tech Stack:** Java 17 / Spring Boot 3 / JUnit 5 + MockMvc + Mockito (H2 profile `test`); Flutter + flutter_riverpod 2.5 + Dio; flutter_test.

**Spec:** Bản review trong hội thoại ngày 2026-11-24 (tóm tắt ở mục "Bối cảnh" bên dưới, không có file spec riêng).

## Bối cảnh (những gì review đã xác nhận)

- `api/.../controller/SettingController.java` (`/api/v1/settings/user/{userId}`, `/group/{groupId}`) không kiểm tra quyền → ai đăng nhập cũng đọc/sửa được cài đặt người khác. Frontend không dùng controller này.
- `SettingsController` (`/api/settings`): `/user/me` an toàn, nhưng `/group/{groupId}` GET/PUT cũng không kiểm tra thành viên nhóm.
- `SettingServiceImpl.getUserSetting` / `getGroupSetting` là `@Transactional(readOnly = true)` nhưng có thể INSERT bản ghi mặc định → lỗi trên PostgreSQL.
- `settings_screen.dart` chỉ `setState`, không lưu gì. Các mục ngân sách, ngày đóng băng, dark mode, ngôn ngữ, sinh trắc học không có backend hay chức năng thật.
- Các cờ `notifyOn*` trong `UserSetting` không được dùng ở đâu. Mọi thông báo hiện có đều thuộc quyết toán: `SETTLEMENT_REQUEST`, `SETTLEMENT_PAID`, `SETTLEMENT_CONFIRMED` (trong `SettlementService`).
- Màn chết (không ai gọi): `home/main_screen.dart`, `settlements/presentation/financial_dashboard_screen.dart`, `expenses/expense_detail_screen.dart`.
- Có 128 chỗ ghi màu cứng `Color(0x…)`. Thanh điều hướng dưới tô màu chọn là đen `#18181B`, khác màu chính tím `#6C5CE7`.
- `SettlementEngineServiceImpl` ghi bảng `Debt` sau mỗi lần thêm/sửa/xoá khoản chi, nhưng không chỗ nào đọc bảng này. Nợ thật được tính bởi `DebtCalculationService`.

## Global Constraints

- Không đọc, không sửa, không commit `api/.env` hay bất kỳ `.env` nào. Không đọc `node_modules`, `target`, `build`, lockfile.
- Không thêm dependency mới vào `pom.xml` hay `pubspec.yaml`.
- Chuỗi hiển thị cho người dùng viết bằng tiếng Việt có dấu.
- Không đổi hợp đồng các API frontend đang dùng, trừ những gì task ghi rõ.
- `SettingsController` vẫn trả DTO thô (không bọc `ApiResponse`), giữ nguyên như hiện tại.
- Backend test: `cd api; .\mvnw.cmd test` (Windows) hoặc `./mvnw test`. Frontend: `cd frontend; flutter analyze; flutter test`.
- Sau mỗi task: cập nhật `docs/PROGRESS.md` (tối đa ~30 dòng: Done / In progress / Next / Blockers) và commit trên branch `dev2-dat`. Không push.
- Nếu plan mơ hồ hoặc mâu thuẫn với code: dừng lại và hỏi, không tự đoán.

## Review Focus

1. Người không phải thành viên gọi PUT `/api/settings/group/{id}` phải nhận 403 và dữ liệu không bị đổi (test ở Task 1).
2. Người dùng mới, chưa có bản ghi `user_settings`: GET `/api/settings/user/me` phải trả mặc định, không lỗi 500 (test ở Task 1).
3. Tắt thông báo quyết toán: bản ghi `Notification` trong app vẫn được lưu, chỉ không gửi push (test ở Task 2).
4. Lưu cài đặt thất bại (mất mạng): công tắc phải quay về trạng thái cũ và báo lỗi, không giả vờ đã lưu (test ở Task 3).
5. Sau khi xoá/đổi tên file: `flutter analyze` không có error. App vẫn mở được cả 4 tab (kiểm tra ở Task 4, 5).

---

### Task 1: Đóng lỗ hổng phân quyền ở API cài đặt

**Files:**
- Delete: `api/src/main/java/com/splitdebt/api/controller/SettingController.java`
- Modify: `api/src/main/java/com/splitdebt/api/controller/SettingsController.java` (hai method `/group/{groupId}`)
- Modify: `api/src/main/java/com/splitdebt/api/service/impl/SettingServiceImpl.java` (`getUserSetting`, `getGroupSetting`: bỏ `readOnly = true`)
- Test: `api/src/test/java/com/splitdebt/api/controller/SettingsSecurityTest.java` (tạo mới)

**Interfaces:**
- Consumes: `GroupAccessService.requireActiveMember(Long groupId, Long userId)`, sẵn có, ném `GroupPermissionException` → 403 qua `GlobalExceptionHandler`.
- Produces: `/api/settings/group/{groupId}` GET/PUT chỉ thành viên ACTIVE dùng được. `/api/v1/settings/**` không còn tồn tại.

- [x] **Step 1: Viết test thất bại.** Tạo `SettingsSecurityTest` theo mẫu `GroupControllerTest`: `@SpringBootTest @AutoConfigureMockMvc @ActiveProfiles("test") @Transactional`, `@MockBean FcmPushService`. Chép helper `newAccount()`/`account()` và cách tạo JWT (`jwt.generateJwtToken(email)`). Tạo nhóm bằng `POST /api/groups` với token chủ nhóm, lấy `data.id`.

```java
@Test void nonMember_cannotReadGroupSettings()   // GET /api/settings/group/{gid} với token người lạ → status 403
@Test void nonMember_cannotUpdateGroupSettings() // PUT cùng route, body {"requireApproval":true,"defaultCurrency":"USD"} với token người lạ → 403;
                                                 // sau đó GET bằng token chủ nhóm → $.defaultCurrency vẫn KHÁC "USD"
@Test void member_canReadGroupSettings()         // GET bằng token chủ nhóm → 200
@Test void newUser_getsDefaultPreferences()      // user vừa tạo, GET /api/settings/user/me → 200, $.language == "VI", $.currency == "VND", $.theme == "LIGHT"
@Test void legacyIdorRoute_isGone()              // GET /api/v1/settings/user/{idCuaNguoiKhac} với token hợp lệ → 404
```

- [x] **Step 2: Chạy test, xác nhận thất bại.** `cd api; .\mvnw.cmd test -Dtest=SettingsSecurityTest`. Kỳ vọng: 3 test `nonMember_*` và `legacyIdorRoute_isGone` FAIL (đang trả 200).
- [x] **Step 3: Sửa code.**
  - Xoá `SettingController.java`.
  - Trong `SettingsController`: inject `GroupAccessService`. Ở đầu cả hai method `/group/{groupId}`, gọi `groupAccessService.requireActiveMember(groupId, getCurrentUser().getId())`.
  - Trong `SettingServiceImpl`: đổi `@Transactional(readOnly = true)` thành `@Transactional` cho `getUserSetting` và `getGroupSetting`.
- [x] **Step 4: Chạy lại.** `.\mvnw.cmd test` (toàn bộ). Kỳ vọng: tất cả PASS, kể cả `SettingsControllerTest` cũ.
- [x] **Step 5: Commit.** `git add -A api/src && git commit -m "fix(api): enforce group membership on settings, remove IDOR settings controller"`

### Task 2: Tôn trọng tuỳ chọn thông báo khi gửi push

**Files:**
- Modify: `api/src/main/java/com/splitdebt/api/dto/UserPreferencesDto.java`: thêm `Boolean notifyOnDebtReminder; Boolean notifyOnSettlement;`
- Modify: `api/src/main/java/com/splitdebt/api/controller/SettingsController.java`: map 2 trường mới ở GET và PUT `/user/me` (null nghĩa là không đổi, `SettingServiceImpl.updateUserSetting` đã xử lý null)
- Modify: `api/src/main/java/com/splitdebt/api/service/NotificationService.java`
- Test: `api/src/test/java/com/splitdebt/api/service/NotificationServiceTest.java` (tạo mới, Mockito thuần, không `@SpringBootTest`)

**Interfaces:**
- Consumes: `UserSettingRepository.findByUserId(Long)` trả `Optional<UserSetting>`.
- Produces: `GET/PUT /api/settings/user/me` JSON có thêm `notifyOnDebtReminder`, `notifyOnSettlement` (boolean). Task 3 dùng hai tên này.

Quy tắc ánh xạ:

| type | cờ quyết định push |
|---|---|
| `SETTLEMENT_REQUEST` | `notifyOnDebtReminder` |
| `SETTLEMENT_PAID`, `SETTLEMENT_CONFIRMED` | `notifyOnSettlement` |
| loại khác | luôn push |

Không có bản ghi `UserSetting` thì coi như bật. Bản ghi `Notification` **luôn** được lưu, chỉ bỏ bước push.

- [x] **Step 1: Viết test thất bại.** Mock `NotificationRepository` (`save` trả lại đối số), `FcmPushService`, `UserSettingRepository`. User có `id = 7L`.

```java
@Test void settlementPush_skipped_whenNotifyOnSettlementFalse()
    // setting.notifyOnSettlement=false; createAndPush(user,"t","c","SETTLEMENT_PAID",Map.of())
    // verify(notificationRepository).save(any()); verify(fcmPushService, never()).sendToUserTopic(any(),any(),any(),any())
@Test void requestPush_skipped_whenNotifyOnDebtReminderFalse()   // type "SETTLEMENT_REQUEST", cờ debtReminder=false → never push, vẫn save
@Test void push_sent_whenNoSettingRow()                           // findByUserId → Optional.empty() → verify push 1 lần với userId 7L
@Test void push_sent_forUnmappedType()                            // type "OTHER", cả 2 cờ false → push 1 lần
```

- [x] **Step 2: Chạy.** `.\mvnw.cmd test -Dtest=NotificationServiceTest`. Kỳ vọng: không biên dịch được hoặc FAIL.
- [x] **Step 3: Sửa code.** Thêm `private final UserSettingRepository userSettingRepository;` vào `NotificationService`. Thêm `private boolean shouldPush(Long userId, String type)` theo bảng trên. Trong `createAndPush`, sau `save` mà `!shouldPush(...)` thì `return saved;` luôn, trước phần đăng ký push. Cập nhật DTO và controller như phần Files.
- [x] **Step 4: Chạy toàn bộ.** `.\mvnw.cmd test`. Kỳ vọng: tất cả PASS.
- [x] **Step 5: Commit.** `git commit -am "feat(api): honor user notification preferences for settlement pushes"` (nhớ `git add` file test mới).

### Task 3: Màn Cài đặt lưu thật, bỏ mục giả

**Files:**
- Create: `frontend/lib/features/profile/user_preferences.dart` (model + repository + notifier + provider)
- Modify: `frontend/lib/features/profile/settings_screen.dart`
- Test: `frontend/test/user_preferences_test.dart`

**Interfaces:**
- Consumes: API từ Task 2: `GET /settings/user/me`, `PUT /settings/user/me` (baseUrl của `dioClient` đã có `/api`). Response là JSON thô, không có envelope `data`.
- Produces:
  - `class UserPreferences { final bool notifyOnDebtReminder; final bool notifyOnSettlement; UserPreferences copyWith({bool? notifyOnDebtReminder, bool? notifyOnSettlement}); factory UserPreferences.fromJson(Map<String, dynamic>) /* null → true */; Map<String, dynamic> toJson(); }`
  - `abstract class UserPreferencesRepository { Future<UserPreferences> fetch(); Future<UserPreferences> save(UserPreferences p); }` và `class DioUserPreferencesRepository implements UserPreferencesRepository` (nhận `Dio` qua constructor).
  - `class UserPreferencesNotifier extends StateNotifier<AsyncValue<UserPreferences>>` với `Future<void> load()`, `Future<bool> setNotifyOnDebtReminder(bool v)`, `Future<bool> setNotifyOnSettlement(bool v)`. Hai setter cập nhật state ngay (optimistic), gọi `save`. Lỗi thì trả state cũ và return `false`; thành công return `true` và state = giá trị server trả về.
  - `final userPreferencesRepositoryProvider = Provider<UserPreferencesRepository>((ref) => DioUserPreferencesRepository(dioClient));`
  - `final userPreferencesProvider = StateNotifierProvider.autoDispose<UserPreferencesNotifier, AsyncValue<UserPreferences>>(...)`, gọi `load()` khi tạo.

- [x] **Step 1: Viết test thất bại** (unit test notifier với `FakeRepo` tự viết trong file test, không cần widget test vì GoogleFonts gọi mạng):

```dart
test('fromJson defaults missing flags to true')        // UserPreferences.fromJson({}) → cả 2 cờ true
test('load exposes fetched preferences')                // fake.fetch trả (true,false) → sau load, state.value!.notifyOnSettlement == false
test('setNotifyOnSettlement persists and returns true') // → true; fake.lastSaved!.notifyOnSettlement == false; state.value cũng false
test('failed save reverts state and returns false')     // fake.save ném Exception → false; state.value!.notifyOnSettlement trở lại true
```

- [x] **Step 2: Chạy.** `cd frontend; flutter test test/user_preferences_test.dart`. Kỳ vọng: FAIL (chưa có file).
- [x] **Step 3: Viết `user_preferences.dart`** theo Interfaces.
- [x] **Step 4: Viết lại phần thân `settings_screen.dart`.** Giữ AppBar, animation, nút đăng xuất (đoạn gọi `authProvider.notifier).logout()`). Xoá toàn bộ mục "CÀI ĐẶT NHÓM" (tiền tệ, Min-Cash-Flow, ngân sách, ngày đóng băng) và các mục Dark Mode, Ngôn ngữ, Sinh trắc học cùng các biến state tương ứng. Thêm mục **"THÔNG BÁO"** với 2 `SwitchListTile` đọc `ref.watch(userPreferencesProvider)`:
  - "Nhắc thanh toán nợ", subtitle "Khi có người yêu cầu bạn thanh toán" → `setNotifyOnDebtReminder`
  - "Cập nhật quyết toán", subtitle "Khi khoản thanh toán được đánh dấu hoặc xác nhận" → `setNotifyOnSettlement`
  - Setter trả `false` → `SnackBar(content: Text('Không lưu được cài đặt. Vui lòng thử lại.'))`.
  - State loading → `CircularProgressIndicator`. State error → dòng `'Không tải được cài đặt.'` kèm nút `'Thử lại'` gọi `load()`.
- [x] **Step 5: Kiểm tra.** `flutter analyze` (0 error) và `flutter test` (tất cả PASS).
- [x] **Step 6: Commit.** `git add frontend/lib/features/profile frontend/test/user_preferences_test.dart && git commit -m "feat(app): persist notification preferences, remove non-functional settings"`

### Task 4: Xoá màn chết

**Files:**
- Delete: `frontend/lib/features/home/main_screen.dart`
- Delete: `frontend/lib/features/settlements/presentation/financial_dashboard_screen.dart`
- Delete: `frontend/lib/features/expenses/expense_detail_screen.dart`

- [x] **Step 1: Xác nhận không ai import.** `grep -rn "main_screen.dart\|financial_dashboard_screen.dart\|expense_detail_screen.dart" frontend/lib frontend/test`. Kỳ vọng: không có kết quả. Có kết quả thì dừng và báo lại.
- [x] **Step 2: Xoá bằng `git rm`** cả 3 file.
- [x] **Step 3: Kiểm tra.** `flutter analyze` (0 error), `flutter test` (PASS).
- [x] **Step 4: Commit.** `git commit -m "chore(app): remove unreferenced screens"`

### Task 5: Sắp lại file theo đúng tab, bỏ ô "Khoản chi gần đây" giả

**Files (dùng `git mv`, rồi sửa mọi import):**
- `frontend/lib/features/groups/dashboard_screen.dart` → `frontend/lib/features/home/dashboard_screen.dart` (class giữ `DashboardScreen`)
- `frontend/lib/features/home/home_screen.dart` → `frontend/lib/features/groups/screens/groups_screen.dart`, đổi class `HomeScreen` → `GroupsScreen`
- `frontend/lib/features/home/pdf_overview_screen.dart` → `frontend/lib/features/history/history_screen.dart`, đổi class `OverviewScreen` → `HistoryScreen` (giữ tham số `history`)
- `frontend/lib/features/expenses/pdf_expense_detail.dart` → `frontend/lib/features/expenses/expense_read_screen.dart` (class giữ `ExpenseReadScreen`)
- Modify: `frontend/lib/main_layout_screen.dart` (import và tên class mới)
- Modify: `dashboard_screen.dart` (sau khi chuyển): xoá lời gọi `_buildRecentExpensesSection(...)` (dòng ~131), khoảng cách đi kèm, và cả method `_buildRecentExpensesSection`.

- [x] **Step 1: `git mv` 4 file**, sửa class name như trên.
- [x] **Step 2: Sửa import tương đối** trong chính các file đã chuyển (đường dẫn `../` thay đổi) và mọi file import chúng. Tìm bằng `grep -rn "dashboard_screen.dart\|home_screen.dart\|pdf_overview_screen.dart\|pdf_expense_detail.dart\|HomeScreen\|OverviewScreen" frontend/lib`.
- [x] **Step 3: Xoá section "Khoản chi gần đây"** như phần Files.
- [x] **Step 4: Kiểm tra.** `flutter analyze` (0 error), `flutter test` (PASS). Grep ở Step 2 chỉ còn đường dẫn mới.
- [x] **Step 5: Commit.** `git add -A frontend/lib && git commit -m "refactor(app): align screen files with tabs, drop placeholder recent-expenses card"`

### Task 6: Thống nhất màu theo `AppColors`

**Files:**
- Modify: `frontend/lib/core/theme/app_colors.dart`: thêm `static const List<Color> avatarPalette = [...]` chứa các màu trang trí avatar/nhóm đang ghi cứng trong `group_card.dart` (ví dụ `0xFFFD79A8`, `0xFF74B9FF`, `0xFF55E6C1`, `0xFFA29BFE`, `0xFFFFA000`), giữ nguyên giá trị.
- Modify: `frontend/lib/core/theme/app_theme.dart`: các hằng `primaryColor`, `backgroundColor`, `textPrimaryColor`, `textSecondaryColor`, `errorColor`, `successColor` trỏ tới `AppColors` (`p500`, `n50`, `n800`, `n600`, `error`, `success`). Màu viền/divider dùng `AppColors.n200`.
- Modify: mọi file trong `frontend/lib` còn `Color(0x…)` **trừ** `app_colors.dart` (danh sách từ `grep -rc "Color(0x" frontend/lib`).
- Modify: `frontend/lib/main_layout_screen.dart`: `selectedItemColor: AppColors.p500`, `unselectedItemColor: AppColors.n500`, `backgroundColor: AppColors.n0`.

Bảng thay thế (màu khác không có trong bảng thì lấy token cùng vai trò gần nhất: tím → `p*`, xám/chữ → `n*`, đỏ → `error`/`errorTint`, xanh lá → `success`/`successTint`, cam → `warning`):

| Cũ | Token |
|---|---|
| `6C5CE7`, `6750A4`, `7C3AED` | `p500` |
| `F0EDFF`, `E6E0FF`, `E5DFFF` | `p50` |
| `C4BAEF` | `p200` |
| `4338CA`, `433783`, `493D7E` | `p700` |
| `261C60` | `p900` |
| `202127`, `111827`, `18181B` | `n800` |
| `778092`, `6B7280`, `87909E` | `n600` |
| `9CA3AF`, `B2BEC3` | `n500` |
| `E0E0E0`, `E8E9EF`, `E0E0EA`, `ECECF3`, `EDEDF2`, `EDEDF3`, `EFEFF5`, `EEF2F6` | `n200` |
| `F8F9FA`, `F8F9FC` | `n50` |
| `FF5261`, `EF4444`, `E53935`, `FF7675` | `error` |
| `FFECEE` | `errorTint` |
| `10B981`, `1CC66A`, `10BF8B`, `15803D`, `43A047` | `success` |
| `E7FBF1`, `E8FCF3` | `successTint` |
| `D97706`, `FFA000` (ngoài avatar) | `warning` |
| `0x08000000` (bóng) | giữ nguyên |

- [x] **Step 1: Đếm trước.** `grep -rc "Color(0x" frontend/lib | grep -v ":0"` và ghi lại tổng (93 instances trong 17 files).
- [x] **Step 2: Thay thế** theo bảng, mỗi file thêm `import` tới `core/theme/app_colors.dart` nếu thiếu. Bỏ `const` ở chỗ nào không còn hợp lệ (thường vẫn hợp lệ vì token là `static const`).
- [x] **Step 3: Kiểm tra.** `grep -rn "Color(0x" frontend/lib | grep -v app_colors.dart`. Kỳ vọng: chỉ còn `Color(0x08000000)`. `flutter analyze` (0 error), `flutter test` (PASS).
- [x] **Step 4: Kiểm tra bằng mắt.** Chạy app, mở 4 tab và màn Cài đặt. Thanh điều hướng dưới tô tím khi chọn. Không có màn nào mất chữ do trùng màu nền.
- [x] **Step 5: Commit.** `git commit -am "style(app): replace hardcoded colors with AppColors tokens"`

### Task 7 (tuỳ chọn, chỉ làm khi Task 1–6 đã xong và còn thời gian): Bỏ engine ghi bảng `Debt` không ai đọc

**Files:**
- Modify: `api/src/main/java/com/splitdebt/api/service/impl/ExpenseServiceImpl.java`: xoá field `settlementEngineService` và 3 lời gọi `recalculateGroupDebts(...)` (dòng ~81, ~315, ~333)
- Delete: `service/SettlementEngineService.java`, `service/impl/SettlementEngineServiceImpl.java`, `repository/DebtRepository.java`, `entity/Debt.java`
- Delete DTO chỉ engine dùng hoặc không ai dùng: `dto/response/DebtResponse.java`, `dto/response/NetBalanceResponse.java`, `dto/response/SimplifiedDebtResponse.java`, `dto/response/SettlementResponse.java`, `dto/request/CreateSettlementRequest.java`, `dto/request/UpdateSettlementStatusRequest.java`

- [x] **Step 1: Xác nhận.** Với mỗi class sắp xoá: `grep -rlw "<TênClass>" api/src` chỉ ra chính nó và các file cũng nằm trong danh sách xoá. Nếu không đúng thì dừng và báo lại.
- [x] **Step 2: Xoá và sửa** như phần Files. Không xoá bảng `debts` trong DB thật (Supabase), chỉ bỏ code.
- [x] **Step 3: Kiểm tra.** `.\mvnw.cmd test` (PASS, đặc biệt `GroupControllerTest` vẫn ra `totalToPay = 100000`).
- [x] **Step 4: Commit.** `git commit -am "refactor(api): remove write-only Debt engine and unused DTOs"`

---

## Hoàn tất

- [x] `cd api; .\mvnw.cmd test` PASS và `cd frontend; flutter analyze; flutter test` PASS. Dán output tóm tắt vào `docs/PROGRESS.md`.
- [x] Báo lại cho Claude Code để review toàn branch (tối đa 3 vòng review/sửa).
