/**
 * Trách nhiệm file: DTO chứa toàn bộ dữ liệu cá nhân của người dùng cho endpoint /api/users/me/data-export.
 */

package com.splitdebt.api.dto.privacy;

import com.splitdebt.api.entity.enums.ConsentSource;
import com.splitdebt.api.entity.enums.ConsentType;
import com.splitdebt.api.entity.enums.GroupMemberStatus;
import com.splitdebt.api.entity.enums.GroupRole;
import com.splitdebt.api.entity.enums.SettlementStatus;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DataExportDto {

    private ProfileData profile;
    private SettingsData settings;
    private List<ConsentRecord> consents;
    private List<GroupRecord> groups;
    private List<ExpenseRecord> expenses;
    private List<SettlementRecord> settlements;
    private List<MessageRecord> messages;
    private List<NotificationRecord> notifications;
    private LocalDateTime exportedAt;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ProfileData {
        private String fullName;
        private String email;
        private String phone;
        private String avatarUrl;
        private LocalDateTime createdAt;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class SettingsData {
        private String theme;
        private String language;
        private String currency;
        private Boolean notifyOnNewExpense;
        private Boolean notifyOnDebtReminder;
        private Boolean notifyOnSettlement;
        private Boolean notifyOnGroupMessage;
        private Boolean biometricsEnabled;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ConsentRecord {
        private ConsentType consentType;
        private String version;
        private boolean granted;
        private ConsentSource source;
        private String platform;
        private String appVersion;
        private LocalDateTime createdAt;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class GroupRecord {
        private Long id;
        private String name;
        private GroupRole role;
        private GroupMemberStatus status;
        private LocalDateTime joinedAt;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ExpenseRecord {
        private Long id;
        private Long groupId;
        private String groupName;
        private String title;
        private BigDecimal totalAmount;
        private BigDecimal myShare;
        private boolean paidByMe;
        private String payerName;
        private LocalDate expenseDate;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class SettlementRecord {
        private Long id;
        private Long groupId;
        private String groupName;
        private String debtorName;
        private String creditorName;
        private BigDecimal amount;
        private SettlementStatus status;
        private LocalDateTime createdAt;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class MessageRecord {
        private Long id;
        private Long groupId;
        private String content;
        private LocalDateTime createdAt;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class NotificationRecord {
        private Long id;
        private String title;
        private String content;
        private String type;
        private Boolean isRead;
        private LocalDateTime createdAt;
    }
}

