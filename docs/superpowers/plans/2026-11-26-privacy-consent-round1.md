# Review vòng 1: Quyền riêng tư, phần backend (Task 1–4, 6)

Review của Claude Code trên `a6472e8..91be056`. Áp dụng Global Constraints của `2026-11-26-privacy-consent.md`.

**Đã kiểm tra:**
- `.\mvnw.cmd test`: 98 passed.
- Task 1 (log đồng ý chỉ thêm, đăng ký có đồng ý, rollback khi thiếu đồng ý), Task 2 (filter 428, danh sách route miễn đúng spec, cache 60 giây), Task 3 (xuất dữ liệu, không có `passwordHash` hay FCM token) đều đúng spec.
- Task 4: ẩn danh hoá, chặn khi còn nợ, chuyển OWNER, ẩn nội dung tin nhắn, xoá avatar sau commit, chặn đăng nhập và chặn thêm vào nhóm đều đúng.
- Task 6: không trích số điều khoản, có mục riêng nói OCR xử lý trên máy.

Đây là **vòng 1 trên tối đa 3**.

## P1. Không xoá được tài khoản khi là chủ duy nhất của nhóm có khoản chi (nghiêm trọng)

Nhánh "chỉ còn mình user" gọi `groupService.deleteGroup`. Hàm này chỉ xoá tin nhắn, thành viên và nhóm, **không xoá** khoản chi, phần chia, thanh toán hay cài đặt nhóm. Vì vậy câu lệnh xoá nhóm vi phạm khoá ngoại.

Claude Code đã chạy thử: user tạo nhóm, thêm 1 khoản chi tự trả cho chính mình (số dư 0), rồi xoá tài khoản. Kết quả: **409** "Không thể thực hiện vì dữ liệu đang được sử dụng…", log có `Referential integrity constraint violation … EXPENSES FOREIGN KEY(GROUP_ID)`.

Trường hợp này rất phổ biến: dùng app một mình, hoặc bạn bè đã rời nhóm. Những người dùng đó **không bao giờ xoá được tài khoản**, trái với yêu cầu của luật và của store. Test `soleOwnerGroup_isDeleted` không bắt được lỗi này vì nhóm trong test không có khoản chi.

**Sửa:**
- Trong `AccountDeletionService`, nhánh không còn thành viên ACTIVE nào khác **không gọi `deleteGroup` nữa**. Thay vào đó gọi một hàm mới `purgeGroup(groupId)` (đặt trong `AccountDeletionService` hoặc một service riêng, **không đổi hành vi của `deleteGroup` hiện có**).
- `purgeGroup` xoá theo đúng thứ tự khoá ngoại: participant của từng món (`ItemParticipant`) → món (`ExpenseItem`) → phần chia (`ExpenseParticipant`) → khoản chi (`Expense`) → thanh toán (`Settlement`) → cài đặt nhóm (`GroupSetting`) → tin nhắn → mọi `GroupMember` → nhóm. Kiểm tra từng entity tham chiếu `Group` trong `entity/` để không sót bảng nào.
- Chạy trong cùng transaction của việc xoá tài khoản.

**Test (thêm vào `AccountDeletionControllerTest`):**
- `soleOwnerGroupWithExpenses_isPurged`: A tạo nhóm, thêm 1 khoản chi A trả cho chính A, và 1 thanh toán nếu tạo được. A xoá tài khoản → **204**. Nhóm, khoản chi và thanh toán của nhóm đều không còn.
- `soleOwnerWithFormerMembers_isPurged`: A tạo nhóm, thêm B, tạo khoản chi A trả chia đều A và B, B thanh toán xong rồi rời nhóm (dùng API có sẵn; không có API rời nhóm thì xoá thành viên B bằng quyền OWNER). A xoá tài khoản → **204**.
- Các test cũ vẫn PASS.

**Ghi chú, không sửa trong vòng này:** `deleteGroup` (nút xoá nhóm trong app) cũng gặp lỗi khoá ngoại khi nhóm có khoản chi. Lỗi này có từ trước và nằm ngoài phạm vi plan. Chỉ ghi vào PROGRESS mục Blockers để chủ dự án quyết định.

## P2. Sai mật khẩu trả 401 làm app tự đăng xuất

Interceptor trong `frontend/lib/core/network/dio_client.dart` **xoá token** khi gặp bất kỳ 401 nào ngoài `/auth/`. Nếu người dùng gõ sai mật khẩu ở màn xoá tài khoản, họ sẽ bị đăng xuất ngầm thay vì thấy báo "Mật khẩu không đúng". Đây là lỗi của spec, Claude Code đã sửa spec và plan.

**Sửa:**
- Sai mật khẩu ở `/api/users/me/deletion` trả **400**, body `ApiResponse` với `message: "Mật khẩu không đúng"` và `data: {"code": "WRONG_PASSWORD"}`. `ApiResponse` không có trường `code`, nên đặt `code` trong `data` cho nhất quán với cách đặt `groups` ở 409.
- Đổi test `wrongPassword_is401` thành `wrongPassword_is400`, kiểm tra `$.data.code == "WRONG_PASSWORD"`.

## P3. `platform` và `appVersion` không được kiểm tra (nhỏ)

Hai trường do client gửi lên được lưu thẳng vào cột `varchar(10)` / `varchar(20)`. Chuỗi dài hơn gây lỗi 500 ở cả đăng ký lẫn `POST /users/me/consents`.

**Sửa:** trong `ConsentService`, `platform` chỉ nhận `android`, `ios`, `web` (không phân biệt hoa thường, lưu chữ thường), giá trị khác thì lưu `null`. `appVersion` dài hơn 20 ký tự thì cắt còn 20. Không trả lỗi, vì đây là dữ liệu phụ.

**Test:** `register_longPlatformAndVersion_isStored`: `platform` = `"windows-phone-xyz"`, `appVersion` dài 30 ký tự → 200, bản ghi có `platform == null` và `appVersion` dài 20.

## Dọn dẹp

Các file `docs/legal/*.md` và `frontend/test/receipt_holdout_test.dart` đang có thay đổi chưa commit, chỉ là thêm dòng trống cuối file. Hãy bỏ các thay đổi này (`git checkout --`).

## Kiểm tra cuối

- `cd api; .\mvnw.cmd test` PASS.
- Mỗi mục một commit. Cập nhật `docs/PROGRESS.md`.
- Không push. Chưa làm Task 7–9.
