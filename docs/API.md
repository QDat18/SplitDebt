# SplitDebt REST API

Base path: `/api`.

## Xác thực

Backend tự quản lý tài khoản trong bảng `users`. Mật khẩu được băm PBKDF2-HMAC-SHA256 trước khi lưu vào `password_hash`. Sau đăng nhập backend phát hành JWT HMAC-SHA256. Các endpoint trừ `/health`, `/auth/register`, `/auth/login` yêu cầu:

```text
Authorization: Bearer <jwt>
```

### Auth

| Method | Path | Body |
|---|---|---|
| POST | `/auth/register` | `fullName`, `email`, `phone?`, `password`, `acceptedTerms` |
| POST | `/auth/login` | `email`, `password` |
| GET | `/me` | Hồ sơ hiện tại |
| PATCH | `/me` | `fullName`, `phone?`, `avatarUrl?` |
| GET/PATCH | `/me/settings` | `user_settings` |

## Nhóm

| Method | Path | Mô tả |
|---|---|---|
| GET | `/overview` | Hồ sơ, nhóm, số dư tách theo tiền tệ, số thông báo chưa đọc |
| GET | `/groups` | Nhóm mà người dùng đang ACTIVE |
| POST | `/groups` | Tạo nhóm, tạo OWNER, `invite_code` và `group_settings` |
| POST | `/groups/join` | Tham gia bằng `inviteCode` |
| GET | `/groups/{id}` | Nhóm, thành viên, khoản chi, settlement, balances, Smart Settlement |
| POST | `/groups/{id}/members` | OWNER thêm tài khoản bằng email |
| DELETE | `/groups/{id}/members/{userId}` | OWNER loại thành viên đã cân bằng công nợ |
| GET/PATCH | `/groups/{id}/settings` | Cấu hình nhóm |

## Khoản chi

`totalAmount` và các trường tiền trong API dùng **minor units** để tránh lỗi số thực: VND dùng đồng; USD/EUR dùng cent. Backend chuyển sang `NUMERIC` theo `group_settings.decimal_scale` trước khi lưu PostgreSQL.

```json
{
  "title": "Ăn tối",
  "description": "Tối thứ bảy",
  "totalAmount": 450000,
  "categoryId": 1,
  "payerId": 10,
  "expenseDate": "2026-09-06",
  "receiptUrl": null,
  "splitType": "EQUAL",
  "participants": [
    {"userId": 10},
    {"userId": 11},
    {"userId": 12}
  ],
  "items": []
}
```

`splitType`: `EQUAL`, `AMOUNT`, `PERCENT`, `WEIGHT`, `ITEM`.

- `AMOUNT`: mỗi participant gửi `amount`; tổng phải bằng khoản chi.
- `PERCENT`: mỗi participant gửi `percentage`; tổng phải bằng 100.
- `WEIGHT`: mỗi participant gửi `weight` > 0.
- `ITEM`: gửi danh sách `items`, mỗi món có `itemName`, `quantity`, `unitPrice`, `totalPrice`, `participantIds`; tổng món phải bằng tổng khoản chi.

| Method | Path |
|---|---|
| GET | `/categories` |
| POST | `/groups/{id}/expenses` |
| PUT | `/groups/{id}/expenses/{expenseId}` |
| DELETE | `/groups/{id}/expenses/{expenseId}` |

Mỗi lần thêm/sửa/xóa khoản chi, backend tính lại số dư và bảng `debts` trong cùng transaction.

## Công nợ và quyết toán

Số dư ròng = tổng được nhận − tổng phải trả. Số dương là creditor, số âm là debtor. Smart Settlement ghép debtor/creditor và trả danh sách `suggestions`.

Quy trình thanh toán hai chiều:

1. Debtor gọi `POST /groups/{id}/settlements` với `creditorId`, `amount`, `paymentMethod` → trạng thái `PAID` và `paid_at`.
2. Creditor gọi `POST /settlements/{id}/confirm` → `CONFIRMED`, `confirmed_at`, công nợ được tính lại.
3. Bản ghi `PENDING/PAID` có thể hủy qua `POST /settlements/{id}/cancel` theo quyền.

Ứng dụng chỉ **ghi nhận** phương thức thanh toán bên ngoài; không thực hiện chuyển tiền thật.

## Thông báo, lịch sử, thống kê

| Method | Path |
|---|---|
| GET | `/notifications?limit=50` |
| POST | `/notifications/{id}/read` |
| GET | `/activity?limit=30&offset=0` |
| GET | `/groups/{id}/statistics?range=WEEK|MONTH|ALL` |

## Bảng dữ liệu được sử dụng

`users`, `groups`, `group_members`, `categories`, `expenses`, `expense_participants`, `expense_items`, `item_participants`, `expense_shares`, `debts`, `settlements`, `notifications`, `group_settings`, `user_settings`.

Các bảng legacy `profiles`, `debt_groups`, `members` không còn được runtime mới sử dụng.
