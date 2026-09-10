package com.splitdebt.api.service;

import com.splitdebt.api.dto.settlement.DebtEdgeDto;
import com.splitdebt.api.dto.settlement.DebtSummaryDto;
import com.splitdebt.api.dto.settlement.NetBalanceDto;
import com.splitdebt.api.entity.ExpenseParticipant;
import com.splitdebt.api.entity.Settlement;
import com.splitdebt.api.entity.User;
import com.splitdebt.api.entity.enums.SettlementStatus;
import com.splitdebt.api.repository.ExpenseParticipantRepository;
import com.splitdebt.api.repository.SettlementRepository;

import lombok.RequiredArgsConstructor;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.PriorityQueue;

@Service
@RequiredArgsConstructor
public class DebtCalculationService {

    private static final BigDecimal ZERO =
            new BigDecimal("0.00");

    private static final BigDecimal EPSILON =
            new BigDecimal("0.005");

    private final ExpenseParticipantRepository participantRepository;
    private final SettlementRepository settlementRepository;

    @Transactional(readOnly = true)
    public DebtSnapshot calculate(Long groupId) {

        Map<Long, UserInfo> users = new HashMap<>();

        /*
         * Net balance:
         *
         * > 0 : người được nhận tiền
         * < 0 : người phải trả tiền
         *
         * Công thức đúng tài liệu:
         *
         * NetBalance =
         * Tổng tiền được nhận
         * -
         * Tổng tiền phải trả
         */
        Map<Long, BigDecimal> balances =
                new HashMap<>();

        int originalTransactionCount = 0;

        List<ExpenseParticipant> participants =
                participantRepository
                        .findByExpenseGroupId(groupId);

        for (ExpenseParticipant participant : participants) {

            BigDecimal share =
                    participant.getAmount();

            /*
             * amount của expense_participants phải chứa
             * số tiền cuối cùng được phân bổ cho người đó.
             *
             * Với EQUAL / PERCENT / WEIGHT / ITEM,
             * module tạo khoản chi phải tính trước giá trị
             * này và lưu vào cột amount.
             */
            if (share == null || share.signum() <= 0) {
                continue;
            }

            User participantUser =
                    participant.getUser();

            User payer =
                    participant
                            .getExpense()
                            .getPayer();

            users.put(
                    participantUser.getId(),
                    new UserInfo(
                            participantUser.getId(),
                            participantUser.getFullName()
                    )
            );

            users.put(
                    payer.getId(),
                    new UserInfo(
                            payer.getId(),
                            payer.getFullName()
                    )
            );

            /*
             * Người trả chính phần của mình
             * thì không tạo công nợ.
             */
            if (Objects.equals(
                    participantUser.getId(),
                    payer.getId()
            )) {
                continue;
            }

            BigDecimal amount =
                    money(share);

            /*
             * Người tham gia đang nợ:
             * net balance giảm.
             */
            balances.merge(
                    participantUser.getId(),
                    amount.negate(),
                    BigDecimal::add
            );

            /*
             * Người ứng tiền được nhận:
             * net balance tăng.
             */
            balances.merge(
                    payer.getId(),
                    amount,
                    BigDecimal::add
            );

            originalTransactionCount++;
        }

        /*
         * Settlement CONFIRMED là khoản tiền
         * đã thanh toán thật sự.
         *
         * Không được trừ settlement vào cặp nợ gốc,
         * vì Smart Settlement có thể tạo một cặp mới
         * không tồn tại trong expense ban đầu.
         *
         * Ta cập nhật trực tiếp Net Balance.
         */
        List<Settlement> confirmedSettlements =
                settlementRepository
                        .findByGroupIdAndStatus(
                                groupId,
                                SettlementStatus.CONFIRMED
                        );

        for (Settlement settlement : confirmedSettlements) {

            User debtor =
                    settlement.getDebtor();

            User creditor =
                    settlement.getCreditor();

            BigDecimal amount =
                    money(
                            settlement.getAmount()
                    );

            users.put(
                    debtor.getId(),
                    new UserInfo(
                            debtor.getId(),
                            debtor.getFullName()
                    )
            );

            users.put(
                    creditor.getId(),
                    new UserInfo(
                            creditor.getId(),
                            creditor.getFullName()
                    )
            );

            /*
             * Debtor đã trả tiền:
             * nghĩa vụ của debtor giảm.
             *
             * Ví dụ:
             * balance debtor = -100
             * trả 100
             * => -100 + 100 = 0
             */
            balances.merge(
                    debtor.getId(),
                    amount,
                    BigDecimal::add
            );

            /*
             * Creditor đã nhận tiền:
             * quyền được nhận giảm.
             *
             * Ví dụ:
             * balance creditor = +100
             * nhận 100
             * => +100 - 100 = 0
             */
            balances.merge(
                    creditor.getId(),
                    amount.negate(),
                    BigDecimal::add
            );
        }

        users.keySet().forEach(
                id -> balances.putIfAbsent(
                        id,
                        ZERO
                )
        );

        /*
         * Làm tròn số tiền.
         */
        balances.replaceAll(
                (id, value) -> money(value)
        );

        /*
         * Kiểm tra bảo toàn tổng tiền.
         *
         * Tổng net balance toàn nhóm phải bằng 0.
         */
        BigDecimal totalBalance =
                balances.values()
                        .stream()
                        .reduce(
                                ZERO,
                                BigDecimal::add
                        );

        if (totalBalance.abs()
                .compareTo(
                        new BigDecimal("0.01")
                ) > 0) {

            throw new IllegalStateException(
                    "Dữ liệu công nợ không nhất quán. "
                            + "Tổng Net Balance khác 0: "
                            + totalBalance
            );
        }

        List<NetBalanceDto> netBalances =
                balances
                        .entrySet()
                        .stream()
                        .map(entry -> {

                            UserInfo info =
                                    users.getOrDefault(
                                            entry.getKey(),
                                            new UserInfo(
                                                    entry.getKey(),
                                                    "User "
                                                            + entry.getKey()
                                            )
                                    );

                            return new NetBalanceDto(
                                    entry.getKey(),
                                    info.name(),
                                    money(
                                            entry.getValue()
                                    )
                            );
                        })
                        .sorted(
                                Comparator.comparing(
                                        NetBalanceDto::userId
                                )
                        )
                        .toList();

        /*
         * Sinh danh sách nghĩa vụ hiện tại
         * từ Net Balance còn lại.
         *
         * Đây cũng chính là dạng công nợ sau khi
         * đã loại nợ chéo.
         */
        List<DebtEdgeDto> currentEdges =
                generateEdgesFromBalances(
                        netBalances
                );

        return new DebtSnapshot(
                currentEdges,
                netBalances,
                originalTransactionCount
        );
    }

    public DebtSummaryDto summary(
            Long groupId,
            Long currentUserId,
            DebtSnapshot snapshot
    ) {

        List<DebtEdgeDto> youOwe =
                snapshot.edges()
                        .stream()
                        .filter(edge ->
                                Objects.equals(
                                        edge.debtorId(),
                                        currentUserId
                                )
                        )
                        .toList();

        List<DebtEdgeDto> owedToYou =
                snapshot.edges()
                        .stream()
                        .filter(edge ->
                                Objects.equals(
                                        edge.creditorId(),
                                        currentUserId
                                )
                        )
                        .toList();

        BigDecimal totalToPay =
                youOwe.stream()
                        .map(
                                DebtEdgeDto::amount
                        )
                        .reduce(
                                ZERO,
                                BigDecimal::add
                        );

        BigDecimal totalToReceive =
                owedToYou.stream()
                        .map(
                                DebtEdgeDto::amount
                        )
                        .reduce(
                                ZERO,
                                BigDecimal::add
                        );

        return new DebtSummaryDto(
                groupId,
                currentUserId,
                money(totalToPay),
                money(totalToReceive),
                youOwe,
                owedToYou,
                snapshot.netBalances()
        );
    }

    private List<DebtEdgeDto>
    generateEdgesFromBalances(
            List<NetBalanceDto> balances
    ) {

        PriorityQueue<BalanceNode> debtors =
                new PriorityQueue<>(
                        Comparator
                                .comparing(
                                        BalanceNode::amount
                                )
                                .reversed()
                );

        PriorityQueue<BalanceNode> creditors =
                new PriorityQueue<>(
                        Comparator
                                .comparing(
                                        BalanceNode::amount
                                )
                                .reversed()
                );

        for (NetBalanceDto balance : balances) {

            BigDecimal value =
                    money(
                            balance.netBalance()
                    );

            if (value.compareTo(EPSILON) > 0) {

                creditors.add(
                        new BalanceNode(
                                balance.userId(),
                                balance.fullName(),
                                value
                        )
                );

            } else if (
                    value.compareTo(
                            EPSILON.negate()
                    ) < 0
            ) {

                debtors.add(
                        new BalanceNode(
                                balance.userId(),
                                balance.fullName(),
                                value.abs()
                        )
                );
            }
        }

        List<DebtEdgeDto> edges =
                new ArrayList<>();

        while (
                !debtors.isEmpty()
                        &&
                        !creditors.isEmpty()
        ) {

            BalanceNode debtor =
                    debtors.poll();

            BalanceNode creditor =
                    creditors.poll();

            BigDecimal transfer =
                    debtor.amount()
                            .min(
                                    creditor.amount()
                            );

            transfer =
                    money(transfer);

            if (
                    transfer.compareTo(EPSILON)
                            <= 0
            ) {
                continue;
            }

            edges.add(
                    new DebtEdgeDto(
                            debtor.userId(),
                            debtor.name(),
                            creditor.userId(),
                            creditor.name(),
                            transfer
                    )
            );

            BigDecimal debtorRemaining =
                    money(
                            debtor.amount()
                                    .subtract(
                                            transfer
                                    )
                    );

            BigDecimal creditorRemaining =
                    money(
                            creditor.amount()
                                    .subtract(
                                            transfer
                                    )
                    );

            if (
                    debtorRemaining
                            .compareTo(EPSILON)
                            > 0
            ) {

                debtors.add(
                        new BalanceNode(
                                debtor.userId(),
                                debtor.name(),
                                debtorRemaining
                        )
                );
            }

            if (
                    creditorRemaining
                            .compareTo(EPSILON)
                            > 0
            ) {

                creditors.add(
                        new BalanceNode(
                                creditor.userId(),
                                creditor.name(),
                                creditorRemaining
                        )
                );
            }
        }

        return edges;
    }

    private BigDecimal money(
            BigDecimal value
    ) {

        if (value == null) {
            return ZERO;
        }

        return value.setScale(
                2,
                RoundingMode.HALF_UP
        );
    }

    private record UserInfo(
            Long id,
            String name
    ) {
    }

    private record BalanceNode(
            Long userId,
            String name,
            BigDecimal amount
    ) {
    }

    public record DebtSnapshot(
            List<DebtEdgeDto> edges,
            List<NetBalanceDto> netBalances,
            int originalTransactionCount
    ) {
    }
}