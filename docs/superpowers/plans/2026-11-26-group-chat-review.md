# Review: Chat nhóm (hoàn thiện)

Review của Claude Code trên `eb06473^..9659505` và code chat hiện tại. Áp dụng Global Constraints của `2026-11-25-group-chat.md`.

**Đã tốt:**
- Mọi API đều gọi `requireActiveMember`; người đã rời hoặc bị xoá khỏi nhóm không đọc hay gửi được.
- Gửi trùng được chặn bằng `clientMessageId` + unique constraint. Tin đang gửi và tin lỗi hiện rõ, có nút thử lại.
- Push gửi **sau commit**, bỏ qua người gửi và người đã tắt thông báo. Màn chat đang mở thì không hiện push trùng.
- Phân trang tin cũ bằng con trỏ id, có index `(group_id, id)`. Tự làm mới dừng khi app chạy nền.

## C1. Thành viên mới thấy số chưa đọc bằng toàn bộ lịch sử

`lastReadMessageId` của thành viên mới là `null`, nên được tính như `0`. Người mới vào nhóm có 300 tin sẽ thấy badge **300 chưa đọc**.

**Sửa:** khi thêm thành viên (mọi luồng tạo `GroupMember` ACTIVE, kể cả khi thành viên cũ được thêm lại), đặt `lastReadMessageId` = id tin mới nhất của nhóm (hoặc `null` nếu nhóm chưa có tin). Lịch sử vẫn xem được như cũ.

**Test (`GroupChatControllerTest`):** nhóm có 3 tin, thêm B → `unreadMessageCount` của B bằng 0. Sau đó A gửi 1 tin → B thấy 1.

## C2. Tải lần đầu lỗi thì lần làm mới sau hiện 100 tin cũ nhất

Nếu `loadInitial` lỗi (mạng chập chờn), danh sách rỗng, nên `refreshNewer` gọi `after=0`, và server trả **100 tin đầu tiên** của nhóm. Người dùng thấy tin từ nhiều tháng trước như thể là tin mới nhất.

**Sửa (`chat_notifier.dart`):** trong `refreshNewer`, nếu chưa có tin nào từ server (`newestServerId == null`) và `state.error != null`, gọi `loadInitial()` thay cho `after(0)`. Nhóm thật sự chưa có tin (không lỗi) thì giữ nguyên hành vi hiện tại.

**Test (`chat_notifier_test.dart`):** repository giả, `latest` lỗi lần đầu và thành công lần sau. Sau `loadInitial` (lỗi) rồi `refreshNewer`, phải gọi `latest` lần 2 và **không** gọi `after(0)`.

## C3. Tin quá 2000 ký tự lỗi mãi mãi

Ô nhập không giới hạn độ dài, còn server từ chối tin trên 2000 ký tự (400). Tin hiện "Chưa gửi được · Chạm để thử lại", nhưng thử lại bao nhiêu lần cũng lỗi.

**Sửa:**
- Ô nhập `maxLength: 2000`. Chỉ hiện bộ đếm khi còn dưới 200 ký tự.
- Trong `send`/`retry`: lỗi **400** thì đánh dấu tin là `rejected` (trạng thái mới, không có nút thử lại) và hiện câu báo của server dưới tin. Lỗi mạng hoặc 5xx vẫn là `failed` như cũ. Tin `rejected` có thể vuốt hoặc nhấn giữ để xoá khỏi danh sách (chỉ trên máy).

**Test:** repository giả ném lỗi 400 → tin có trạng thái `rejected`, `retry` không gửi lại.

## C4. Bị xoá khỏi nhóm trong lúc đang mở chat

Polling nhận 403 nhưng bỏ qua im lặng. Người dùng vẫn gõ được, mọi tin đều lỗi.

**Sửa:** `refreshNewer` hoặc `send` nhận **403** thì đặt cờ `removed = true` trong state, dừng polling. Màn chat ẩn ô nhập và hiện dòng "Bạn không còn là thành viên của nhóm này.".

**Test:** repository giả ném 403 ở `after` → `state.removed == true`.

## C5. Hai lần gửi trùng cùng lúc trả 409 (nhỏ)

Hai request cùng `clientMessageId` đến gần như cùng lúc (mạng chậm, bấm thử lại): cả hai cùng qua bước kiểm tra, một request vi phạm unique constraint và trả lỗi chung.

**Sửa (`GroupChatService.send`):** bắt `DataIntegrityViolationException` khi lưu, đọc lại bằng `findBySenderIdAndClientMessageId` và trả kết quả `created = false`. Vì exception làm hỏng transaction hiện tại, phần đọc lại phải chạy ngoài transaction đó. Nếu cách làm không rõ thì dừng lại hỏi, không tự đoán.

**Test:** gọi `send` 2 lần tuần tự cùng `clientMessageId` vẫn trả cùng id (đã có). Không bắt buộc test đồng thời.

## Kiểm tra cuối

- `cd api; .\mvnw.cmd test` và `cd frontend; flutter analyze; flutter test -j 1` PASS.
- Mỗi mục một commit. Cập nhật `docs/PROGRESS.md`. Không push.
