# Review vòng 1: Sửa chat nhóm (C1–C5)

Review của Claude Code trên `0524641..03e0731`. Áp dụng Global Constraints của `2026-11-25-group-chat.md`.

**Đã kiểm tra:**
- C1: cả 2 luồng tạo thành viên (thêm thành viên, tham gia bằng mã) đặt `lastReadMessageId` = tin mới nhất. Không có luồng nào kích hoạt lại thành viên cũ, nên không cần sửa thêm.
- C2, C3, C4 (app): đúng plan. Repository để `DioException` đi thẳng lên, nên mã 400 và 403 được nhận đúng. Ô nhập có `maxLength: 2000`, bộ đếm hiện khi gần hết.
- Push vẫn chỉ gửi sau khi tin đã lưu.

Đây là **vòng 1 trên tối đa 3**.

## G1. Gửi lại tin đã lưu trả 500 (nghiêm trọng, do C5 gây ra)

C5 bỏ `@Transactional` khỏi `GroupChatService.send`. Mà `application.yaml` đặt `spring.jpa.open-in-view: false`, nên **ngoài transaction không còn session Hibernate**. Ở nhánh "tin đã tồn tại" (và nhánh bắt `DataIntegrityViolationException`), `findBySenderIdAndClientMessageId` trả entity có `sender` lazy. Khi `toDto` gọi `getSender().getFullName()` thì nổ `LazyInitializationException`.

Claude Code đã chạy thử **không có transaction của test**: gửi tin lần 1 trả **201**, gửi lại cùng `clientMessageId` trả **500** `could not initialize proxy [User#1] - no Session`.

Hậu quả: đúng trường hợp idempotency được làm ra để xử lý (mạng chậm, tin đã lưu nhưng app không nhận được phản hồi, người dùng bấm "thử lại") thì tin báo lỗi mãi, không bao giờ chuyển sang đã gửi.

**Vì sao test không bắt được:** `GroupChatControllerTest` có `@Transactional` ở cấp class, nên mọi request trong một test chạy chung một transaction và session luôn mở. Lỗi bị che.

**Sửa:**
- Trong `GroupMessageRepository`, thêm `@EntityGraph(attributePaths = {"sender", "group"})` cho `findBySenderIdAndClientMessageId`, để entity trả về đã nạp sẵn người gửi và nhóm.
- Kiểm tra `toDto(saved)` ở nhánh tạo mới: entity được nạp bằng `findById` trong `transactionTemplate`, nên đã đủ dữ liệu. Giữ nguyên, nhưng phải có test bên dưới chứng minh.
- **Không** thêm lại `@Transactional` cho `send` (sẽ phá cách xử lý C5).

**Test:** tạo class mới `GroupChatNoTxTest`, **không có `@Transactional`**, dùng MockMvc và đăng ký user qua API như `AccountDeletionControllerTest`.
- `resendSameClientMessageId_returns200WithSameId`: gửi lần 1 → 201; gửi lại cùng `clientMessageId` → **200**, cùng `id`, `senderName` đúng.
- `firstSend_returnsSenderName`: gửi tin mới → 201 và `$.data.senderName` khác rỗng.
- Dọn dữ liệu cuối test nếu cần, để không ảnh hưởng test khác (database H2 dùng chung trong cùng context).

## Kiểm tra cuối

- `cd api; .\mvnw.cmd test` PASS.
- Một commit. Cập nhật `docs/PROGRESS.md`. Không push.
