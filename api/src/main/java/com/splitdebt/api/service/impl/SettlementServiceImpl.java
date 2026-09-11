package com.splitdebt.api.service.impl;

import com.splitdebt.api.dto.request.CreateSettlementRequest;
import com.splitdebt.api.dto.request.UpdateSettlementStatusRequest;
import com.splitdebt.api.dto.response.SettlementResponse;
import com.splitdebt.api.entity.Group;
import com.splitdebt.api.entity.Settlement;
import com.splitdebt.api.entity.User;
import com.splitdebt.api.entity.enums.SettlementStatus;
import com.splitdebt.api.repository.GroupRepository;
import com.splitdebt.api.repository.SettlementRepository;
import com.splitdebt.api.repository.UserRepository;
import com.splitdebt.api.service.SettlementEngineService;
import com.splitdebt.api.service.SettlementService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
public class SettlementServiceImpl implements SettlementService {

    private final SettlementRepository settlementRepository;
    private final GroupRepository groupRepository;
    private final UserRepository userRepository;
    private final SettlementEngineService settlementEngineService;

    @Override
    @Transactional
    public SettlementResponse createSettlement(CreateSettlementRequest request, Long currentUserId) {
        Group group = groupRepository.findById(request.getGroupId())
                .orElseThrow(() -> new IllegalArgumentException("Khong tim thay nhom voi ID: " + request.getGroupId()));

        User debtor = userRepository.findById(currentUserId)
                .orElseThrow(() -> new IllegalArgumentException("Nguoi thuc hien khong hop le: " + currentUserId));

        User creditor = userRepository.findById(request.getCreditorId())
                .orElseThrow(() -> new IllegalArgumentException("Nguoi nhan thanh toan khong hop le: " + request.getCreditorId()));

        if (request.getAmount() == null || request.getAmount().compareTo(java.math.BigDecimal.ZERO) <= 0) {
            throw new IllegalArgumentException("So tien thanh toan phai lon hon 0");
        }

        Settlement settlement = Settlement.builder()
                .group(group)
                .debtor(debtor)
                .creditor(creditor)
                .amount(request.getAmount())
                .status(SettlementStatus.PENDING)
                .paymentMethod(request.getPaymentMethod())
                .requestedAt(LocalDateTime.now())
                .build();

        settlement = settlementRepository.save(settlement);
        return mapToSettlementResponse(settlement);
    }

    @Override
    @Transactional
    public SettlementResponse updateSettlementStatus(Long settlementId, UpdateSettlementStatusRequest request, Long currentUserId) {
        Settlement settlement = settlementRepository.findById(settlementId)
                .orElseThrow(() -> new IllegalArgumentException("Khong tim thay giao dich quyet toan voi ID: " + settlementId));

        SettlementStatus newStatus = request.getStatus();

        if (newStatus == SettlementStatus.PAID) {
            settlement.setStatus(SettlementStatus.PAID);
            settlement.setPaidAt(LocalDateTime.now());
        } else if (newStatus == SettlementStatus.CONFIRMED) {
            settlement.setStatus(SettlementStatus.CONFIRMED);
            settlement.setConfirmedAt(LocalDateTime.now());
            // Recalculate group net balances & debts
            settlementEngineService.recalculateGroupDebts(settlement.getGroup().getId());
        } else if (newStatus == SettlementStatus.CANCELLED) {
            settlement.setStatus(SettlementStatus.CANCELLED);
        }

        settlement = settlementRepository.save(settlement);
        return mapToSettlementResponse(settlement);
    }

    @Override
    @Transactional(readOnly = true)
    public List<SettlementResponse> getSettlementsByGroupId(Long groupId) {
        List<Settlement> settlements = settlementRepository.findByGroupId(groupId);
        List<SettlementResponse> responses = new ArrayList<>();
        for (Settlement s : settlements) {
            responses.add(mapToSettlementResponse(s));
        }
        return responses;
    }

    @Override
    @Transactional(readOnly = true)
    public SettlementResponse getSettlementById(Long settlementId) {
        Settlement settlement = settlementRepository.findById(settlementId)
                .orElseThrow(() -> new IllegalArgumentException("Khong tim thay giao dich quyet toan voi ID: " + settlementId));
        return mapToSettlementResponse(settlement);
    }

    private SettlementResponse mapToSettlementResponse(Settlement s) {
        return SettlementResponse.builder()
                .id(s.getId())
                .groupId(s.getGroup().getId())
                .groupName(s.getGroup().getName())
                .debtorId(s.getDebtor().getId())
                .debtorName(s.getDebtor().getFullName())
                .debtorAvatar(s.getDebtor().getAvatarUrl())
                .creditorId(s.getCreditor().getId())
                .creditorName(s.getCreditor().getFullName())
                .creditorAvatar(s.getCreditor().getAvatarUrl())
                .amount(s.getAmount())
                .status(s.getStatus())
                .paymentMethod(s.getPaymentMethod())
                .requestedAt(s.getRequestedAt())
                .paidAt(s.getPaidAt())
                .confirmedAt(s.getConfirmedAt())
                .build();
    }
}
