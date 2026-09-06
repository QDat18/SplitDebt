# BÁO CÁO KHỞI TẠO TẦNG ENTITY - DỰ ÁN SPLITDEBT API

---

## 1. Các công việc đã thực hiện (Work Accomplished)

Đã hoàn thiện **100%** việc ánh xạ từ kịch bản Cơ sở dữ liệu PostgreSQL/Supabase sang các Java Entity Classes trong dự án Spring Boot 3.x (`com.splitdebt.api`).

### 1.1. Tái sử dụng & Kế thừa `BaseEntity`
- Tái sử dụng [BaseEntity.java](file:///d:/KyVII_HocVienNganHang/LapTrinhDiDong/CuoiKy/SplitDebt/api/src/main/java/com/splitdebt/api/entity/BaseEntity.java) sẵn có chứa 2 trường audit tự động (`createdAt`, `updatedAt`).
-Áp dụng kế thừa `BaseEntity` cho các thực thể có cả 2 trường `created_at` và `updated_at`:
  - [User.java](file:///d:/KyVII_HocVienNganHang/LapTrinhDiDong/CuoiKy/SplitDebt/api/src/main/java/com/splitdebt/api/entity/User.java)
  - [Group.java](file:///d:/KyVII_HocVienNganHang/LapTrinhDiDong/CuoiKy/SplitDebt/api/src/main/java/com/splitdebt/api/entity/Group.java)
  - [Expense.java](file:///d:/KyVII_HocVienNganHang/LapTrinhDiDong/CuoiKy/SplitDebt/api/src/main/java/com/splitdebt/api/entity/Expense.java)
  - [Debt.java](file:///d:/KyVII_HocVienNganHang/LapTrinhDiDong/CuoiKy/SplitDebt/api/src/main/java/com/splitdebt/api/entity/Debt.java)

### 1.2. Khởi tạo 11 Java Entity Classes
1. **[User.java](file:///d:/KyVII_HocVienNganHang/LapTrinhDiDong/CuoiKy/SplitDebt/api/src/main/java/com/splitdebt/api/entity/User.java)** (`users`): Quản lý tài khoản người dùng (`fullName`, `email`, `phone`, `passwordHash`, `avatarUrl`).
2. **[Group.java](file:///d:/KyVII_HocVienNganHang/LapTrinhDiDong/CuoiKy/SplitDebt/api/src/main/java/com/splitdebt/api/entity/Group.java)** (`groups`): Quản lý nhóm chi tiêu, liên kết chủ sở hữu (`owner` -> `User`).
3. **[GroupMember.java](file:///d:/KyVII_HocVienNganHang/LapTrinhDiDong/CuoiKy/SplitDebt/api/src/main/java/com/splitdebt/api/entity/GroupMember.java)** (`group_members`): Liên kết người dùng - nhóm, vai trò (`role`), trạng thái (`status`) và ràng buộc duy nhất (`uq_group_user`).
4. **[Category.java](file:///d:/KyVII_HocVienNganHang/LapTrinhDiDong/CuoiKy/SplitDebt/api/src/main/java/com/splitdebt/api/entity/Category.java)** (`categories`): Danh mục khoản chi (`name`, `icon`).
5. **[Expense.java](file:///d:/KyVII_HocVienNganHang/LapTrinhDiDong/CuoiKy/SplitDebt/api/src/main/java/com/splitdebt/api/entity/Expense.java)** (`expenses`): Khoản chi tiêu chính (`group`, `category`, `payer`, `title`, `totalAmount`, `expenseDate`, `receiptUrl`).
6. **[ExpenseParticipant.java](file:///d:/KyVII_HocVienNganHang/LapTrinhDiDong/CuoiKy/SplitDebt/api/src/main/java/com/splitdebt/api/entity/ExpenseParticipant.java)** (`expense_participants`): Chi tiết người tham gia & tỷ lệ/số tiền phân bổ chia nợ.
7. **[ExpenseItem.java](file:///d:/KyVII_HocVienNganHang/LapTrinhDiDong/CuoiKy/SplitDebt/api/src/main/java/com/splitdebt/api/entity/ExpenseItem.java)** (`expense_items`): Các dòng món ăn/dịch vụ khi chọn chia theo món (`itemName`, `quantity`, `unitPrice`, `totalPrice`).
8. **[ItemParticipant.java](file:///d:/KyVII_HocVienNganHang/LapTrinhDiDong/CuoiKy/SplitDebt/api/src/main/java/com/splitdebt/api/entity/ItemParticipant.java)** (`item_participants`): Người tham gia từng món cụ thể.
9. **[Debt.java](file:///d:/KyVII_HocVienNganHang/LapTrinhDiDong/CuoiKy/SplitDebt/api/src/main/java/com/splitdebt/api/entity/Debt.java)** (`debts`): Nghĩa vụ công nợ giữa con nợ (`debtor`) và chủ nợ (`creditor`).
10. **[Settlement.java](file:///d:/KyVII_HocVienNganHang/LapTrinhDiDong/CuoiKy/SplitDebt/api/src/main/java/com/splitdebt/api/entity/Settlement.java)** (`settlements`): Giao dịch quyết toán 2 chiều (`amount`, `status`, `paymentMethod`, mốc thời gian `requestedAt`, `paidAt`, `confirmedAt`).
11. **[Notification.java](file:///d:/KyVII_HocVienNganHang/LapTrinhDiDong/CuoiKy/SplitDebt/api/src/main/java/com/splitdebt/api/entity/Notification.java)** (`notifications`): Thông báo hệ thống và đẩy di động (`title`, `content`, `type`, `isRead`).

### 1.3. Khởi tạo 4 Enum Classes (`com.splitdebt.api.entity.enums`)
- [GroupRole.java](file:///d:/KyVII_HocVienNganHang/LapTrinhDiDong/CuoiKy/SplitDebt/api/src/main/java/com/splitdebt/api/entity/enums/GroupRole.java): `OWNER`, `MEMBER`
- [GroupMemberStatus.java](file:///d:/KyVII_HocVienNganHang/LapTrinhDiDong/CuoiKy/SplitDebt/api/src/main/java/com/splitdebt/api/entity/enums/GroupMemberStatus.java): `ACTIVE`, `INACTIVE`
- [SplitType.java](file:///d:/KyVII_HocVienNganHang/LapTrinhDiDong/CuoiKy/SplitDebt/api/src/main/java/com/splitdebt/api/entity/enums/SplitType.java): `EQUAL`, `AMOUNT`, `PERCENT`, `WEIGHT`, `ITEM`
- [SettlementStatus.java](file:///d:/KyVII_HocVienNganHang/LapTrinhDiDong/CuoiKy/SplitDebt/api/src/main/java/com/splitdebt/api/entity/enums/SettlementStatus.java): `PENDING`, `PAID`, `CONFIRMED`, `CANCELLED`

---

## 2. Mức độ hoàn thiện & Đánh giá chất lượng (Completeness & Quality)

| Tiêu chí | Đánh giá | Chi tiết triển khai |
| :--- | :---: | :--- |
| **Mức độ hoàn thiện** | **100%** | Tất cả 11 bảng SQL và thuộc tính đều được ánh xạ đầy đủ. |
| **Chuẩn kiểu dữ liệu tiền tệ** | **Đạt chuẩn** | Sử dụng `java.math.BigDecimal` với `precision` và `scale` chính xác, tránh sai số số thực. |
| **Tối ưu hóa Performance** | **Đạt chuẩn** | Sử dụng `FetchType.LAZY` cho tất cả các quan hệ `@ManyToOne` để tránh N+1 Query Problem. |
| **Ràng buộc toàn vẹn** | **Đạt chuẩn** | Khhai báo chính xác `@Column(nullable, length, unique)` và `@UniqueConstraint`. |
| **Chuẩn mã nguồn Java** | **Đạt chuẩn** | Sử dụng Lombok (`@Getter`, `@Setter`, `@Builder`, `@NoArgsConstructor`, `@AllArgsConstructor`) giúp code sạch đẹp. |

---

## 3. Mức độ bám sát yêu cầu (Requirements Compliance)

- **Chuẩn DB Script & SRS**: Bám sát 100% kịch bản DDL SQL được cung cấp cũng như tài liệu phân tích hệ thống SplitDebt.
- **Kế thừa Base Entity**: Các bảng có trường `updated_at` đều kế thừa `BaseEntity`. Các bảng chỉ có audit khởi tạo (`joined_at`, `created_at`) dùng `@CreationTimestamp` của Hibernate.
- **Tính mở rộng**: Cấu trúc Entity đã sẵn sàng hỗ trợ các thuật toán chia nợ phức tạp (chia đều, theo số tiền, theo phần trăm, theo hệ số trọng số, theo từng món cụ thể).

---

## 4. Hướng phát triển tiếp theo (Next Steps / Roadmap)

### Phase 1: Tầng Repository (Data Access Layer)
- Tạo các interface `JpaRepository` cho từng Entity (`UserRepository`, `GroupRepository`, `ExpenseRepository`, `DebtRepository`, `SettlementRepository`, v.v.).
- Thêm các hàm query tùy chỉnh (`findByEmail`, `findByGroupAndUser`, `findActiveMembersByGroupId`, v.v.).

### Phase 2: DTOs & Mappers (Data Transfer Objects)
- Xây dựng Request/Response DTOs cho các tính năng:
  - Auth: `LoginRequest`, `RegisterRequest`, `AuthResponse`.
  - Group: `CreateGroupRequest`, `GroupDetailResponse`.
  - Expense: `CreateExpenseRequest`, `ExpenseResponse`.
  - Settlement: `SettlementRequest`, `SettlementResponse`.

### Phase 3: Authentication & Security (Spring Security 6 + JWT)
- Cấu hình `SecurityConfig`, `JwtAuthenticationFilter`, `PasswordEncoder` (BCrypt).
- Triển khai `CustomUserDetailsService`.

### Phase 4: Business Logic Services & Financial Algorithm
- Implement `UserService`, `GroupService`, `ExpenseService`.
- Xây dựng thuật toán tính toán và tối ưu hóa nợ (Debt Simplification Algorithm - ví dụ Min-Cash-Flow) để giảm tối đa số lượng giao dịch thanh toán trong nhóm.

### Phase 5: REST Controllers & Global Exception Handling
- Xây dựng các `@RestController` theo chuẩn RESTful JSON.
- Triển khai `@RestControllerAdvice` xử lý lỗi tập trung (`ResourceNotFoundException`, `BadRequestException`, `UnauthorizedException`).
