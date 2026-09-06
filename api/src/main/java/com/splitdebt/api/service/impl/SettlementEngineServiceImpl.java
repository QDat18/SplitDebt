package com.splitdebt.api.service.impl;

import com.splitdebt.api.dto.response.DebtResponse;
import com.splitdebt.api.dto.response.NetBalanceResponse;
import com.splitdebt.api.dto.response.SimplifiedDebtResponse;
import com.splitdebt.api.entity.Debt;
import com.splitdebt.api.entity.Expense;
import com.splitdebt.api.entity.ExpenseParticipant;
import com.splitdebt.api.entity.GroupMember;
import com.splitdebt.api.entity.User;
import com.splitdebt.api.repository.*;
import com.splitdebt.api.service.SettlementEngineService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.*;

@Service
@RequiredArgsConstructor
public class SettlementEngineServiceImpl implements SettlementEngineService {

    private final GroupRepository groupRepository;
    private final GroupMemberRepository groupMemberRepository;
    private final ExpenseRepository expenseRepository;
    private final ExpenseParticipantRepository expenseParticipantRepository;
    private final DebtRepository debtRepository;

    @Override
    @Transactional(readOnly = true)
    public List<NetBalanceResponse> getNetBalances(Long groupId) {
        if (!groupRepository.existsById(groupId)) {
            throw new IllegalArgumentException("Khong tim thay nhom voi ID: " + groupId);
        }

        List<GroupMember> members = groupMemberRepository.findByGroupId(groupId);
        Map<Long, User> userMap = new HashMap<>();
        Map<Long, BigDecimal> paidMap = new HashMap<>();
        Map<Long, BigDecimal> owedMap = new HashMap<>();

        for (GroupMember member : members) {
            Long uId = member.getUser().getId();
            userMap.put(uId, member.getUser());
            paidMap.put(uId, BigDecimal.ZERO);
            owedMap.put(uId, BigDecimal.ZERO);
        }

        List<Expense> expenses = expenseRepository.findByGroupId(groupId);
        for (Expense expense : expenses) {
            Long payerId = expense.getPayer().getId();
            if (paidMap.containsKey(payerId)) {
                paidMap.put(payerId, paidMap.get(payerId).add(expense.getTotalAmount()));
            }

            List<ExpenseParticipant> participants = expenseParticipantRepository.findByExpenseId(expense.getId());
            for (ExpenseParticipant participant : participants) {
                Long pUserId = participant.getUser().getId();
                if (owedMap.containsKey(pUserId) && participant.getAmount() != null) {
                    owedMap.put(pUserId, owedMap.get(pUserId).add(participant.getAmount()));
                }
            }
        }

        List<NetBalanceResponse> results = new ArrayList<>();
        for (Long uId : userMap.keySet()) {
            User u = userMap.get(uId);
            BigDecimal totalPaid = paidMap.getOrDefault(uId, BigDecimal.ZERO).setScale(2, RoundingMode.HALF_UP);
            BigDecimal totalOwed = owedMap.getOrDefault(uId, BigDecimal.ZERO).setScale(2, RoundingMode.HALF_UP);
            BigDecimal netBalance = totalPaid.subtract(totalOwed).setScale(2, RoundingMode.HALF_UP);

            results.add(NetBalanceResponse.builder()
                    .userId(u.getId())
                    .userName(u.getFullName())
                    .userAvatar(u.getAvatarUrl())
                    .totalPaid(totalPaid)
                    .totalOwed(totalOwed)
                    .netBalance(netBalance)
                    .build());
        }

        return results;
    }

    @Override
    @Transactional(readOnly = true)
    public List<SimplifiedDebtResponse> getSimplifiedDebts(Long groupId) {
        List<NetBalanceResponse> netBalances = getNetBalances(groupId);

        PriorityQueue<UserBalance> creditors = new PriorityQueue<>((a, b) -> b.balance.compareTo(a.balance));
        PriorityQueue<UserBalance> debtors = new PriorityQueue<>((a, b) -> b.balance.compareTo(a.balance)); // balance stored positive

        for (NetBalanceResponse nb : netBalances) {
            if (nb.getNetBalance().compareTo(BigDecimal.ZERO) > 0) {
                creditors.add(new UserBalance(nb.getUserId(), nb.getUserName(), nb.getUserAvatar(), nb.getNetBalance()));
            } else if (nb.getNetBalance().compareTo(BigDecimal.ZERO) < 0) {
                debtors.add(new UserBalance(nb.getUserId(), nb.getUserName(), nb.getUserAvatar(), nb.getNetBalance().abs()));
            }
        }

        List<SimplifiedDebtResponse> simplifiedDebts = new ArrayList<>();

        while (!creditors.isEmpty() && !debtors.isEmpty()) {
            UserBalance creditor = creditors.poll();
            UserBalance debtor = debtors.poll();

            BigDecimal minAmount = creditor.balance.min(debtor.balance).setScale(2, RoundingMode.HALF_UP);

            simplifiedDebts.add(SimplifiedDebtResponse.builder()
                    .debtorId(debtor.userId)
                    .debtorName(debtor.userName)
                    .debtorAvatar(debtor.userAvatar)
                    .creditorId(creditor.userId)
                    .creditorName(creditor.userName)
                    .creditorAvatar(creditor.userAvatar)
                    .amount(minAmount)
                    .build());

            creditor.balance = creditor.balance.subtract(minAmount);
            debtor.balance = debtor.balance.subtract(minAmount);

            if (creditor.balance.compareTo(BigDecimal.valueOf(0.01)) >= 0) {
                creditors.add(creditor);
            }

            if (debtor.balance.compareTo(BigDecimal.valueOf(0.01)) >= 0) {
                debtors.add(debtor);
            }
        }

        return simplifiedDebts;
    }

    @Override
    @Transactional(readOnly = true)
    public List<DebtResponse> getGroupDebts(Long groupId) {
        List<Debt> debts = debtRepository.findByGroupId(groupId);
        List<DebtResponse> responses = new ArrayList<>();

        for (Debt d : debts) {
            responses.add(DebtResponse.builder()
                    .id(d.getId())
                    .groupId(d.getGroup().getId())
                    .debtorId(d.getDebtor().getId())
                    .debtorName(d.getDebtor().getFullName())
                    .debtorAvatar(d.getDebtor().getAvatarUrl())
                    .creditorId(d.getCreditor().getId())
                    .creditorName(d.getCreditor().getFullName())
                    .creditorAvatar(d.getCreditor().getAvatarUrl())
                    .amount(d.getAmount())
                    .sourceType(d.getSourceType())
                    .status(d.getStatus())
                    .createdAt(d.getCreatedAt())
                    .updatedAt(d.getUpdatedAt())
                    .build());
        }

        return responses;
    }

    @Override
    @Transactional
    public void recalculateGroupDebts(Long groupId) {
        List<Debt> oldDebts = debtRepository.findByGroupId(groupId);
        debtRepository.deleteAll(oldDebts);

        List<SimplifiedDebtResponse> simplified = getSimplifiedDebts(groupId);
        com.splitdebt.api.entity.Group group = groupRepository.findById(groupId)
                .orElseThrow(() -> new IllegalArgumentException("Khong tim thay nhom voi ID: " + groupId));

        for (SimplifiedDebtResponse sd : simplified) {
            User debtor = groupMemberRepository.findByGroupIdAndUserId(groupId, sd.getDebtorId())
                    .map(GroupMember::getUser)
                    .orElseThrow(() -> new IllegalArgumentException("Nguoi dung khong hop le"));
            User creditor = groupMemberRepository.findByGroupIdAndUserId(groupId, sd.getCreditorId())
                    .map(GroupMember::getUser)
                    .orElseThrow(() -> new IllegalArgumentException("Nguoi dung khong hop le"));

            Debt debt = Debt.builder()
                    .group(group)
                    .debtor(debtor)
                    .creditor(creditor)
                    .amount(sd.getAmount())
                    .sourceType("SMART_SETTLEMENT")
                    .status("ACTIVE")
                    .build();

            debtRepository.save(debt);
        }
    }

    private static class UserBalance {
        Long userId;
        String userName;
        String userAvatar;
        BigDecimal balance;

        UserBalance(Long userId, String userName, String userAvatar, BigDecimal balance) {
            this.userId = userId;
            this.userName = userName;
            this.userAvatar = userAvatar;
            this.balance = balance;
        }
    }
}
