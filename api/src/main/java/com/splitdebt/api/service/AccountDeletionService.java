/**
 * Trách nhiệm file: Xử lý nghiệp vụ xoá tài khoản (kiểm tra mật khẩu, kiểm tra công nợ, chuyển OWNER, ẩn danh hoá).
 */

package com.splitdebt.api.service;

import com.splitdebt.api.dto.settlement.NetBalanceDto;
import com.splitdebt.api.entity.Expense;
import com.splitdebt.api.entity.ExpenseItem;
import com.splitdebt.api.entity.GroupMember;
import com.splitdebt.api.entity.GroupMessage;
import com.splitdebt.api.entity.User;
import com.splitdebt.api.entity.enums.GroupMemberStatus;
import com.splitdebt.api.entity.enums.GroupRole;
import com.splitdebt.api.exception.InvalidPasswordException;
import com.splitdebt.api.exception.OutstandingBalanceException;
import com.splitdebt.api.exception.UserNotFoundException;
import com.splitdebt.api.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.*;

@Service
@RequiredArgsConstructor
@Slf4j
public class AccountDeletionService {

    private static final BigDecimal BALANCE_THRESHOLD = new BigDecimal("0.01");

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final GroupMemberRepository groupMemberRepository;
    private final DebtCalculationService debtCalculationService;
    private final GroupRepository groupRepository;
    private final GroupSettingRepository groupSettingRepository;
    private final ExpenseRepository expenseRepository;
    private final ExpenseItemRepository expenseItemRepository;
    private final ItemParticipantRepository itemParticipantRepository;
    private final ExpenseParticipantRepository expenseParticipantRepository;
    private final SettlementRepository settlementRepository;
    private final GroupMessageRepository groupMessageRepository;
    private final FcmTokenRepository fcmTokenRepository;
    private final UserSettingRepository userSettingRepository;
    private final NotificationRepository notificationRepository;
    private final UserActivityLogRepository userActivityLogRepository;
    private final SupabaseStorageService supabaseStorageService;

    @Transactional
    public void deleteAccount(Long userId, String rawPassword) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new UserNotFoundException("Không tìm thấy người dùng"));

        if (rawPassword == null || !passwordEncoder.matches(rawPassword, user.getPasswordHash())) {
            throw new InvalidPasswordException("Mật khẩu không đúng");
        }

        List<GroupMember> memberships = groupMemberRepository.findByUserId(userId);
        List<OutstandingBalanceException.GroupBalance> outstandingGroups = new ArrayList<>();
        for (GroupMember gm : memberships) {
            if (gm.getStatus() != GroupMemberStatus.ACTIVE) continue;
            var snapshot = debtCalculationService.calculate(gm.getGroup().getId());
            BigDecimal balance = snapshot.netBalances().stream()
                    .filter(nb -> Objects.equals(nb.userId(), userId))
                    .map(NetBalanceDto::netBalance)
                    .findFirst()
                    .orElse(BigDecimal.ZERO);
            if (balance.abs().compareTo(BALANCE_THRESHOLD) >= 0) {
                outstandingGroups.add(new OutstandingBalanceException.GroupBalance(
                        gm.getGroup().getId(),
                        gm.getGroup().getName(),
                        balance
                ));
            }
        }
        if (!outstandingGroups.isEmpty()) {
            throw new OutstandingBalanceException(
                    "Bạn cần thanh toán hết công nợ trước khi xoá tài khoản.",
                    outstandingGroups
            );
        }

        for (GroupMember gm : memberships) {
            Long groupId = gm.getGroup().getId();
            if (gm.getRole() == GroupRole.OWNER) {
                List<GroupMember> others = groupMemberRepository
                        .findByGroupIdAndStatus(groupId, GroupMemberStatus.ACTIVE)
                        .stream()
                        .filter(m -> !Objects.equals(m.getUser().getId(), userId))
                        .sorted(Comparator
                                .comparing((GroupMember m) -> m.getRole() == GroupRole.ADMIN ? 0 : 1)
                                .thenComparing(GroupMember::getJoinedAt, Comparator.nullsLast(Comparator.naturalOrder()))
                                .thenComparing(GroupMember::getId))
                        .toList();
                if (others.isEmpty()) {
                    purgeGroup(groupId);
                } else {
                    GroupMember successor = others.get(0);
                    successor.setRole(GroupRole.OWNER);
                    groupMemberRepository.save(successor);
                    groupMemberRepository.delete(gm);
                }
            } else {
                groupMemberRepository.delete(gm);
            }
        }

        List<GroupMessage> messages = groupMessageRepository.findBySenderIdOrderByIdAsc(userId);
        for (GroupMessage m : messages) {
            m.setContent("Tin nhắn đã bị xoá");
        }
        if (!messages.isEmpty()) {
            groupMessageRepository.saveAll(messages);
        }

        fcmTokenRepository.deleteAll(fcmTokenRepository.findByUserId(userId));
        userSettingRepository.findByUserId(userId).ifPresent(userSettingRepository::delete);
        notificationRepository.deleteAll(notificationRepository.findByUserIdOrderByCreatedAtDesc(userId));
        userActivityLogRepository.deleteAll(userActivityLogRepository.findByUserIdOrderByCreatedAtDesc(userId));

        String oldAvatarUrl = user.getAvatarUrl();
        user.setFullName("Người dùng đã xoá");
        user.setEmail("deleted-" + user.getId() + "-" + UUID.randomUUID() + "@deleted.invalid");
        user.setPhone(null);
        user.setAvatarUrl(null);
        user.setPasswordHash(passwordEncoder.encode(UUID.randomUUID().toString()));
        user.setDeletedAt(LocalDateTime.now());
        userRepository.save(user);

        if (oldAvatarUrl != null && !oldAvatarUrl.isBlank()) {
            TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
                @Override
                public void afterCommit() {
                    try {
                        supabaseStorageService.deleteObject(oldAvatarUrl);
                    } catch (Exception e) {
                        log.warn("Không thể xoá avatar trên Supabase sau khi xoá user {}: {}", userId, e.getMessage());
                    }
                }
            });
        }
    }

    private void purgeGroup(Long groupId) {
        List<Expense> expenses = expenseRepository.findByGroupId(groupId);
        for (Expense expense : expenses) {
            List<ExpenseItem> items = expenseItemRepository.findByExpenseId(expense.getId());
            for (ExpenseItem item : items) {
                itemParticipantRepository.deleteByItemId(item.getId());
            }
            expenseItemRepository.deleteByExpenseId(expense.getId());
            expenseParticipantRepository.deleteByExpenseId(expense.getId());
        }
        if (!expenses.isEmpty()) {
            expenseRepository.deleteAll(expenses);
        }
        settlementRepository.deleteAll(settlementRepository.findByGroupId(groupId));
        groupSettingRepository.findByGroupId(groupId).ifPresent(groupSettingRepository::delete);
        groupMessageRepository.deleteByGroupId(groupId);
        groupMemberRepository.deleteAll(groupMemberRepository.findByGroupId(groupId));
        groupRepository.deleteById(groupId);
    }
}

