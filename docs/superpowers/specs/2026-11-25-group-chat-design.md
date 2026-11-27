# Thiết kế: Nhắn tin trong nhóm (Group Chat)

**Ngày:** 2026-11-25 · **Trạng thái:** chờ duyệt · **Phương án đã chọn:** A (REST + FCM + polling)

## 1. Mục đích

Mỗi nhóm chi tiêu có một kênh chat chung để các thành viên nói chuyện ngay trong app, không phải chuyển qua Zalo hay Messenger.

Thành công khi: demo trên hai điện thoại, người A gửi tin thì máy B đang mở màn chat thấy tin trong khoảng 1 giây. Nếu B đang ở màn khác hoặc app ở nền, B nhận thông báo "Tên: nội dung" và thấy số tin chưa đọc trên nhóm.

## 2. Mục tiêu / Không làm / Thất bại dù chạy được

**Mục tiêu**
- Gửi và nhận tin văn bản trong nhóm. Xem lịch sử, cuộn lên để tải tin cũ hơn.
- Có số tin chưa đọc cho từng nhóm (trên thẻ nhóm và trên nút chat).
- Push khi có tin mới, tắt được trong màn Thông báo.
- Chạy trên Android, iOS và web, dùng chung code.

**Không làm (lần này)**
- Không có trạng thái "đang gõ…" hay "đã xem" của từng người.
- Không gửi ảnh, file, emoji reaction. Không sửa hay xoá tin.
- Không chat 1-1. Không gắn tin với khoản chi hay thanh toán.
- Không dùng WebSocket.

**Thất bại dù chạy được**
- Người không thuộc nhóm (hoặc đã rời nhóm) đọc hoặc gửi được tin.
- Bấm gửi khi mạng chập chờn tạo ra 2 tin trùng nhau.
- Tin mất hoặc nhảy lộn thứ tự khi push và poll về cùng lúc.
- Người đang mở đúng màn chat vẫn bị hiện thông báo hoặc SnackBar cho tin của chính nhóm đó.
- Tin chat tràn vào hộp thư Thông báo, che mất thông báo nghiệp vụ (yêu cầu thanh toán và các loại khác).
- Màn chat nháy spinner hoặc nhảy vị trí cuộn mỗi lần poll (lỗi từng gặp ở màn quyết toán).

## 3. Ràng buộc

- Spring Boot 3.3, JPA với `ddl-auto: update` (thêm bảng và cột tự động). Flutter, Riverpod 2.5, Dio.
- Dùng lại: `GroupAccessService.requireActiveMember`, `FcmPushService.sendToUserTopic`, `VisiblePoller` + `appRouteObserver`, `UserSetting`/`UserPreferences`, widget HIG trong `core/widgets/grouped_list.dart` và `AppColors`.
- Không thêm dependency ở cả backend lẫn app.
- `deleteGroup` hiện xoá tay `GroupMember` rồi mới xoá `Group`. Tin nhắn cũng phải được xoá trước.

## 4. Các phương án đã cân nhắc

| Phương án | Ưu | Nhược | Kết luận |
|---|---|---|---|
| **A. REST + FCM + polling** | Dùng lại hạ tầng có sẵn, chạy được trên mọi hosting, dễ test | Không có "đang gõ…"; push trễ thì tin chậm vài giây | **Đã chọn** |
| B. WebSocket (STOMP) | Thời gian thực đúng nghĩa | Xác thực JWT cho socket, tự xử lý kết nối lại, hosting miễn phí hay cắt kết nối, code gấp đôi | Loại |
| C. Firestore | Có sẵn thời gian thực và offline | Phải cấp custom token, đồng bộ thành viên sang Firestore, dữ liệu chia hai nơi | Loại |

API ở mục 5.2 không phụ thuộc cách vận chuyển, nên sau này có thể thêm WebSocket mà không phải đổi API.

## 5. Thiết kế

### 5.1 Dữ liệu

**Bảng `group_messages`** (entity `GroupMessage`, kế thừa `BaseEntity` để có `createdAt`):

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `id` | bigint, tự tăng | Dùng làm con trỏ phân trang và thứ tự tin |
| `group_id` | FK → groups, not null | index (`group_id`, `id`) |
| `sender_id` | FK → users, not null | |
| `content` | text, not null | đã trim, 1–2000 code point |
| `client_message_id` | varchar(36), not null | UUID do app sinh; unique (`sender_id`, `client_message_id`) |

**`GroupMember`** thêm cột `last_read_message_id` (bigint, nullable). `null` nghĩa là chưa đọc tin nào.

**`UserSetting`** thêm cột `notify_on_group_message` (boolean, not null, mặc định `true`).

### 5.2 API (mọi route đều cần JWT và `requireActiveMember(groupId, currentUserId)`)

**Lấy tin:** `GET /api/groups/{groupId}/messages`
- `?limit=30` (mặc định 30, tối đa 50): lấy các tin mới nhất.
- `?before={id}&limit=30`: lấy tin cũ hơn `id`, dùng khi cuộn lên.
- `?after={id}`: lấy tin mới hơn `id`, tối đa 100, dùng khi poll hoặc khi nhận push.
- `before` và `after` không được dùng cùng lúc (trả 400).
- Response theo envelope `ApiResponse`: `{ "messages": [MessageDto…], "hasMore": bool }`. `messages` **luôn được sắp tăng dần theo `id`**. `hasMore` chỉ có nghĩa với kiểu lấy mới nhất và kiểu `before`.

**`MessageDto`:** `{ id, groupId, senderId, senderName, content, createdAt, clientMessageId }`

**Gửi tin:** `POST /api/groups/{groupId}/messages`, body `{ "content": "...", "clientMessageId": "uuid" }`
- Thành công trả **201** cùng `MessageDto`.
- Gửi lại cùng `clientMessageId` từ cùng người gửi: trả **200** cùng tin đã có. Không tạo tin mới và không push lại (idempotent).
- Lỗi 400 (thông báo tiếng Việt):
  - nội dung rỗng sau khi trim → "Tin nhắn không được để trống";
  - dài hơn 2000 code point → "Tin nhắn tối đa 2000 ký tự";
  - `clientMessageId` thiếu hoặc không phải UUID.

**Đánh dấu đã đọc:** `POST /api/groups/{groupId}/messages/read`, body `{ "lastReadMessageId": 123 }` → **204**.
- Chỉ tăng chứ không giảm: nếu giá trị nhỏ hơn hoặc bằng giá trị hiện có thì bỏ qua.
- Nếu id không thuộc nhóm thì trả 400.

**Số tin chưa đọc:** `GroupResponseDto` thêm `unreadMessageCount` (int). Công thức: số tin của nhóm có `id > lastReadMessageId` (hoặc toàn bộ nếu `null`) **và** `sender_id ≠ người xem`. Trả về ở `GET /api/groups` và `GET /api/groups/{id}`.

### 5.3 Push

Sau khi lưu tin mới (không áp dụng cho request lặp lại), gửi push cho **từng thành viên ACTIVE khác người gửi** có `notifyOnGroupMessage = true`. Push chạy sau khi transaction commit, giống `NotificationService`.
- `title`: tên nhóm.
- `body`: `"<Tên người gửi>: <nội dung>"`, cắt còn 100 ký tự kèm "…".
- `data`: `{ type: "GROUP_MESSAGE", groupId, messageId }`.
- **Không** lưu vào bảng `Notification`, nên tin chat không vào hộp thư Thông báo.

### 5.4 App

**Lối vào:** trên AppBar của `GroupDetailScreen` có icon chat (`Icons.chat_bubble_outline`), kèm badge số tin chưa đọc (ẩn khi bằng 0, hiển thị "99+" khi lớn hơn 99). Bấm vào thì mở `GroupChatScreen(group)`. Thẻ nhóm ở tab Nhóm và ở Trang chủ cũng hiện badge này.

**Màn chat (HIG):**
```
┌ ‹  Du lịch Đà Lạt          ┐
│        Hôm qua             │  ← mốc ngày, cỡ 13, n600, căn giữa
│ Lan                        │  ← tên người gửi, chỉ ở tin đầu của một chuỗi
│ ┌──────────────┐           │
│ │ Mai mấy giờ? │ 21:04     │  ← bong bóng người khác: nền n100, bo 18
│ └──────────────┘           │
│        Hôm nay             │
│           ┌─────────────┐  │
│     08:12 │ 7h nhé      │  │  ← bong bóng của mình: nền p500, chữ trắng
│           └─────────────┘  │
│        ⏱ đang gửi          │  ← tin đang chờ
│        ⚠ Chưa gửi được · Gửi lại │  ← tin lỗi, màu error
├────────────────────────────┤
│ [ Nhắn tin…            ] ➤ │  ← TextField 1–5 dòng; nút gửi khoá khi rỗng
└────────────────────────────┘
```
- "Chuỗi" là các tin liên tiếp của cùng một người, cách nhau dưới 5 phút. Trong một chuỗi chỉ hiện tên người gửi ở tin đầu.
- Mốc ngày hiển thị "Hôm nay", "Hôm qua" hoặc `dd/MM/yyyy`. Giờ hiển thị `HH:mm` theo giờ máy.
- Danh sách dùng `ListView(reverse: true)`: tin mới nằm dưới cùng, bàn phím mở thì không làm nhảy vị trí cuộn.
- Cuộn tới gần đầu danh sách (còn 200px) thì tải trang `before`. Trong lúc tải hiện một spinner nhỏ ở đầu danh sách.
- **Tin mới chỉ tự cuộn xuống** khi người dùng đang ở cuối danh sách (cách cuối dưới 100px) hoặc khi tin do chính mình gửi. Nếu đang cuộn đọc tin cũ thì hiện nút "↓ Tin mới" thay vì tự cuộn.
- Màn trống: "Chưa có tin nhắn. Hãy bắt đầu cuộc trò chuyện."

**Gửi tin (optimistic):**
1. Sinh `clientMessageId` (UUID v4, tự viết bằng `Random.secure()`, không thêm package).
2. Chèn ngay vào danh sách một tin có trạng thái `pending`, xoá ô nhập.
3. Gọi POST. Thành công thì thay tin pending bằng tin từ server (khớp theo `clientMessageId`). Lỗi thì chuyển trạng thái thành `failed`.
4. Bấm "Gửi lại" thì gửi lại với **cùng** `clientMessageId`.

**Nhận tin:**
- `VisiblePoller(interval: 5s)` gọi `after = id lớn nhất đã có từ server`. Poller dùng `appRouteObserver` để dừng khi màn bị che.
- `FirebaseMessaging.onMessage` với `type == GROUP_MESSAGE` và đúng `groupId` thì tải `after` ngay.
- Mọi kết quả đều đi qua hàm gộp: bỏ trùng theo `id` và `clientMessageId`, sắp theo `id`, tin pending/failed luôn nằm sau cùng.
- **Làm mới âm thầm:** spinner toàn màn chỉ hiện ở lần tải đầu khi chưa có dữ liệu. Poll lỗi thì giữ nguyên dữ liệu.

**Đánh dấu đã đọc:** khi màn chat đang hiển thị và có tin mới nhất từ server, gọi `read` với id đó. Gom nhiều lần gọi trong 1 giây thành 1, và chỉ gọi khi id tăng lên. Khi rời màn, tải lại danh sách nhóm để badge cập nhật.

**Không hiện thông báo cho nhóm đang mở:** giữ `ActiveChat.groupId` (static, gán khi vào màn chat, xoá khi rời hoặc khi màn bị che). `push_notification_service.dart` bỏ qua SnackBar foreground khi `type == GROUP_MESSAGE && groupId == ActiveChat.groupId`.

**Cài đặt:** màn Thông báo thêm một công tắc "Tin nhắn nhóm" (phụ đề "Khi có tin nhắn mới trong nhóm"). `UserPreferences` thêm `notifyOnGroupMessage`; `UserPreferencesDto` và `SettingsController` map thêm trường này.

## 6. Kiểm thử

- **Backend (MockMvc):**
  - người không thuộc nhóm → 403 cho cả GET, POST và read;
  - gửi và lấy theo cả 3 kiểu, thứ tự tăng dần, `hasMore` đúng;
  - gửi lặp cùng `clientMessageId` → 200 và vẫn chỉ có 1 tin;
  - nội dung rỗng hoặc 2001 code point → 400; 2000 emoji → 201;
  - `unreadMessageCount` không tính tin của chính mình, giảm về 0 sau khi gọi read, và read không làm giảm con trỏ;
  - xoá nhóm có tin nhắn thì không lỗi khoá ngoại.
- **Backend (unit, Mockito):** push gửi đúng cho thành viên khác người gửi, bỏ qua người tắt tuỳ chọn, không push khi gửi lặp, không lưu vào `Notification`.
- **App (unit):**
  - `mergeMessages` (bỏ trùng, sắp xếp, vị trí của pending);
  - `buildChatRows` (mốc ngày, chuỗi tin 5 phút);
  - `ChatNotifier` với repository giả (gửi thành công, gửi lỗi rồi gửi lại cùng id, poll trả tin trùng với tin pending);
  - `uuidV4()` đúng định dạng.
- **Thủ công:** hai máy cùng nhóm: nhắn qua lại; tắt mạng rồi gửi rồi bấm Gửi lại; cuộn lên tải tin cũ; thông báo khi ở màn khác; không có thông báo khi đang mở đúng nhóm.

## 7. Quyết định của Claude (bạn kiểm tra giúp)

1. Chat là **màn riêng** mở từ icon trên AppBar, không phải tab thứ ba, vì chat cần ô nhập và bàn phím chiếm toàn màn.
2. Poll **5 giây** khi đang mở màn chat (các màn khác dùng 20 giây).
3. Tin tối đa **2000 ký tự**.
4. Tin chat **không** vào hộp thư Thông báo, chỉ có push và badge.
5. Thành viên đã rời nhóm: tin cũ của họ vẫn còn và vẫn hiện tên; bản thân họ không đọc được nữa.
6. Có công tắc riêng "Tin nhắn nhóm" trong màn Thông báo.

## 8. Để người triển khai tự quyết

Tên class và file chi tiết, cách viết query đếm tin chưa đọc (JPQL hoặc `count`), chi tiết giao diện của bong bóng (theo `AppColors` và bo góc ở trên), nơi đặt `ActiveChat`.
