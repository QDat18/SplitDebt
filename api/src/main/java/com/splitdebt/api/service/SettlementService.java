package com.splitdebt.api.service;

import com.splitdebt.api.dto.settlement.ConfirmSettlementRequest;
import com.splitdebt.api.dto.settlement.CreateSettlementRequest;
import com.splitdebt.api.dto.settlement.DebtEdgeDto;
import com.splitdebt.api.dto.settlement.MarkPaidRequest;
import com.splitdebt.api.dto.settlement.SettlementDto;

import com.splitdebt.api.entity.Group;
import com.splitdebt.api.entity.Settlement;
import com.splitdebt.api.entity.User;
import com.splitdebt.api.entity.enums.SettlementStatus;

import com.splitdebt.api.repository.GroupRepository;
import com.splitdebt.api.repository.SettlementRepository;
import com.splitdebt.api.repository.UserRepository;

import lombok.RequiredArgsConstructor;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;

import java.time.LocalDateTime;

import java.util.List;
import java.util.Map;
import java.util.Objects;

@Service
@RequiredArgsConstructor
public class SettlementService {

    private final SettlementRepository settlementRepository;
    private final GroupRepository groupRepository;
    private final UserRepository userRepository;
    private final GroupAccessService groupAccessService;
    private final NotificationService notificationService;
    private final DebtCalculationService debtCalculationService;

    @Transactional(readOnly = true)
    public List<SettlementDto> list(
            Long groupId,
            Long requesterId
    ) {

        groupAccessService.requireActiveMember(
                groupId,
                requesterId
        );

        return settlementRepository
                .findByGroupId(groupId)
                .stream()
                .map(this::toDto)
                .toList();
    }

    @Transactional
    public SettlementDto create(
            Long groupId,
            Long requesterId,
            CreateSettlementRequest request
    ) {

        groupAccessService.requireActiveMember(
                groupId,
                requesterId
        );

        if (
                request.debtorId() == null
                        ||
                        request.creditorId() == null
        ) {
            throw new IllegalArgumentException(
                    "debtorId và creditorId không được để trống"
            );
        }

        validateAmount(
                request.amount()
        );

        if (
                Objects.equals(
                        request.debtorId(),
                        request.creditorId()
                )
        ) {
            throw new IllegalArgumentException(
                    "Người trả và người nhận không được trùng nhau"
            );
        }

        groupAccessService.requireActiveMember(
                groupId,
                request.debtorId()
        );

        groupAccessService.requireActiveMember(
                groupId,
                request.creditorId()
        );

        if (
                !requesterId.equals(
                        request.debtorId()
                )
                        &&
                        !requesterId.equals(
                                request.creditorId()
                        )
        ) {

            throw new IllegalArgumentException(
                    "Chỉ người trả hoặc người nhận mới được tạo settlement"
            );
        }

        /*
         * Kiểm tra giao dịch phải tồn tại
         * trong phương án công nợ hiện tại.
         */
        var snapshot =
                debtCalculationService
                        .calculate(groupId);

        DebtEdgeDto validEdge =
                snapshot.edges()
                        .stream()
                        .filter(edge ->
                                Objects.equals(
                                        edge.debtorId(),
                                        request.debtorId()
                                )
                                        &&
                                        Objects.equals(
                                                edge.creditorId(),
                                                request.creditorId()
                                        )
                        )
                        .findFirst()
                        .orElseThrow(
                                () ->
                                        new IllegalArgumentException(
                                                "Không tồn tại công nợ hợp lệ giữa hai người này"
                                        )
                        );

        BigDecimal requestedAmount =
                money(
                        request.amount()
                );

        if (
                requestedAmount.compareTo(
                        validEdge.amount()
                ) > 0
        ) {

            throw new IllegalArgumentException(
                    "Số tiền settlement vượt quá công nợ hiện tại"
            );
        }

        Group group =
                groupRepository
                        .findById(groupId)
                        .orElseThrow(
                                () ->
                                        new IllegalArgumentException(
                                                "Không tìm thấy nhóm"
                                        )
                        );

        User debtor =
                userRepository
                        .findById(
                                request.debtorId()
                        )
                        .orElseThrow(
                                () ->
                                        new IllegalArgumentException(
                                                "Không tìm thấy người trả"
                                        )
                        );

        User creditor =
                userRepository
                        .findById(
                                request.creditorId()
                        )
                        .orElseThrow(
                                () ->
                                        new IllegalArgumentException(
                                                "Không tìm thấy người nhận"
                                        )
                        );

        Settlement settlement =
                Settlement.builder()
                        .group(group)
                        .debtor(debtor)
                        .creditor(creditor)
                        .amount(
                                requestedAmount
                        )
                        .status(
                                SettlementStatus.PENDING
                        )
                        .requestedAt(
                                LocalDateTime.now()
                        )
                        .build();

        settlement =
                settlementRepository
                        .save(settlement);

        notificationService.createAndPush(
                debtor,
                "Yêu cầu thanh toán",
                "Bạn cần thanh toán "
                        + requestedAmount
                        + " VND cho "
                        + creditor.getFullName(),
                "SETTLEMENT_REQUEST",
                Map.of(
                        "groupId",
                        groupId.toString(),
                        "settlementId",
                        settlement.getId().toString()
                )
        );

        return toDto(settlement);
    }

    @Transactional
    public SettlementDto markPaid(
            Long groupId,
            Long settlementId,
            MarkPaidRequest request
    ) {

        if (
                request.debtorUserId() == null
        ) {
            throw new IllegalArgumentException(
                    "debtorUserId không được để trống"
            );
        }

        Settlement settlement =
                getForGroup(
                        groupId,
                        settlementId
                );

        if (
                !Objects.equals(
                        settlement
                                .getDebtor()
                                .getId(),
                        request.debtorUserId()
                )
        ) {

            throw new IllegalArgumentException(
                    "Chỉ người phải trả mới được đánh dấu đã thanh toán"
            );
        }

        if (
                settlement.getStatus()
                        != SettlementStatus.PENDING
        ) {

            throw new IllegalArgumentException(
                    "Settlement không ở trạng thái PENDING"
            );
        }

        String paymentMethod =
                normalizePaymentMethod(
                        request.paymentMethod()
                );

        settlement.setPaymentMethod(
                paymentMethod
        );

        settlement.setStatus(
                SettlementStatus.PAID
        );

        settlement.setPaidAt(
                LocalDateTime.now()
        );

        Settlement saved =
                settlementRepository
                        .save(settlement);

        notificationService.createAndPush(
                saved.getCreditor(),
                "Xác nhận thanh toán",
                saved.getDebtor().getFullName()
                        + " đã đánh dấu đã thanh toán "
                        + saved.getAmount()
                        + " VND.",
                "SETTLEMENT_PAID",
                Map.of(
                        "groupId",
                        groupId.toString(),
                        "settlementId",
                        saved.getId().toString()
                )
        );

        return toDto(saved);
    }

    @Transactional
    public SettlementDto confirm(
            Long groupId,
            Long settlementId,
            ConfirmSettlementRequest request
    ) {

        if (
                request.creditorUserId() == null
        ) {
            throw new IllegalArgumentException(
                    "creditorUserId không được để trống"
            );
        }

        Settlement settlement =
                getForGroup(
                        groupId,
                        settlementId
                );

        if (
                !Objects.equals(
                        settlement
                                .getCreditor()
                                .getId(),
                        request.creditorUserId()
                )
        ) {

            throw new IllegalArgumentException(
                    "Chỉ người nhận mới được xác nhận đã nhận tiền"
            );
        }

        if (
                settlement.getStatus()
                        != SettlementStatus.PAID
        ) {

            throw new IllegalArgumentException(
                    "Settlement phải ở trạng thái PAID trước khi xác nhận"
            );
        }

        settlement.setStatus(
                SettlementStatus.CONFIRMED
        );

        settlement.setConfirmedAt(
                LocalDateTime.now()
        );

        Settlement saved =
                settlementRepository
                        .save(settlement);

        notificationService.createAndPush(
                saved.getDebtor(),
                "Thanh toán hoàn tất",
                saved.getCreditor().getFullName()
                        + " đã xác nhận nhận "
                        + saved.getAmount()
                        + " VND.",
                "SETTLEMENT_CONFIRMED",
                Map.of(
                        "groupId",
                        groupId.toString(),
                        "settlementId",
                        saved.getId().toString()
                )
        );

        return toDto(saved);
    }

    private Settlement getForGroup(
            Long groupId,
            Long settlementId
    ) {

        Settlement settlement =
                settlementRepository
                        .findWithRelationsById(
                                settlementId
                        )
                        .orElseThrow(
                                () ->
                                        new IllegalArgumentException(
                                                "Không tìm thấy settlement"
                                        )
                        );

        if (
                !Objects.equals(
                        settlement
                                .getGroup()
                                .getId(),
                        groupId
                )
        ) {

            throw new IllegalArgumentException(
                    "Settlement không thuộc nhóm này"
            );
        }

        return settlement;
    }

    private void validateAmount(
            BigDecimal amount
    ) {

        if (
                amount == null
                        ||
                        amount.signum() <= 0
        ) {

            throw new IllegalArgumentException(
                    "Số tiền settlement phải lớn hơn 0"
            );
        }
    }

    private String normalizePaymentMethod(
            String value
    ) {

        if (
                value == null
                        ||
                        value.isBlank()
        ) {

            throw new IllegalArgumentException(
                    "Phải chọn phương thức thanh toán"
            );
        }

        String normalized =
                value.trim()
                        .toUpperCase();

        return switch (normalized) {

            case "CASH",
                 "TIEN_MAT",
                 "TIỀN_MẶT"
                    -> "CASH";

            case "BANK_TRANSFER",
                 "CHUYEN_KHOAN",
                 "CHUYỂN_KHOẢN",
                 "CHUYEN_KHOAN_NGAN_HANG",
                 "CHUYỂN_KHOẢN_NGÂN_HÀNG"
                    -> "BANK_TRANSFER";

            case "MOMO"
                    -> "MOMO";

            case "ZALOPAY"
                    -> "ZALOPAY";

            case "OTHER",
                 "KHAC",
                 "KHÁC"
                    -> "OTHER";

            default ->
                    throw new IllegalArgumentException(
                            "Phương thức thanh toán không hợp lệ"
                    );
        };
    }

    private SettlementDto toDto(
            Settlement settlement
    ) {

        return new SettlementDto(
                settlement.getId(),

                settlement
                        .getGroup()
                        .getId(),

                settlement
                        .getDebtor()
                        .getId(),

                settlement
                        .getDebtor()
                        .getFullName(),

                settlement
                        .getCreditor()
                        .getId(),

                settlement
                        .getCreditor()
                        .getFullName(),

                settlement.getAmount(),

                settlement.getStatus(),

                settlement.getPaymentMethod(),

                settlement.getRequestedAt(),

                settlement.getPaidAt(),

                settlement.getConfirmedAt()
        );
    }

    private BigDecimal money(
            BigDecimal value
    ) {

        return value.setScale(
                2,
                RoundingMode.HALF_UP
        );
    }
}