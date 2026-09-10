# SplitDebt Spring Boot API

Backend REST cho ứng dụng SplitDebt. Runtime sử dụng schema `users`, `groups`, `group_members`, `expenses`, `expense_participants`, `expense_items`, `item_participants`, `debts`, `settlements`, `notifications` và các bảng settings. Xác thực dùng JWT do backend phát hành.

## Chạy local

1. Cài Java 17+.
2. Có thể giữ cấu hình mặc định để chạy H2 local, hoặc copy `.env.example` thành `.env` và cấu hình PostgreSQL.
3. Chạy `mvnw.cmd spring-boot:run` trên Windows hoặc `bash mvnw spring-boot:run` trên macOS/Linux.
4. API mặc định: `http://localhost:8080/api`.

Đọc thêm: [SETUP](../docs/SETUP.md), [API](../docs/API.md), [VALIDATION](../docs/VALIDATION.md).
