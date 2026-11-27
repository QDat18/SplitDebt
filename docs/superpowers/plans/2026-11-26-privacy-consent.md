# Quyền riêng tư, sự đồng ý & quyền thiết bị — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** App tuân thủ Luật Bảo vệ dữ liệu cá nhân 91/2025/QH15 và Nghị định 356/2025/NĐ-CP, cùng yêu cầu của hai store, ở các điểm sau: đồng ý chủ động và có bằng chứng, đồng ý theo từng mục đích, đồng ý lại khi văn bản đổi, xin quyền thiết bị đúng ngữ cảnh, xem dữ liệu của mình, xoá tài khoản.

**Architecture:** Bảng log chỉ thêm `user_consents` cùng phiên bản văn bản lấy từ cấu hình. Một filter trả 428 khi người dùng chưa đồng ý lại. Có endpoint xem dữ liệu và endpoint xoá tài khoản (ẩn danh hoá, giữ sổ nợ chung). Ở app: checkbox khi đăng ký, màn đồng ý lại, màn giải thích trước khi xin quyền, Trung tâm Quyền riêng tư.

**Tech Stack:** Spring Boot 3.3 / JPA / MockMvc / Mockito; Flutter / Riverpod 2.5 / Dio / shared_preferences / flutter_test.

> **Cập nhật 2026-11-26:** OCR chạy hoàn toàn trên máy, nên **bỏ `RECEIPT_AI`**: Task 5 bị huỷ, Task 9 không còn sheet đồng ý cho OCR, Trung tâm Quyền riêng tư không còn mục đồng ý tuỳ chọn. Giữ nguyên số thứ tự các task để dễ đối chiếu.

**Spec:** `docs/superpowers/specs/2026-11-26-privacy-consent-design.md`. **Bắt buộc đọc toàn bộ spec trước.** Chuỗi tiếng Việt, mã lỗi, route và quy tắc lấy **nguyên văn** từ spec.

## Global Constraints

- **Không thêm dependency** ở cả backend lẫn app.
- Không đọc, sửa hay commit `.env`. **Không commit `frontend/android/gradle.properties`.** Không push.
- **`user_consents` chỉ được thêm bản ghi.** Không viết code nào gọi update hay delete trên bảng này.
- App: màu, khoảng cách và bo góc lấy từ `AppColors`/`AppDimensions`. Màn mới dùng `GroupedSection`/`GroupedTile`. Widget có test lấy chữ từ `Theme.of(context).textTheme`.
- Chuỗi hiển thị tiếng Việt có dấu, viết hoa kiểu câu, không emoji, không dấu chấm than.
- Mỗi task một commit. Cập nhật `docs/PROGRESS.md` sau mỗi task.
- Kiểm tra: `cd api; .\mvnw.cmd test` và `cd frontend; flutter analyze` (0 error) và `flutter test`.
- **Khi sửa các test cũ đang gọi `/api/auth/register`** (vì request giờ bắt buộc có `consents`), chỉ được thêm khối `consents`, không được nới lỏng validation để test cũ pass.
- Plan hoặc spec mơ hồ, hoặc không khớp với code: dừng lại và hỏi.

## Review Focus

1. **Người dùng cũ** (chưa có bản ghi đồng ý) cập nhật app: bị chặn ở màn đồng ý lại, không crash, không vòng lặp điều hướng (Task 2, Task 7).
2. **Xoá tài khoản khi là OWNER** của nhóm có người khác: nhóm còn nguyên, OWNER mới đúng, số dư của người khác không đổi (Task 4).
3. **Đồng ý lại 2 lần liên tiếp** (2 phiên bản văn bản): có đủ các bản ghi, không bản cũ nào bị sửa (Task 1).
4. **Cài mới:** không hộp thoại xin quyền nào xuất hiện trước khi đăng nhập (Task 8).
5. **Trên web:** sheet thông báo và trạng thái quyền không crash. `FirebaseMessaging.isSupported()` trả `false` thì ẩn phần thông báo (Task 8, Task 9).

---

### Task 1: Backend — log đồng ý, đăng ký có đồng ý, trạng thái và cập nhật đồng ý

**Files:**
- Create: `entity/UserConsent.java`, `entity/enums/ConsentType.java` (`TERMS, PRIVACY, AGE_16`), `entity/enums/ConsentSource.java` (`REGISTER, RECONSENT`)
- Create: `repository/UserConsentRepository.java` (`Optional<UserConsent> findFirstByUserIdAndConsentTypeOrderByIdDesc(Long, ConsentType)`, `List<UserConsent> findByUserIdOrderByIdAsc(Long)`)
- Create: `config/LegalProperties.java` (`@ConfigurationProperties("app.legal")`: `termsVersion`, `privacyVersion`); Modify `application.yaml` theo spec 5.1
- Create: `service/ConsentService.java`, `dto/consent/*` (`RegisterConsentsDto`, `ConsentStatusDto`, `ConsentUpdateRequest`, `ConsentItemDto`)
- Modify: `dto/RegisterRequest.java` (thêm `consents`, `platform`, `appVersion`), `service/AuthService.java` (validate rồi ghi 3 bản ghi trong cùng transaction), `dto/UserDto.java` + `controller/UserController.java` (`consent` trong `/me`; `POST /me/consents`)
- Modify: các test cũ có gọi register (thêm khối `consents` hợp lệ)
- Test: `api/src/test/java/com/splitdebt/api/controller/ConsentControllerTest.java`

**Interfaces (Produces):**
```java
public class ConsentService {
  void recordRegistration(User user, RegisterConsentsDto c, String platform, String appVersion); // ném IllegalArgumentException theo spec 5.3
  ConsentStatusDto status(Long userId);          // termsVersion, privacyVersion, reconsentRequired, acceptedAt
  ConsentStatusDto update(Long userId, ConsentUpdateRequest req);
  boolean reconsentRequired(Long userId);
}
```

- [ ] **Step 1: Viết test thất bại.**
```java
@Test void register_withoutConsents_is400()
@Test void register_ageNotConfirmed_is400()
@Test void register_staleVersion_is400()           // termsVersion "2000-01-01" → 400, message chứa "Văn bản đã được cập nhật"
@Test void register_valid_creates3ConsentRecords()  // 201; repo có TERMS, PRIVACY, AGE_16 granted=true, source=REGISTER, đúng version/platform
@Test void me_returnsConsentBlock()                 // $.consent.reconsentRequired == false; $.consent.acceptedAt != null
@Test void legacyUserWithoutRecords_requiresReconsent() // tạo User trực tiếp bằng repository → /me: reconsentRequired == true
@Test void withdrawRequiredConsent_is400()          // POST /me/consents TERMS granted=false → 400 "Để rút lại đồng ý bắt buộc, hãy xoá tài khoản."
@Test void reconsentTwice_appendsRecords()          // đồng ý phiên bản A rồi B (đổi LegalProperties trong test) → bản ghi của A vẫn nguyên, có thêm bản ghi B
@Test void reconsent_clearsFlag()                    // user cũ gửi TERMS+PRIVACY version hiện hành → reconsentRequired == false
```
- [ ] **Step 2: Chạy.** `.\mvnw.cmd test -Dtest=ConsentControllerTest`. Kỳ vọng FAIL.
- [ ] **Step 3: Viết code.** Thêm `@EnableConfigurationProperties(LegalProperties.class)` vào cấu hình. Sửa các test cũ đang gọi register.
- [ ] **Step 4: Chạy toàn bộ.** `.\mvnw.cmd test`. Kỳ vọng PASS.
- [ ] **Step 5: Commit.** `git add` và `git commit -m "feat(privacy): append-only consent log, consent on register, consent status API"`

### Task 2: Backend — chặn API nghiệp vụ khi cần đồng ý lại (428)

**Files:**
- Create: `security/ReconsentFilter.java` (`OncePerRequestFilter`, đăng ký trong `SecurityConfig` **sau** `JwtAuthenticationFilter`)
- Modify: `security/SecurityConfig.java`, `ConsentService` (cache 60 giây theo userId bằng `ConcurrentHashMap<Long, CachedFlag>`, xoá cache trong `update`)
- Test: `ConsentControllerTest` (bổ sung)

Danh sách route được miễn lấy **nguyên văn** từ spec 5.3. Body của 428: `ApiResponse.error(428, "Bạn cần đồng ý điều khoản mới để tiếp tục.")` kèm trường `code: "RECONSENT_REQUIRED"`. Nếu `ApiResponse` không có chỗ cho `code` thì ghi JSON `{"status":428,"code":"RECONSENT_REQUIRED","message":"..."}` trực tiếp từ filter.

- [ ] **Step 1: Viết test.**
```java
@Test void legacyUser_businessApi_is428()        // GET /api/groups → 428, $.code == "RECONSENT_REQUIRED"
@Test void legacyUser_exemptRoutes_pass()         // GET /api/users/me → 200; GET /api/users/me/data-export → 200 (sau Task 3; tạm thời chỉ kiểm tra /me)
@Test void afterReconsent_businessApi_passes()   // gửi đồng ý → GET /api/groups → 200
@Test void unauthenticated_isStill401()           // không token → 401 (filter không đổi hành vi này)
```
- [ ] **Step 2: FAIL. Step 3: Viết code. Step 4:** `.\mvnw.cmd test` PASS.
- [ ] **Step 5: Commit.** `git commit -m "feat(privacy): block business APIs with 428 until re-consent"`

### Task 3: Backend — xem dữ liệu của tôi

**Files:**
- Create: `service/DataExportService.java`, `dto/privacy/DataExportDto.java`
- Modify: `UserController` (`GET /me/data-export`)
- Test: `api/src/test/java/com/splitdebt/api/controller/DataExportControllerTest.java`

Nội dung đúng theo spec 5.3. Dùng các repository sẵn có. Nếu repository chưa có query cần thiết thì thêm query dẫn xuất.

- [ ] **Step 1: Viết test.**
```java
@Test void export_containsOwnData()          // A có 1 nhóm, 1 khoản chi, 1 tin nhắn → $.data.groups.length()==1, expenses ≥1, messages ≥1, consents ≥3
@Test void export_excludesSecrets()          // response body không chứa "passwordHash", không chứa "token"
@Test void export_excludesOthersMessages()   // B nhắn trong cùng nhóm → messages của A không có nội dung của B
@Test void export_requiresAuth()             // không token → 401
```
Bổ sung vào Task 2: `legacyUser_exemptRoutes_pass` kiểm tra `data-export` trả 200.
- [ ] **Step 2–4:** FAIL, viết code, PASS.
- [ ] **Step 5: Commit.** `git commit -m "feat(privacy): personal data export endpoint"`

### Task 4: Backend — xoá tài khoản

**Files:**
- Modify: `entity/User.java` (`LocalDateTime deletedAt`)
- Create: `service/AccountDeletionService.java`, `dto/privacy/DeletionRequest.java`, `exception/OutstandingBalanceException.java` (409, mang danh sách nhóm) cùng handler trong `GlobalExceptionHandler`
- Modify: `UserController` (`POST /me/deletion`); `AuthService.login` (user có `deletedAt != null` → sai thông tin, như email không tồn tại); `GroupServiceImpl.addGroupMember` (từ chối user đã xoá: 404 "Không tìm thấy người dùng")
- Modify (nếu cần): `SupabaseStorageServiceImpl` (thêm `deleteObject(String url)`, xoá sau khi commit, lỗi thì chỉ log)
- Test: `api/src/test/java/com/splitdebt/api/controller/AccountDeletionControllerTest.java` (`@MockBean` cho storage service)

**Interfaces:** `void deleteAccount(Long userId, String rawPassword)`. Các bước theo đúng thứ tự ở spec 5.3, bước 1 → 5, trong một transaction.

- [ ] **Step 1: Viết test.**
```java
@Test void wrongPassword_is400()  // 400, code WRONG_PASSWORD
@Test void outstandingBalance_is409WithGroups()   // A nợ B 100000 → 409, $.data.groups[0].name đúng (hoặc trường tương ứng theo handler)
@Test void success_anonymizesAndBlocksLogin()      // hết nợ → 204; /api/auth/login bằng email cũ → 401; user.fullName == "Người dùng đã xoá"; email kết thúc "@deleted.invalid"; phone/avatarUrl null; deletedAt != null
@Test void ownerTransfer_toEarliestAdminOrMember() // A OWNER, B ADMIN (tham gia sau C MEMBER) → OWNER mới là B; không có ADMIN → C
@Test void soleOwnerGroup_isDeleted()             // nhóm chỉ có A → nhóm bị xoá
@Test void sharedExpensesKept_balancesUnchanged()  // nhóm A,B,C đã cân bằng với A; sau khi A xoá: GET /api/v1/expenses/group/{id} (token B) vẫn còn khoản chi; số dư của B và C như trước
@Test void messagesRedacted_consentsKept()         // tin của A có content "Tin nhắn đã bị xoá"; user_consents của A vẫn còn
@Test void personalTablesCleared()                 // FCM token, UserSetting, Notification, UserActivityLog của A = 0
@Test void oldJwt_rejected()                       // token cũ của A gọi GET /api/users/me → 401
```
- [ ] **Step 2–4:** FAIL, viết code, `.\mvnw.cmd test` PASS.
- [ ] **Step 5: Commit.** `git commit -m "feat(privacy): account deletion with anonymization and owner transfer"`

### Task 5: ~~Backend — OCR phải có đồng ý `RECEIPT_AI`~~ (đã huỷ)

OCR xử lý hoàn toàn trên máy, không có endpoint. Không làm gì ở task này.

### Task 6: Văn bản pháp lý

**Files (Create):** `docs/legal/privacy-policy.md`, `docs/legal/terms.md`, `docs/legal/account-deletion.md`, `docs/legal/store-checklist.md`

- [ ] **Step 1:** Viết đủ các mục **đúng như liệt kê ở spec mục 7 và mục 9**. Đầu mỗi file ghi `Phiên bản: 2026-11-26` và `Hiệu lực từ: [CẦN ĐIỀN]`. Chưa biết thông tin thì để `[CẦN ĐIỀN]`. **Không trích số điều khoản cụ thể.** Câu ngắn, dễ hiểu.
- [ ] **Step 2:** Tự kiểm tra: mọi bên nhận dữ liệu ở spec mục 2 đều có trong mục 4 của chính sách, và mọi quyền ở mục 6 đều chỉ ra được nơi thực hiện trong app (màn hình nào).
- [ ] **Step 3: Commit.** `git add docs/legal && git commit -m "docs(legal): privacy policy, terms, account deletion page, store checklist (draft)"`

### Task 7: App — văn bản trong app, đăng ký có đồng ý, màn đồng ý lại

**Files:**
- Create: `frontend/lib/features/legal/legal_texts.dart` (`kTermsVersion`, `kPrivacyVersion` = `'2026-11-26'`, `kLegalChangeSummary`, `LegalSection`, nội dung chuyển từ `docs/legal/privacy-policy.md` và `terms.md`)
- Create: `frontend/lib/features/legal/legal_document_screen.dart`, `frontend/lib/features/legal/reconsent_screen.dart`, `frontend/lib/features/legal/consent_models.dart` (`ConsentStatus.fromJson`)
- Create: `frontend/lib/features/auth/register_consent_state.dart` (`class RegisterConsentState { bool terms, privacy, age; bool get canSubmit; RegisterConsentState copyWith(...); }`)
- Modify: `frontend/lib/features/auth/register_screen.dart`, `frontend/lib/data/repositories/auth_repository.dart` (gửi `consents`, `platform`, `appVersion`; `appVersion` lấy từ hằng trong `app_constants.dart`, không thêm package)
- Modify: `frontend/lib/core/network/dio_client.dart` (interceptor: response 428 có `code == RECONSENT_REQUIRED` thì gọi `onReconsentRequired` do app gán)
- Modify: luồng sau đăng nhập (splash hoặc auth provider): `/users/me` có `reconsentRequired == true` thì `pushAndRemoveUntil(ReconsentScreen)`
- Test: `frontend/test/register_consent_state_test.dart`, `frontend/test/consent_models_test.dart`

- [ ] **Step 1: Viết test.**
```dart
test('cannot submit until all three boxes are checked')   // mặc định false; tích 2 → false; tích 3 → true
test('initial state has nothing pre-checked')
test('ConsentStatus parses reconsentRequired and acceptedAt')   // acceptedAt null → null; chuỗi ISO → DateTime
```
- [ ] **Step 2–3: FAIL, viết code.** Giao diện theo spec 6.2 và 6.3. Link trong checkbox mở `LegalDocumentScreen`. Interceptor chỉ điều hướng 1 lần (có cờ chống lặp). `ReconsentScreen` gọi `POST /users/me/consents` với `source: RECONSENT`, thành công thì về `MainLayoutScreen`.
- [ ] **Step 4:** `flutter analyze`, `flutter test` PASS. Chạy app: đăng ký mới, rồi giả lập user cũ bằng cách đổi `LEGAL_PRIVACY_VERSION` ở backend.
- [ ] **Step 5: Commit.** `git commit -m "feat(privacy): consent on sign-up, legal screens, re-consent gate"` (nhớ `git add` file mới).

### Task 8: App — xin quyền thông báo đúng ngữ cảnh

**Files:**
- Modify: `frontend/lib/features/notifications/push_notification_service.dart` (bỏ `requestPermission` trong `initialize`; thêm `requestPermissionWithRationale(BuildContext)`, `currentStatus()`)
- Create: `frontend/lib/features/notifications/notification_prompt_policy.dart` (`bool shouldPromptNotifications({required int count, required DateTime? last, required DateTime now})`)
- Create: `frontend/lib/features/notifications/notification_rationale_sheet.dart`
- Modify: `frontend/lib/features/home/dashboard_screen.dart` (sau frame đầu: chưa được cấp quyền và policy cho phép thì hiện sheet; cập nhật `notif_prompt_count` và `notif_prompt_last` trong SharedPreferences)
- Modify: `frontend/ios/Runner/Info.plist` (câu mô tả camera và ảnh **đúng chữ trong spec 6.4**, nếu chưa có hoặc khác thì thống nhất lại)
- Test: `frontend/test/notification_prompt_policy_test.dart`

- [ ] **Step 1: Viết test.**
```dart
test('prompts on first time')                 // count 0, last null → true
test('waits 7 days after "Để sau"')           // count 1, last = now - 6 ngày → false; now - 7 ngày → true
test('never more than twice')                 // count 2 → false
```
- [ ] **Step 2–3: FAIL, viết code.** Sheet theo spec 6.4. Nếu quyền đã `authorized` thì không hiện. Web không hỗ trợ (`isSupported() == false`) thì không hiện.
- [ ] **Step 4:** PASS. Chạy app trên máy Android 13+ cài mới: không có hộp thoại xin quyền trước khi đăng nhập; sheet hiện ở Trang chủ; bấm "Để sau" thì không hỏi lại ngay.
- [ ] **Step 5: Commit.** `git commit -m "feat(privacy): contextual notification permission with rationale"` (nhớ `git add`).

### Task 9: App — Trung tâm Quyền riêng tư, xem dữ liệu, xoá tài khoản

**Files:**
- Create: `frontend/lib/features/privacy/privacy_center_screen.dart`, `data_export_screen.dart`, `delete_account_flow.dart` (màn giải thích, nhập mật khẩu, xác nhận, kết quả), `privacy_repository.dart` (`exportData()`, `deleteAccount(password)` ném `OutstandingBalanceError(groups)` hoặc `WrongPasswordError`)
- Modify: `frontend/lib/features/profile/profile_screen.dart` (hàng "Quyền riêng tư" trong section Tài khoản)
- Test: `frontend/test/privacy_repository_test.dart` (Dio giả bằng `HttpClientAdapter` tự viết, hoặc tách hàm parse thuần để test)

- [ ] **Step 1: Viết test.**
```dart
test('deleteAccount maps 409 to OutstandingBalanceError with group list')
test('deleteAccount maps 400 WRONG_PASSWORD to WrongPasswordError')
test('deleteAccount 204 completes normally')
```
- [ ] **Step 2–3: FAIL, viết code.** Bố cục **đúng như sơ đồ ở spec 6.5**. Footer phần Văn bản lấy ngày đồng ý từ `consent.acceptedAt`. Xoá thành công thì xoá token, huỷ đăng ký topic FCM (dùng hàm logout và cleanup push có sẵn), về `LoginScreen` kèm SnackBar.
- [ ] **Step 4:** `flutter analyze`, `flutter test` PASS. Chạy app và đi qua phần kiểm thử thủ công ở spec mục 8.
- [ ] **Step 5: Commit.** `git commit -m "feat(privacy): privacy center, data view, account deletion"` (nhớ `git add`).

---

## Hoàn tất

- [ ] `cd api; .\mvnw.cmd test` và `cd frontend; flutter analyze; flutter test` đều PASS.
- [ ] `grep -rn "RECEIPT_AI\|DeepSeek" api/src frontend/lib docs/legal` phải không có kết quả.
- [ ] Đi qua toàn bộ phần kiểm thử thủ công ở spec mục 8. Ghi kết quả vào `docs/PROGRESS.md`.
- [ ] Liệt kê mọi chỗ `[CẦN ĐIỀN]` còn lại trong `docs/legal/` để chủ dự án điền.
- [ ] Báo lại danh sách commit và những chỗ đã phải hỏi hoặc làm khác plan.
