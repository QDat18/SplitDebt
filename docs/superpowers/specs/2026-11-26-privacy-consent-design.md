# Thiết kế: Quyền riêng tư, sự đồng ý và quyền truy cập thiết bị

**Ngày:** 2026-11-26 · **Trạng thái:** chờ duyệt · **Cập nhật cùng ngày:** OCR chuyển sang xử lý hoàn toàn trên máy (không còn DeepSeek), nên bỏ mục đồng ý tuỳ chọn `RECEIPT_AI` và mọi phần liên quan.

> Đây là thiết kế kỹ thuật cho đồ án, **không phải tư vấn pháp lý**. Trước khi phát hành thật, văn bản Chính sách và Điều khoản cần được giảng viên hoặc người có chuyên môn pháp lý đọc lại.

## 1. Căn cứ

- **Luật Bảo vệ dữ liệu cá nhân số 91/2025/QH15**, hiệu lực từ 01/01/2026. Theo các bản tóm tắt chính thống:
  - sự đồng ý phải rõ ràng, cụ thể; **im lặng hoặc không phản hồi không được coi là đồng ý**;
  - chủ thể dữ liệu có quyền đồng ý, không đồng ý và **rút lại sự đồng ý**, và việc rút lại phải dễ như lúc đồng ý;
  - bên xử lý dữ liệu phải **lưu và chứng minh được** sự đồng ý;
  - dữ liệu của trẻ em cần sự đồng ý của người đại diện theo pháp luật;
  - người dân có quyền yêu cầu xoá dữ liệu.
- **Nghị định 356/2025/NĐ-CP**, hiệu lực từ 01/01/2026, thay thế Nghị định 13/2023. Thời hạn xử lý yêu cầu của chủ thể dữ liệu tối đa 30 ngày. **Nghị định 330** quy định xử phạt.
- **Google Play:** app cho tạo tài khoản thì phải cho **yêu cầu xoá tài khoản ngay trong app và qua một đường link web**. Phải khai báo trong mục Data safety, có URL Chính sách quyền riêng tư.
- **App Store:** bắt buộc có xoá tài khoản trong app, App Privacy label, URL chính sách, và câu mô tả mục đích cho từng quyền truy cập (`NS…UsageDescription`).

Nguồn tham khảo được liệt kê ở mục 10. Điều luật cụ thể phải đối chiếu với văn bản gốc trên vbpl.moj.gov.vn.

## 2. Hiện trạng (đã kiểm tra trong code)

- Màn đăng ký chỉ có họ tên, email, mật khẩu. **Không có bước đồng ý nào**, không có chính sách, không có giới hạn tuổi.
- `push_notification_service.initialize()` gọi `requestPermission` ngay khi khởi tạo, tức là **xin quyền thông báo mà chưa giải thích, chưa đúng ngữ cảnh**.
- `Info.plist` chưa có câu mô tả cho Camera và Thư viện ảnh. Plan OCR đã ghi phải thêm.
- **Không có chức năng xoá tài khoản**, không có chức năng xem hay tải dữ liệu của mình.
- **Bên thứ ba nhận dữ liệu:**
  - Firebase (Google): push token;
  - Supabase: ảnh đại diện;
  - nhà cung cấp hosting backend và database.
- **Quét hoá đơn** đọc chữ và phân tích ngay trên điện thoại. Ảnh và chữ trên hoá đơn **không được gửi đi đâu**, chỉ kết quả cuối cùng (các món người dùng xác nhận lưu) mới lên server như một khoản chi bình thường.

## 3. Mục tiêu / Không làm / Thất bại dù chạy được

**Mục tiêu**
1. **Đồng ý chủ động khi đăng ký:** checkbox không tích sẵn; chưa tích đủ thì không đăng ký được. Lưu bằng chứng (ai, đồng ý gì, phiên bản nào, lúc nào, trên nền tảng nào).
2. **Đồng ý theo từng mục đích:** hiện app không có mục đích xử lý nào ngoài việc cung cấp dịch vụ, nên chưa có mục đồng ý tuỳ chọn. Bảng log và API được thiết kế để sau này thêm một loại mới (ví dụ dùng AI bên ngoài) chỉ bằng một giá trị enum mới, hỏi đúng lúc dùng và tắt được.
3. **Đồng ý lại khi văn bản đổi phiên bản:** người dùng cũ cũng phải đồng ý trước khi dùng tiếp.
4. **Xin quyền thiết bị đúng ngữ cảnh,** có màn giải thích trước khi hiện hộp thoại của hệ thống. Bị từ chối thì app vẫn chạy và chỉ cách bật lại.
5. **Trung tâm Quyền riêng tư** trong tab Cá nhân gồm:
   - xem Chính sách và Điều khoản;
   - quản lý các mục đồng ý;
   - xem trạng thái quyền thiết bị;
   - xem và sao chép dữ liệu của tôi;
   - xoá tài khoản.
6. **Xoá tài khoản thật sự:** ẩn danh hoá dữ liệu cá nhân nhưng không làm hỏng sổ nợ của các thành viên khác.
7. **Văn bản pháp lý tiếng Việt** (Chính sách, Điều khoản, trang hướng dẫn xoá tài khoản) và checklist khai báo cho hai store.

**Không làm**
- Không làm hồ sơ đánh giá tác động xử lý dữ liệu hay hồ sơ chuyển dữ liệu ra nước ngoài nộp cơ quan nhà nước. Đây là thủ tục pháp lý, không phải code; chỉ ghi chú ở mục 9.
- Không có analytics hay quảng cáo, nên không có ATT của iOS và không có banner cookie.
- Không làm luồng cho người dưới 16 tuổi có người giám hộ đồng ý. App chỉ dành cho người từ đủ 16 tuổi.

**Thất bại dù chạy được**
- Checkbox tích sẵn, hoặc đồng ý gộp chung "đồng ý tất cả" cho cả mục đích tuỳ chọn.
- Xin quyền thông báo, camera hay ảnh ngay khi mở app lần đầu.
- Không có bản ghi chứng minh, hoặc bản ghi bị sửa đè lên.
- Xoá tài khoản làm mất khoản chi hoặc công nợ của người khác, hoặc để lại email và tên thật trong database.
- Nói trong Chính sách rằng dữ liệu hoá đơn không rời máy, trong khi code lại gửi nó đi.

## 4. Các phương án đã cân nhắc

| Vấn đề | Phương án | Kết luận |
|---|---|---|
| Lưu bằng chứng đồng ý | (a) cột boolean trên `users`; (b) **bảng log chỉ thêm, không sửa** `user_consents` | **(b)**: chứng minh được lịch sử đồng ý và rút lại; (a) mất lịch sử |
| Văn bản pháp lý trong app | (a) WebView tới URL; (b) **văn bản đóng gói trong app** cùng bản web trên một trang tĩnh | **(b)**: không thêm dependency, đọc được offline; store vẫn có URL |
| Xoá tài khoản | (a) xoá cứng mọi bản ghi; (b) **ẩn danh hoá người dùng, giữ khoản chi/thanh toán đã ẩn danh** | **(b)**: (a) làm hỏng sổ nợ và lịch sử của người khác |
| Người dùng còn nợ khi xoá | (a) cho xoá, nợ treo; (b) **chặn tới khi mọi số dư về 0** | **(b)**: bảo vệ quyền lợi các thành viên khác (quyết định của Claude, cần duyệt) |

## 5. Thiết kế backend

### 5.1 Phiên bản văn bản và các loại đồng ý

`application.yaml`:
```yaml
app.legal:
  terms-version: ${LEGAL_TERMS_VERSION:2026-11-26}
  privacy-version: ${LEGAL_PRIVACY_VERSION:2026-11-26}
```

`enum ConsentType`:

| Giá trị | Ý nghĩa | Bắt buộc? | Có phiên bản? |
|---|---|---|---|
| `TERMS` | Điều khoản sử dụng | Có | `terms-version` |
| `PRIVACY` | Chính sách quyền riêng tư và xử lý dữ liệu cá nhân | Có | `privacy-version` |
| `AGE_16` | Xác nhận từ đủ 16 tuổi | Có | `"1"` |

Chưa có loại tuỳ chọn nào. Nếu sau này thêm thì loại đó được bật/tắt qua cùng API ở mục 5.3.

Quyền thông báo, camera và ảnh **không** nằm trong bảng này. Đó là quyền của hệ điều hành, app chỉ đọc trạng thái.

### 5.2 Bảng `user_consents` (chỉ thêm, không sửa)

| Cột | Kiểu |
|---|---|
| `id` | bigint, tự tăng |
| `user_id` | FK users, not null, index |
| `consent_type` | varchar(20), not null |
| `version` | varchar(20), not null |
| `granted` | boolean, not null |
| `source` | varchar(20): `REGISTER`, `RECONSENT` (giữ chỗ cho sau này: `PRIVACY_CENTER`, `JUST_IN_TIME`) |
| `platform` | varchar(10): `android`, `ios`, `web` |
| `app_version` | varchar(20), nullable |
| `created_at` | timestamp |

**Không có API sửa hay xoá bản ghi.** Trạng thái hiện tại của một loại đồng ý là bản ghi mới nhất của loại đó.

### 5.3 API

**`POST /api/auth/register`** nhận thêm trường bắt buộc:
```json
"consents": { "termsVersion": "2026-11-26", "privacyVersion": "2026-11-26", "ageConfirmed": true },
"platform": "android", "appVersion": "1.0.0"
```
- Thiếu trường, `ageConfirmed != true`, hoặc phiên bản khác phiên bản hiện hành → **400** "Bạn cần đồng ý Điều khoản, Chính sách và xác nhận đủ 16 tuổi để đăng ký." (phiên bản lệch thì: "Văn bản đã được cập nhật, vui lòng tải lại.").
- Thành công thì ghi 3 bản ghi `TERMS`, `PRIVACY`, `AGE_16` với `source = REGISTER`, **trong cùng transaction tạo user**.

**`GET /api/users/me`** thêm:
```json
"consent": {
  "termsVersion": "2026-11-26", "privacyVersion": "2026-11-26",
  "reconsentRequired": false,
  "acceptedAt": "2026-11-26T10:00:00"
}
```
`reconsentRequired` bằng `true` khi bản ghi `TERMS` hoặc `PRIVACY` mới nhất có `granted = true` nhưng khác phiên bản hiện hành, hoặc khi không có bản ghi nào. Người dùng cũ chưa từng có bản ghi nên sẽ thuộc trường hợp này.

`acceptedAt` là thời điểm của bản ghi `PRIVACY` mới nhất có `granted = true`, hoặc `null`.

**`POST /api/users/me/consents`** dùng cho việc đồng ý lại (và sau này cho các mục tuỳ chọn):
```json
{ "items": [ { "type": "TERMS", "granted": true, "version": "2026-11-26" } ],
  "source": "RECONSENT", "platform": "ios", "appVersion": "1.0.0" }
```
- `TERMS`, `PRIVACY` hoặc `AGE_16` với `granted = false` → **400** "Để rút lại đồng ý bắt buộc, hãy xoá tài khoản."
- `version` phải bằng phiên bản hiện hành của loại đó, nếu không trả 400.
- Thành công trả **200** cùng khối `consent` như ở `/users/me`.

**Chặn khi chưa đồng ý lại:** khi `reconsentRequired` là `true`, mọi API dưới `/api/**` trả **428** `{"code":"RECONSENT_REQUIRED"}`, trừ các route sau: `/api/auth/**`, `GET /api/users/me`, `/api/users/me/consents`, `/api/users/me/data-export`, `/api/users/me/deletion`, `/api/health`. Cài đặt bằng một filter chạy sau `JwtAuthenticationFilter`. Kết quả kiểm tra được cache theo user trong 60 giây và xoá cache khi user gửi đồng ý.

**`GET /api/users/me/data-export`** trả JSON (bọc `ApiResponse`) gồm:
- `profile`: họ tên, email, số điện thoại, avatarUrl, ngày tạo;
- `settings`;
- `consents`: toàn bộ lịch sử;
- `groups`: id, tên, vai trò, ngày tham gia;
- `expenses`: những khoản mình trả hoặc có tham gia, kèm phần của mình;
- `settlements`: những khoản mình là người nợ hoặc người nhận;
- `messages`: tin mình đã gửi;
- `notifications`;
- `exportedAt`.

Không bao gồm dữ liệu cá nhân của người khác ngoài tên hiển thị cần để hiểu bản ghi. Không trả `passwordHash` và không trả FCM token.

**`POST /api/users/me/deletion`**, body `{ "password": "..." }`:
1. Sai mật khẩu → **400**, thông báo "Mật khẩu không đúng", kèm `code: "WRONG_PASSWORD"`. Không dùng 401, vì app coi 401 là phiên đăng nhập hết hạn và tự xoá token.
2. Còn số dư khác 0 trong bất kỳ nhóm nào (`|balance| ≥ 0.01`, tính bằng `DebtCalculationService`) → **409**, kèm `{"groups":[{"id":..,"name":..,"balance":..}]}` và thông báo "Bạn cần thanh toán hết công nợ trước khi xoá tài khoản."
3. Nếu qua được 2 bước trên, chạy toàn bộ phần sau trong **một transaction**:
   - **Nhóm user là OWNER:** nếu còn thành viên ACTIVE khác thì chuyển OWNER cho ADMIN tham gia sớm nhất, không có ADMIN thì cho thành viên tham gia sớm nhất. Nếu chỉ còn mình user thì xoá nhóm bằng luồng `deleteGroup` hiện có.
   - Xoá mọi bản ghi `GroupMember` của user.
   - **Ẩn danh hoá `User`:**
     - `fullName` thành "Người dùng đã xoá";
     - `email` thành `deleted-<id>-<uuid>@deleted.invalid`;
     - `phone` và `avatarUrl` thành `null`;
     - `passwordHash` thành một hash ngẫu nhiên;
     - thêm cột `deletedAt` (timestamp).
   - **Xoá:** FCM token, `UserSetting`, `Notification`, `ocr_usage`, `UserActivityLog`, và ảnh đại diện trên Supabase. Xoá file trên Supabase **sau khi commit**; lỗi thì chỉ log, không rollback.
   - **Tin nhắn nhóm đã gửi:** đổi `content` thành "Tin nhắn đã bị xoá". Người gửi vẫn trỏ tới user đã ẩn danh.
   - **Giữ lại:** khoản chi, phần chia, thanh toán (chỉ trỏ tới user đã ẩn danh) để sổ nợ của người khác vẫn đúng, và `user_consents` làm bằng chứng tuân thủ.
4. Trả **204**. JWT cũ tự hết hiệu lực vì filter tìm user theo email, mà email đã đổi. Đăng nhập lại bằng email cũ sẽ báo sai thông tin.
5. User có `deletedAt != null` thì không đăng nhập được và không được thêm vào nhóm nào nữa.

## 6. Thiết kế app

### 6.1 Văn bản pháp lý

- Tạo `lib/features/legal/legal_texts.dart`, chứa nội dung Chính sách và Điều khoản dưới dạng danh sách `LegalSection(title, paragraphs)`. Nội dung lấy từ `docs/legal/*.md` (Task 9). Hằng `kTermsVersion` và `kPrivacyVersion` phải khớp backend.
- Tạo `LegalDocumentScreen(document)`, hiển thị theo kiểu HIG: tiêu đề lớn, ngày hiệu lực, các mục có tiêu đề cỡ 17 semibold, đoạn văn cỡ 16.

### 6.2 Màn đăng ký

Bên dưới các ô nhập, thêm 3 hàng checkbox, **mặc định không tích**:
```
☐ Tôi đã đọc và đồng ý Điều khoản sử dụng            ← "Điều khoản sử dụng" là link mở LegalDocumentScreen
☐ Tôi đã đọc và đồng ý Chính sách quyền riêng tư
  và cho phép xử lý dữ liệu cá nhân theo chính sách này
☐ Tôi xác nhận mình từ đủ 16 tuổi trở lên
[        Tạo tài khoản        ]  ← khoá khi chưa tích đủ 3 ô
Dữ liệu được dùng để quản lý nhóm, khoản chi và công nợ của bạn.   ← chú thích cỡ 13, n600
```
Không có nút "Đồng ý tất cả". Request gửi kèm phiên bản, nền tảng và phiên bản app.

### 6.3 Màn đồng ý lại (chặn)

Khi `/users/me` trả `reconsentRequired: true`, hoặc bất kỳ API nào trả 428, app chuyển sang `ReconsentScreen` và bỏ hết các màn phía sau (dùng `pushAndRemoveUntil`). Màn gồm:
- tiêu đề "Chúng tôi đã cập nhật điều khoản";
- 2 hàng link tới văn bản, mỗi hàng kèm câu tóm tắt thay đổi (`kLegalChangeSummary`, viết trong `legal_texts.dart`);
- 2 checkbox như ở màn đăng ký (không có checkbox tuổi);
- nút "Đồng ý và tiếp tục";
- nút phụ "Đăng xuất";
- liên kết nhỏ "Xoá tài khoản" (người không đồng ý vẫn có lối thoát).

Người dùng không vào được app khi chưa đồng ý.

### 6.4 Quyền thiết bị

**Quy tắc chung:** chỉ xin quyền đúng lúc cần, luôn có màn giải thích trước, và bị từ chối thì app vẫn chạy.

| Quyền | Khi nào xin | Màn giải thích trước | Bị từ chối |
|---|---|---|---|
| Thông báo (Android 13+, iOS, web) | **Sau lần đăng nhập đầu tiên**, khi vào Trang chủ. Chỉ hỏi 1 lần; "Để sau" thì hỏi lại sau 7 ngày, tối đa 2 lần | Bottom sheet: "Bật thông báo để biết ngay khi có người yêu cầu thanh toán, xác nhận khoản trả hoặc nhắn tin trong nhóm." Nút [Bật thông báo] và [Để sau] | Trung tâm Quyền riêng tư hiện "Đang tắt" và hướng dẫn bật trong Cài đặt hệ thống |
| Camera | Khi bấm "Chụp ảnh" (OCR, avatar) | Không cần sheet riêng vì người dùng vừa bấm nút; câu mô tả của hệ thống giải thích mục đích | SnackBar: "Chưa có quyền dùng camera. Bạn có thể bật trong Cài đặt > SplitDebt." |
| Thư viện ảnh | Khi bấm "Chọn ảnh". Android 13+ dùng Photo Picker, không cần quyền | Như trên | Như trên |

- Gỡ lời gọi `requestPermission` khỏi `PushNotificationService.initialize()`. Thêm `Future<bool> requestPermissionWithRationale(BuildContext)` (hiện sheet, rồi mới gọi `requestPermission`) và `Future<AuthorizationStatus> currentStatus()`.
- Lưu `notif_prompt_count` và `notif_prompt_last` trong `SharedPreferences`. Đây chỉ là tiện ích hiển thị cho từng máy, không phải bằng chứng pháp lý.
- **Câu mô tả iOS** (`Info.plist`):
  - `NSCameraUsageDescription` = "SplitDebt dùng camera để chụp hoá đơn và ảnh đại diện.";
  - `NSPhotoLibraryUsageDescription` = "SplitDebt cần truy cập thư viện để bạn chọn ảnh hoá đơn hoặc ảnh đại diện.".

  Nếu plan OCR đã thêm hai khoá này thì giữ một bộ chữ thống nhất.
- **Android:** không thêm `CAMERA` hay `READ_MEDIA_IMAGES` nếu `image_picker` không cần. `image_picker` dùng intent chụp ảnh và Photo Picker. Giữ `POST_NOTIFICATIONS`.

### 6.5 Trung tâm Quyền riêng tư

Thêm hàng **"Quyền riêng tư"** (icon `Icons.privacy_tip_outlined`) vào section Tài khoản của tab Cá nhân. Hàng này mở `PrivacyCenterScreen`, dùng `GroupedSection`/`GroupedTile`:
```
Văn bản
  Chính sách quyền riêng tư            ›
  Điều khoản sử dụng                   ›
  footer: Phiên bản 26/11/2026. Bạn đã đồng ý ngày dd/MM/yyyy.

Quyền của ứng dụng
  Thông báo                      Đang bật / Đang tắt
  Camera, Ảnh                    Hỏi khi dùng
  footer: Thay đổi trong Cài đặt của điện thoại. Ảnh hoá đơn được đọc ngay trên máy và không được gửi đi.

Dữ liệu của bạn
  Xem dữ liệu của tôi                  ›   → DataExportScreen
  Xoá tài khoản (đỏ, căn giữa)
```

- **`DataExportScreen`:** gọi `data-export`, hiện tóm tắt (số nhóm, số khoản chi, số tin nhắn...) và JSON dạng chữ chọn được (`SelectableText`, font monospace). Nút "Sao chép" dùng `Clipboard.setData`. Footer: "Yêu cầu khác về dữ liệu, liên hệ <email liên hệ>".
- **Xoá tài khoản**, theo trình tự:
  1. Màn giải thích: những gì bị xoá, những gì được giữ ẩn danh (khoản chi chung để sổ nợ của nhóm vẫn đúng), và việc này không hoàn tác được.
  2. Nhập mật khẩu.
  3. Hộp xác nhận adaptive, nút "Xoá vĩnh viễn" màu đỏ, nút phá huỷ.
  4. Gọi API:
     - 409 thì hiện danh sách nhóm còn nợ, mỗi nhóm bấm vào được để mở `GroupDetailScreen`;
     - 400 có `code == WRONG_PASSWORD` thì báo sai mật khẩu;
     - 204 thì xoá token, huỷ đăng ký topic FCM, về màn đăng nhập kèm SnackBar "Tài khoản đã được xoá.".

## 7. Văn bản pháp lý (Task 9)

- **`docs/legal/privacy-policy.md`** cần có các mục:
  1. Bên kiểm soát dữ liệu và thông tin liên hệ ([CẦN ĐIỀN]: tên nhóm hoặc người phát triển, email);
  2. Dữ liệu thu thập (tài khoản; dữ liệu nhóm, khoản chi, thanh toán; tin nhắn; ảnh đại diện; push token; thông tin kỹ thuật như nền tảng và phiên bản app). Ghi rõ: **ảnh và chữ trên hoá đơn khi dùng Quét hoá đơn được xử lý ngay trên điện thoại, không được gửi về máy chủ hay bên thứ ba**;
  3. Mục đích và căn cứ xử lý (sự đồng ý; thực hiện dịch vụ người dùng yêu cầu);
  4. Bên nhận dữ liệu và nơi lưu trữ (Firebase/Google; Supabase; hosting và database [CẦN ĐIỀN]; nêu rõ bên nào có thể lưu dữ liệu ở nước ngoài);
  5. Thời gian lưu và xoá (khi xoá tài khoản; những gì được giữ ẩn danh và lý do);
  6. Quyền của người dùng và cách thực hiện ngay trong app (xem, sao chép, sửa hồ sơ, tắt thông báo, xoá tài khoản, liên hệ), thời hạn phản hồi tối đa 30 ngày;
  7. Biện pháp bảo vệ (HTTPS, băm mật khẩu bằng bcrypt, phân quyền theo nhóm);
  8. Trẻ em (chỉ dành cho người từ đủ 16 tuổi);
  9. Thay đổi chính sách (đánh số phiên bản, yêu cầu đồng ý lại);
  10. Căn cứ: Luật 91/2025/QH15, Nghị định 356/2025/NĐ-CP.
- **`docs/legal/terms.md`:** mô tả dịch vụ; trách nhiệm tài khoản; hành vi bị cấm (nội dung vi phạm pháp luật trong chat, mạo danh); app chỉ ghi nhận công nợ giữa các thành viên, không giữ tiền và không xử lý thanh toán; giới hạn trách nhiệm; chấm dứt tài khoản; luật áp dụng là pháp luật Việt Nam.
- **`docs/legal/account-deletion.md`:** trang công khai hướng dẫn xoá tài khoản (dùng làm URL khai báo cho Google Play). Gồm cách xoá trong app, cách gửi yêu cầu qua email nếu không vào được app, dữ liệu bị xoá và dữ liệu được giữ ẩn danh.
- **Quy tắc viết:** tiếng Việt dễ hiểu, câu ngắn. **Không trích số điều khoản cụ thể** ngoài tên hai văn bản ở mục 10. Chỗ chưa biết thì để [CẦN ĐIỀN].

## 8. Kiểm thử

- **Backend (MockMvc):**
  - đăng ký thiếu đồng ý, sai phiên bản, hoặc `ageConfirmed = false` → 400; đăng ký đúng → 201 và có 3 bản ghi;
  - user cũ không có bản ghi → API nghiệp vụ trả 428, các route được miễn vẫn 200; đồng ý lại → hết 428;
  - rút `TERMS` → 400; đồng ý lại 2 lần thêm 2 nhóm bản ghi mới và không sửa bản cũ;
  - data-export chỉ chứa dữ liệu của mình, không có `passwordHash`;
  - xoá tài khoản: sai mật khẩu 400 (`WRONG_PASSWORD`); còn nợ 409 kèm danh sách nhóm; thành công 204, sau đó đăng nhập thất bại, email và tên đã ẩn danh, quyền OWNER đã chuyển, khoản chi của nhóm vẫn còn và số dư của các thành viên khác không đổi, tin nhắn đã thay nội dung, bản ghi đồng ý vẫn còn.
- **App (unit):**
  - `RegisterConsentState`: nút khoá cho tới khi tích đủ 3 ô;
  - `shouldPromptNotifications(count, last, now)`: lần đầu hỏi, sau "Để sau" thì 7 ngày mới hỏi lại, tối đa 2 lần;
  - parse khối `consent` từ `/users/me`;
  - interceptor Dio gặp 428 thì gọi callback điều hướng.
- **Thủ công:**
  - cài mới: không có hộp thoại xin quyền nào trước khi đăng nhập;
  - đăng ký thiếu một ô thì nút khoá;
  - đăng nhập lần đầu: sheet thông báo, bấm "Để sau";
  - đổi `LEGAL_PRIVACY_VERSION` ở backend: app chặn ở màn đồng ý lại;
  - xoá tài khoản còn nợ và hết nợ.

## 9. Ngoài phạm vi code, nhưng phải biết

- **Chuyển dữ liệu ra nước ngoài** (Firebase, Supabase, và có thể cả hosting, tuỳ vùng máy chủ): pháp luật Việt Nam có yêu cầu về hồ sơ đánh giá tác động cho tổ chức xử lý dữ liệu. Đồ án sinh viên chỉ cần nêu rõ trong Chính sách. Khi phát hành thương mại cần người có chuyên môn pháp lý tư vấn.
- **Checklist cho store (Task 9 tạo `docs/legal/store-checklist.md`):**
  - **Google Play:** URL chính sách, URL trang xoá tài khoản, khai báo mục Data safety (dữ liệu thu thập, chia sẻ với bên thứ ba, có mã hoá khi truyền, cho phép xoá).
  - **App Store:** URL chính sách, App Privacy label tương ứng, tính năng xoá tài khoản ngay trong app, câu mô tả cho các quyền.
- **Lưu trữ văn bản công khai:** 3 file markdown cần được đưa lên một trang tĩnh công khai (GitHub Pages, Vercel...). Việc này chủ dự án tự làm; Task 9 chỉ chuẩn bị nội dung.
- **Quy trình xử lý sự cố lộ dữ liệu:** cần một quy trình nội bộ (ai chịu trách nhiệm, báo cho ai, trong bao lâu). Không thuộc phạm vi code.

## 10. Nguồn tham khảo

- Luật Bảo vệ dữ liệu cá nhân 91/2025/QH15: https://thuvienphapluat.vn/van-ban/Bo-may-hanh-chinh/Luat-Bao-ve-du-lieu-ca-nhan-2025-so-91-2025-QH15-625628.aspx
- Bộ Công an, luật có hiệu lực từ 01/01/2026: https://bocongan.gov.vn/chinh-sach-phap-luat/bai-viet/luat-bao-ve-du-lieu-ca-nhan-chinh-thuc-co-hieu-luc-thi-hanh-tu-ngay-01-01-2026-1767186124
- VnExpress, quyền yêu cầu xoá dữ liệu: https://vnexpress.net/tu-2026-nguoi-dan-co-quyen-yeu-cau-xoa-du-lieu-ca-nhan-4999068.html
- Nghị định 356/2025/NĐ-CP: https://thuvienphapluat.vn/van-ban/Quyen-dan-su/Nghi-dinh-356-2025-ND-CP-huong-dan-Luat-Bao-ve-du-lieu-ca-nhan-687428.aspx
- PwC, thời hạn xử lý yêu cầu 30 ngày: https://www.pwc.com/vn/vn/publications/legal-news-brief/20260128-new-rules-personal-data-protection.html
- Google Play, yêu cầu xoá tài khoản: https://support.google.com/googleplay/android-developer/answer/13327111

## 11. Quyết định của Claude (bạn kiểm tra giúp)

1. App chỉ dành cho người **từ đủ 16 tuổi**. Không làm luồng người giám hộ.
2. **Chặn xoá tài khoản khi còn nợ** trong bất kỳ nhóm nào.
3. Xoá tài khoản thì **chuyển OWNER** tự động cho ADMIN tham gia sớm nhất, không có thì cho thành viên tham gia sớm nhất.
4. Tin nhắn của tài khoản đã xoá bị **thay nội dung** bằng "Tin nhắn đã bị xoá", thay vì giữ nguyên.
5. Đổi phiên bản văn bản thì **chặn dùng app** tới khi đồng ý lại (backend trả 428).
6. Quyền thông báo được hỏi sau lần đăng nhập đầu, **tối đa 2 lần, cách nhau 7 ngày**.
7. "Xem dữ liệu của tôi" hiển thị JSON kèm nút sao chép, không xuất file. Lý do: không thêm dependency.
