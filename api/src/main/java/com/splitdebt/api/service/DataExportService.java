/**
 * Trách nhiệm file: Tổng hợp dữ liệu cá nhân của người dùng đang đăng nhập để xuất JSON.
 */

package com.splitdebt.api.service;

import com.splitdebt.api.dto.privacy.DataExportDto;
import com.splitdebt.api.entity.Expense;
import com.splitdebt.api.entity.ExpenseParticipant;
import com.splitdebt.api.entity.User;
import com.splitdebt.api.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class DataExportService {

    private final UserRepository userRepository;
    private final UserSettingRepository userSettingRepository;
    private final UserConsentRepository userConsentRepository;
    private final GroupMemberRepository groupMemberRepository;
    private final ExpenseRepository expenseRepository;
    private final ExpenseParticipantRepository expenseParticipantRepository;
    private final SettlementRepository settlementRepository;
    private final GroupMessageRepository groupMessageRepository;
    private final NotificationRepository notificationRepository;

    @Transactional(readOnly = true)
    public DataExportDto export(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        DataExportDto.ProfileData profile = DataExportDto.ProfileData.builder()
                .fullName(user.getFullName())
                .email(user.getEmail())
                .phone(user.getPhone())
                .avatarUrl(user.getAvatarUrl())
                .createdAt(user.getCreatedAt())
                .build();

        DataExportDto.SettingsData settings = userSettingRepository.findByUserId(userId)
                .map(s -> DataExportDto.SettingsData.builder()
                        .theme(s.getTheme())
                        .language(s.getLanguage())
                        .currency(s.getCurrency())
                        .notifyOnNewExpense(s.getNotifyOnNewExpense())
                        .notifyOnDebtReminder(s.getNotifyOnDebtReminder())
                        .notifyOnSettlement(s.getNotifyOnSettlement())
                        .notifyOnGroupMessage(s.getNotifyOnGroupMessage())
                        .biometricsEnabled(s.getBiometricsEnabled())
                        .build())
                .orElse(null);

        List<DataExportDto.ConsentRecord> consents = userConsentRepository.findByUserIdOrderByIdAsc(userId)
                .stream()
                .map(c -> DataExportDto.ConsentRecord.builder()
                        .consentType(c.getConsentType())
                        .version(c.getVersion())
                        .granted(c.isGranted())
                        .source(c.getSource())
                        .platform(c.getPlatform())
                        .appVersion(c.getAppVersion())
                        .createdAt(c.getCreatedAt())
                        .build())
                .toList();

        List<DataExportDto.GroupRecord> groups = groupMemberRepository.findByUserId(userId)
                .stream()
                .map(gm -> DataExportDto.GroupRecord.builder()
                        .id(gm.getGroup().getId())
                        .name(gm.getGroup().getName())
                        .role(gm.getRole())
                        .status(gm.getStatus())
                        .joinedAt(gm.getJoinedAt())
                        .build())
                .toList();

        Map<Long, DataExportDto.ExpenseRecord> expenseMap = new LinkedHashMap<>();
        for (Expense e : expenseRepository.findByPayerId(userId)) {
            expenseMap.put(e.getId(), DataExportDto.ExpenseRecord.builder()
                    .id(e.getId())
                    .groupId(e.getGroup().getId())
                    .groupName(e.getGroup().getName())
                    .title(e.getTitle())
                    .totalAmount(e.getTotalAmount())
                    .myShare(BigDecimal.ZERO)
                    .paidByMe(true)
                    .payerName(e.getPayer().getFullName())
                    .expenseDate(e.getExpenseDate())
                    .build());
        }
        for (ExpenseParticipant ep : expenseParticipantRepository.findByUserId(userId)) {
            Expense e = ep.getExpense();
            DataExportDto.ExpenseRecord existing = expenseMap.get(e.getId());
            if (existing != null) {
                existing.setMyShare(ep.getAmount());
            } else {
                expenseMap.put(e.getId(), DataExportDto.ExpenseRecord.builder()
                        .id(e.getId())
                        .groupId(e.getGroup().getId())
                        .groupName(e.getGroup().getName())
                        .title(e.getTitle())
                        .totalAmount(e.getTotalAmount())
                        .myShare(ep.getAmount())
                        .paidByMe(e.getPayer().getId().equals(userId))
                        .payerName(e.getPayer().getFullName())
                        .expenseDate(e.getExpenseDate())
                        .build());
            }
        }

        List<DataExportDto.SettlementRecord> settlements = settlementRepository
                .findByDebtorIdOrCreditorId(userId, userId)
                .stream()
                .map(s -> DataExportDto.SettlementRecord.builder()
                        .id(s.getId())
                        .groupId(s.getGroup().getId())
                        .groupName(s.getGroup().getName())
                        .debtorName(s.getDebtor().getFullName())
                        .creditorName(s.getCreditor().getFullName())
                        .amount(s.getAmount())
                        .status(s.getStatus())
                        .createdAt(s.getRequestedAt())
                        .build())
                .toList();

        List<DataExportDto.MessageRecord> messages = groupMessageRepository
                .findBySenderIdOrderByIdAsc(userId)
                .stream()
                .map(m -> DataExportDto.MessageRecord.builder()
                        .id(m.getId())
                        .groupId(m.getGroup().getId())
                        .content(m.getContent())
                        .createdAt(m.getCreatedAt())
                        .build())
                .toList();

        List<DataExportDto.NotificationRecord> notifications = notificationRepository
                .findByUserIdOrderByCreatedAtDesc(userId)
                .stream()
                .map(n -> DataExportDto.NotificationRecord.builder()
                        .id(n.getId())
                        .title(n.getTitle())
                        .content(n.getContent())
                        .type(n.getType())
                        .isRead(n.getIsRead())
                        .createdAt(n.getCreatedAt())
                        .build())
                .toList();

        return DataExportDto.builder()
                .profile(profile)
                .settings(settings)
                .consents(consents)
                .groups(groups)
                .expenses(List.copyOf(expenseMap.values()))
                .settlements(settlements)
                .messages(messages)
                .notifications(notifications)
                .exportedAt(LocalDateTime.now())
                .build();
    }
}
