# Nhắn tin trong nhóm (Group Chat) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Mỗi nhóm có kênh chat văn bản chung. Tin tới gần như tức thì khi đang mở màn chat, có push và số tin chưa đọc khi ở màn khác.

**Architecture:** Lưu tin trong PostgreSQL và cung cấp qua REST. Push dùng FCM (`sendToUserTopic` có sẵn). App nhận tin qua `onMessage` cộng `VisiblePoller` 5 giây. Gửi tin theo kiểu optimistic với `clientMessageId` để gửi lại không bị trùng.

**Tech Stack:** Spring Boot 3.3 / JPA / JUnit 5 + MockMvc + Mockito; Flutter / Riverpod 2.5 / Dio / flutter_test.

**Spec:** `docs/superpowers/specs/2026-11-25-group-chat-design.md`. **Đọc spec trước khi làm.** Các giá trị (giới hạn, chuỗi tiếng Việt, layout) lấy nguyên văn từ spec.

## Global Constraints

- Không thêm dependency (backend lẫn app). UUID tự viết bằng `Random.secure()`.
- Không đọc, sửa hay commit `.env`. **Không commit `frontend/android/gradle.properties`.** Không push.
- Chuỗi hiển thị tiếng Việt có dấu, viết hoa kiểu câu, không emoji, không dấu chấm than.
- App: màu, khoảng cách và bo góc chỉ lấy từ `AppColors`/`AppDimensions`. Widget và hàm có test thì lấy chữ từ `Theme.of(context).textTheme`, không dùng `AppTypography`/`GoogleFonts`.
- Mỗi task một commit. Cập nhật `docs/PROGRESS.md` sau mỗi task.
- Kiểm tra: `cd api; .\mvnw.cmd test` và `cd frontend; flutter analyze` (0 error) và `flutter test`.
- Plan hoặc spec mơ hồ, hoặc không khớp với code: dừng lại và hỏi.

## Review Focus

1. **Gửi khi mạng chập chờn rồi bấm Gửi lại:** chỉ có 1 tin trên server và 1 bong bóng trên màn (Task 1, Task 4).
2. **Push và poll trả cùng một tin gần như cùng lúc:** không bị trùng, không đảo thứ tự (Task 4).
3. **Đang cuộn đọc tin cũ thì có tin mới:** không bị kéo xuống, hiện nút "↓ Tin mới" (Task 5, kiểm tra bằng mắt).
4. **Đang mở chat nhóm X:** không hiện thông báo hay SnackBar cho tin của nhóm X, nhưng vẫn hiện cho nhóm Y (Task 5).
5. **Xoá nhóm có tin nhắn:** không lỗi khoá ngoại (Task 2).

---

### Task 1: Backend — lưu, gửi và lấy tin

**Files:**
- Create: `api/src/main/java/com/splitdebt/api/entity/GroupMessage.java`
- Create: `api/src/main/java/com/splitdebt/api/repository/GroupMessageRepository.java`
- Create: `api/src/main/java/com/splitdebt/api/dto/chat/MessageDto.java`, `SendMessageRequest.java`, `MessagePageDto.java`
- Create: `api/src/main/java/com/splitdebt/api/service/GroupChatService.java`
- Create: `api/src/main/java/com/splitdebt/api/controller/GroupChatController.java`
- Test: `api/src/test/java/com/splitdebt/api/controller/GroupChatControllerTest.java`

**Interfaces (Produces):**
```java
// GroupMessage extends BaseEntity: id, group (ManyToOne LAZY), sender (ManyToOne LAZY), content, clientMessageId
// @Table(indexes = @Index(columnList = "group_id,id"), uniqueConstraints = @UniqueConstraint(columnNames = {"sender_id","client_message_id"}))
public record MessageDto(Long id, Long groupId, Long senderId, String senderName, String content,
                         LocalDateTime createdAt, String clientMessageId) {}
public record SendMessageRequest(String content, String clientMessageId) {}
public record MessagePageDto(List<MessageDto> messages, boolean hasMore) {}

public class GroupChatService {
  MessagePageDto list(Long groupId, Long userId, Long before, Long after, Integer limit);
  SendResult send(Long groupId, Long userId, SendMessageRequest req);   // record SendResult(MessageDto message, boolean created)
}
// Controller: GET/POST /api/groups/{groupId}/messages; POST → 201 nếu created, 200 nếu trùng; bọc ApiResponse.
```

- [ ] **Step 1: Viết test thất bại.** Theo mẫu `SettingsSecurityTest`: `@SpringBootTest @AutoConfigureMockMvc @ActiveProfiles("test") @Transactional`, `@MockBean FcmPushService`, helper `newAccount()` và JWT. Tạo nhóm, thêm thành viên B.
```java
@Test void nonMember_cannotListOrSend()            // người lạ: GET và POST → 403
@Test void send_thenListLatest_ascendingOrder()     // gửi 3 tin → GET → $.data.messages[0..2].content đúng thứ tự gửi, id tăng dần
@Test void duplicateClientMessageId_isIdempotent()  // POST lần 1 → 201; lần 2 cùng clientMessageId → 200, cùng $.data.id; GET → 1 tin
@Test void blankOrTooLong_isRejected()              // "   " → 400; "a".repeat(2001) → 400; "😀".repeat(2000) → 201
@Test void invalidClientMessageId_isRejected()      // "abc" → 400
@Test void beforeAndAfterPaging()                   // gửi 35 tin; GET limit=30 → 30 tin cuối, hasMore=true;
                                                    // GET before=<id nhỏ nhất> → 5 tin, hasMore=false; GET after=<id tin thứ 33> → 2 tin
@Test void beforeAndAfterTogether_isRejected()      // → 400
@Test void limitIsCappedAt50()                      // gửi 60, GET limit=500 → 50 tin
```
- [ ] **Step 2: Chạy.** `.\mvnw.cmd test -Dtest=GroupChatControllerTest`. Kỳ vọng: FAIL hoặc không biên dịch được.
- [ ] **Step 3: Viết code** theo Interfaces và spec 5.1–5.2.
  - Repository dùng các query dẫn xuất (`findTop{N}ByGroupIdOrderByIdDesc` không cho N động, nên dùng `Pageable`): `findByGroupIdOrderByIdDesc(Long, Pageable)`, `findByGroupIdAndIdLessThanOrderByIdDesc(Long, Long, Pageable)`, `findByGroupIdAndIdGreaterThanOrderByIdAsc(Long, Long, Pageable)`, `findBySenderIdAndClientMessageId(Long, String)`.
  - Kết quả lấy theo thứ tự giảm dần thì đảo lại trước khi trả. `hasMore` tính bằng cách lấy `limit + 1` bản ghi.
  - Đếm độ dài bằng `codePointCount`. Kiểm tra UUID bằng `UUID.fromString` trong `try`.
  - Lỗi validate ném `IllegalArgumentException` (đã map sang 400). Kiểm tra quyền bằng `groupAccessService.requireActiveMember`.
- [ ] **Step 4: Chạy toàn bộ.** `.\mvnw.cmd test`. Kỳ vọng PASS.
- [ ] **Step 5: Commit.** `git add` các file mới và `git commit -m "feat(chat): store and serve group messages via REST"`

### Task 2: Backend — đánh dấu đã đọc, đếm tin chưa đọc, xoá nhóm

**Files:**
- Modify: `entity/GroupMember.java` (thêm `private Long lastReadMessageId;`)
- Modify: `GroupChatService`, `GroupChatController` (thêm `POST /messages/read`)
- Modify: `dto/GroupResponseDto.java` (thêm `private int unreadMessageCount;`), `service/impl/GroupServiceImpl.java` (`mapToGroupResponseDto` và các chỗ gọi nó trong luồng lấy danh sách và lấy chi tiết; `deleteGroup` xoá tin trước khi xoá thành viên)
- Modify: `GroupMessageRepository` (thêm `long countUnread(Long groupId, Long afterId, Long viewerId)` bằng `@Query`; `void deleteByGroupId(Long groupId)`)
- Test: `GroupChatControllerTest` (bổ sung)

**Interfaces (Produces):** `void markRead(Long groupId, Long userId, Long lastReadMessageId)`; JSON nhóm có thêm `unreadMessageCount`.

- [ ] **Step 1: Viết test thất bại.**
```java
@Test void unreadCount_excludesOwnMessages()     // A gửi 2, B gửi 1 → GET /api/groups (token A) → nhóm có unreadMessageCount == 1; token B → 2
@Test void markRead_resetsCount_andNeverMovesBack() // B read(id tin cuối) → 204, count B = 0; B read(id tin đầu) → 204, count B vẫn 0
@Test void markRead_foreignMessageId_isRejected() // id tin thuộc nhóm khác → 400
@Test void nonMember_cannotMarkRead()            // → 403
@Test void deleteGroupWithMessages_succeeds()    // gửi 2 tin, chủ nhóm DELETE /api/groups/{id} → 2xx
```
- [ ] **Step 2: Chạy.** Kỳ vọng FAIL. **Step 3:** Viết code. Với `afterId` là `null` thì dùng `0L`. **Step 4:** `.\mvnw.cmd test` PASS.
- [ ] **Step 5: Commit.** `git commit -am "feat(chat): read pointer, unread count, cleanup on group delete"` (nhớ `git add` nếu có file mới).

### Task 3: Backend — push tin mới và tuỳ chọn tắt

**Files:**
- Modify: `entity/UserSetting.java` (`notifyOnGroupMessage`, `@Builder.Default = true`, cột `notify_on_group_message`, `nullable = false`, `columnDefinition = "boolean default true"`), `dto/request/UserSettingRequest.java`, `dto/response/UserSettingResponse.java`, `service/impl/SettingServiceImpl.java` (update, map, default), `dto/UserPreferencesDto.java`, `controller/SettingsController.java` (map GET/PUT `/user/me`)
- Create: `api/src/main/java/com/splitdebt/api/service/GroupChatPushService.java`
- Modify: `GroupChatService.send` (chỉ gọi push khi `created == true`)
- Test: `api/src/test/java/com/splitdebt/api/service/GroupChatPushServiceTest.java` (Mockito thuần)

**Interfaces (Produces):** `void notifyNewMessage(GroupMessage saved)`: lấy thành viên ACTIVE của nhóm, bỏ người gửi, bỏ người có `notifyOnGroupMessage == false` (không có bản ghi `UserSetting` thì coi là bật), rồi `fcmPushService.sendToUserTopic(userId, groupName, body, data)` sau khi commit (dùng `TransactionSynchronization` giống `NotificationService`, không có transaction thì gửi ngay). `body` và `data` theo spec 5.3. Không gọi `NotificationRepository`.

- [ ] **Step 1: Viết test thất bại.**
```java
@Test void pushesToOtherActiveMembersOnly()     // nhóm có A (người gửi), B, C → push cho B và C, không push cho A
@Test void skipsMembersWhoOptedOut()            // C có notifyOnGroupMessage=false → chỉ B
@Test void bodyIsTruncatedTo100Chars()          // nội dung 300 ký tự → body.length() <= 100 và kết thúc bằng "…"
@Test void dataHasTypeGroupAndMessageIds()      // data.type=="GROUP_MESSAGE", groupId, messageId đúng
@Test void neverWritesNotificationTable()       // verifyNoInteractions(notificationRepository) (mock được inject nếu class có tham chiếu; nếu không có thì bỏ test này)
```
Thêm vào `GroupChatControllerTest`: `duplicateSend_doesNotPushTwice()`. Gửi 2 lần cùng `clientMessageId`, rồi `verify(fcmPushService, times(1)).sendToUserTopic(eq(bId), any(), any(), any())`.
- [ ] **Step 2: Chạy.** FAIL. **Step 3:** Viết code. **Step 4:** `.\mvnw.cmd test` PASS.
- [ ] **Step 5: Commit.** `git commit -am "feat(chat): push new messages with per-user opt-out"` (nhớ `git add` file mới).

### Task 4: App — tầng dữ liệu và logic chat (không có giao diện)

**Files (Create, tất cả trong `frontend/lib/features/chat/`):**
- `chat_models.dart`: `ChatMessage` (id `int?`, groupId, senderId, senderName, content, createdAt `DateTime`, clientMessageId, status `ChatStatus { sent, pending, failed }`, `fromJson`), `MessagePage`.
- `uuid.dart`: `String uuidV4()`.
- `chat_repository.dart`: `abstract class ChatRepository { Future<MessagePage> latest(int groupId); Future<MessagePage> before(int groupId, int id); Future<List<ChatMessage>> after(int groupId, int id); Future<ChatMessage> send(int groupId, String content, String clientMessageId); Future<void> markRead(int groupId, int lastId); }` và `DioChatRepository` (đọc `response.data['data']`).
- `chat_logic.dart`: hàm thuần `List<ChatMessage> mergeMessages(List<ChatMessage> current, List<ChatMessage> incoming)` và `List<ChatRow> buildChatRows(List<ChatMessage> messages, DateTime now, int myUserId)`. `ChatRow` là sealed class gồm `DayDividerRow(String label)` và `MessageRow(ChatMessage m, bool isMine, bool showSender)`.
- `chat_notifier.dart`: `ChatState { List<ChatMessage> messages; bool loadingInitial; bool loadingOlder; bool hasMore; String? error; }` và `class ChatNotifier extends StateNotifier<ChatState>` với `loadInitial()`, `loadOlder()`, `refreshNewer()`, `send(String text)`, `retry(String clientMessageId)`, `int? get newestServerId`. Provider `chatNotifierProvider` dùng `StateNotifierProvider.autoDispose.family<ChatNotifier, ChatState, int>` (tham số là groupId). Gán `state` sau `await` luôn kèm kiểm tra `mounted`.

**Quy tắc** (theo spec 5.4):
- **`mergeMessages`:** bỏ trùng theo `id`. Tin server có `clientMessageId` trùng với tin pending hoặc failed thì thay tin đó. Tin có id sắp tăng dần; tin pending và failed luôn nằm cuối, giữ thứ tự chèn.
- **`buildChatRows`:** chèn mốc ngày khi đổi ngày theo giờ máy ("Hôm nay", "Hôm qua", `dd/MM/yyyy`). `showSender` bằng `true` khi tin không phải của mình **và** (là tin đầu, hoặc người gửi khác tin trước, hoặc cách tin trước từ 5 phút trở lên, hoặc vừa qua một mốc ngày).
- **`refreshNewer`:** nếu đang chạy thì bỏ qua. Lỗi thì giữ nguyên dữ liệu.
- **`send`:** trim; rỗng thì không làm gì.

- [ ] **Step 1: Viết test thất bại** (`frontend/test/chat_logic_test.dart`, `frontend/test/chat_notifier_test.dart`, `FakeChatRepository` viết trong file test):
```dart
test('uuidV4 matches RFC 4122 v4 format')            // RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')
test('merge dedupes by id and sorts ascending')
test('merge replaces pending by clientMessageId and keeps pending last')
test('rows insert day dividers with Hôm nay / Hôm qua / dd/MM/yyyy')
test('rows show sender only at start of a 5-minute run from same person')
test('send success replaces pending with server message')
test('send failure marks failed; retry reuses the same clientMessageId')  // fake.sentIds == [x, x]
test('refreshNewer returning the same message as pending does not duplicate')
test('refreshNewer error keeps messages and sets no error')
test('loadOlder prepends and updates hasMore')
```
- [ ] **Step 2: Chạy.** `flutter test test/chat_logic_test.dart test/chat_notifier_test.dart`. Kỳ vọng FAIL.
- [ ] **Step 3: Viết code.** **Step 4:** PASS, `flutter analyze` 0 error.
- [ ] **Step 5: Commit.** `git add frontend/lib/features/chat frontend/test/chat_*` và `git commit -m "feat(chat): chat data layer, merge logic and notifier"`

### Task 5: App — màn chat, lối vào, badge, push

**Files:**
- Create: `frontend/lib/features/chat/group_chat_screen.dart`, `frontend/lib/features/chat/active_chat.dart` (`class ActiveChat { static int? groupId; }`)
- Modify: `frontend/lib/features/groups/screens/group_detail_screen.dart` (icon chat kèm badge trên AppBar)
- Modify: `frontend/lib/features/groups/models/group_model.dart` (`unreadMessageCount`, mặc định 0 khi thiếu)
- Modify: `frontend/lib/features/groups/widgets/group_card.dart` (badge), `frontend/lib/features/home/dashboard_screen.dart` (badge ở danh sách nhóm nếu dùng widget riêng)
- Modify: `frontend/lib/features/notifications/push_notification_service.dart` (bỏ qua foreground cho nhóm đang mở)
- Test: `frontend/test/model_contract_test.dart` (bổ sung `'group model reads unreadMessageCount and defaults to 0'`)

- [ ] **Step 1: Viết test** cho `GroupModel.fromJson` như trên, rồi sửa model.
- [ ] **Step 2: Viết `GroupChatScreen(group)`** theo layout ở spec 5.4:
  - `ref.watch(chatNotifierProvider(group.id))`, gọi `loadInitial()` ở `initState` (sau frame đầu).
  - `ListView.builder(reverse: true)` hiển thị `buildChatRows(...)` theo thứ tự đảo. Gần đầu danh sách (`extentAfter < 200`) thì gọi `loadOlder()`.
  - Theo dõi khoảng cách tới cuối danh sách. Có tin mới mà đang cách cuối từ 100px trở lên thì hiện nút "↓ Tin mới"; nếu không thì giữ ở cuối.
  - Ô nhập: `TextField(minLines: 1, maxLines: 5)` và nút gửi (khoá khi text sau trim rỗng). Gửi xong thì xoá ô nhập.
  - Tin pending hiện "Đang gửi". Tin failed hiện "Chưa gửi được · Gửi lại" màu `AppColors.error`, bấm vào thì `retry`.
  - `VisiblePoller(interval: Duration(seconds: 5), onTick: notifier.refreshNewer)` kèm `RouteAware`, giống `notification_screen.dart`. Khi bị che (`didPushNext`) thì `ActiveChat.groupId = null`; `didPopNext` thì gán lại.
  - `FirebaseMessaging.onMessage`: nếu `data['type'] == 'GROUP_MESSAGE' && data['groupId'] == '${group.id}'` thì `refreshNewer()`.
  - Đánh dấu đã đọc: mỗi khi `newestServerId` tăng thì `markRead` (gom trong 1 giây bằng `Timer`). Lỗi thì bỏ qua.
  - `dispose`: dừng poller, huỷ subscription, `ActiveChat.groupId = null`.
- [ ] **Step 3: Lối vào.** Thêm `IconButton` chat vào AppBar của `GroupDetailScreen`, kèm `Badge(isLabelVisible: count > 0, label: Text(count > 99 ? '99+' : '$count'))`. Khi quay về từ màn chat thì tải lại nhóm (dùng cùng cách màn đang làm để refresh, ví dụ `ref.read(userGroupsProvider.notifier)...`). `group_card.dart` cũng hiện badge.
- [ ] **Step 4: Push foreground.** Trong `_handleForegroundMessage`: nếu `type == 'GROUP_MESSAGE'` và `groupId == '${ActiveChat.groupId}'` thì `return`. Tin của nhóm khác hiện SnackBar như hiện tại.
- [ ] **Step 5: Kiểm tra.** `flutter analyze`, `flutter test` PASS. Chạy app trên 2 máy (hoặc máy thật + emulator) và đi qua 5 mục Review Focus.
- [ ] **Step 6: Commit.** `git add` và `git commit -m "feat(chat): group chat screen, entry point, unread badges, push routing"`

### Task 6: App — công tắc "Tin nhắn nhóm"

**Files:**
- Modify: `frontend/lib/features/profile/user_preferences.dart` (`notifyOnGroupMessage`, `fromJson` mặc định `true`, `toJson`, `copyWith`, setter `Future<bool?> setNotifyOnGroupMessage(bool v)` theo đúng mẫu hai setter hiện có)
- Modify: `frontend/lib/features/profile/notification_settings_screen.dart` (thêm `GroupedSwitchTile` thứ ba: icon `Icons.chat_bubble_outline`, "Tin nhắn nhóm", "Khi có tin nhắn mới trong nhóm")
- Test: `frontend/test/user_preferences_test.dart` (bổ sung)

- [ ] **Step 1: Viết test.** `'fromJson defaults notifyOnGroupMessage to true'`, `'setNotifyOnGroupMessage persists'`. **Step 2:** FAIL. **Step 3:** Viết code. **Step 4:** PASS.
- [ ] **Step 5: Commit.** `git commit -am "feat(chat): notification toggle for group messages"`

---

## Hoàn tất

- [ ] `cd api; .\mvnw.cmd test` và `cd frontend; flutter analyze; flutter test` đều PASS.
- [ ] Đi qua phần kiểm thử thủ công ở spec mục 6 trên 2 máy.
- [ ] Cập nhật `docs/PROGRESS.md`, báo lại danh sách commit và những chỗ đã phải hỏi hoặc làm khác plan.
