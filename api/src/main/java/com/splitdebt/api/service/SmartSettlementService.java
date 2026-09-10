package com.splitdebt.api.service;

import com.splitdebt.api.dto.settlement.DebtEdgeDto;
import com.splitdebt.api.dto.settlement.NetBalanceDto;
import com.splitdebt.api.dto.settlement.SmartSettlementDto;

import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.PriorityQueue;

@Service
public class SmartSettlementService {

    private static final BigDecimal EPSILON =
            new BigDecimal("0.005");

    public SmartSettlementDto optimize(
            Long groupId,
            int beforeCount,
            List<NetBalanceDto> balances
    ) {

        PriorityQueue<Node> debtors =
                new PriorityQueue<>(
                        Comparator
                                .comparing(Node::amount)
                                .reversed()
                );

        PriorityQueue<Node> creditors =
                new PriorityQueue<>(
                        Comparator
                                .comparing(Node::amount)
                                .reversed()
                );

        for (NetBalanceDto balance : balances) {

            BigDecimal value =
                    money(
                            balance.netBalance()
                    );

            if (
                    value.compareTo(EPSILON)
                            > 0
            ) {

                creditors.add(
                        new Node(
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
                        new Node(
                                balance.userId(),
                                balance.fullName(),
                                value.abs()
                        )
                );
            }
        }

        BigDecimal totalDebtors =
                debtors.stream()
                        .map(Node::amount)
                        .reduce(
                                BigDecimal.ZERO,
                                BigDecimal::add
                        );

        BigDecimal totalCreditors =
                creditors.stream()
                        .map(Node::amount)
                        .reduce(
                                BigDecimal.ZERO,
                                BigDecimal::add
                        );

        if (
                totalDebtors
                        .subtract(
                                totalCreditors
                        )
                        .abs()
                        .compareTo(
                                new BigDecimal("0.01")
                        )
                        > 0
        ) {

            throw new IllegalStateException(
                    "Không thể xén nợ vì tổng tiền "
                            + "phải trả khác tổng tiền được nhận"
            );
        }

        List<DebtEdgeDto> suggestions =
                new ArrayList<>();

        while (
                !debtors.isEmpty()
                        &&
                        !creditors.isEmpty()
        ) {

            Node debtor =
                    debtors.poll();

            Node creditor =
                    creditors.poll();

            BigDecimal transfer =
                    money(
                            debtor.amount()
                                    .min(
                                            creditor.amount()
                                    )
                    );

            if (
                    transfer.compareTo(EPSILON)
                            <= 0
            ) {
                continue;
            }

            suggestions.add(
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
                        new Node(
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
                        new Node(
                                creditor.userId(),
                                creditor.name(),
                                creditorRemaining
                        )
                );
            }
        }

        return new SmartSettlementDto(
                groupId,
                beforeCount,
                suggestions.size(),
                suggestions
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

    private record Node(
            Long userId,
            String name,
            BigDecimal amount
    ) {
    }
}