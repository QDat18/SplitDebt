package com.splitdebt.api.service;

import com.splitdebt.api.dto.settlement.DebtSummaryDto;
import com.splitdebt.api.dto.stats.ChartSliceDto;
import com.splitdebt.api.dto.stats.FinancialStatsDto;
import com.splitdebt.api.entity.Expense;
import com.splitdebt.api.repository.ExpenseRepository;

import lombok.RequiredArgsConstructor;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;

@Service
@RequiredArgsConstructor
public class FinancialStatsService {

    private final ExpenseRepository expenseRepository;
    private final DebtCalculationService debtCalculationService;
    private final GroupAccessService groupAccessService;

    @Transactional(readOnly = true)
    public FinancialStatsDto getStats(
            Long groupId,
            Long userId,
            String rawPeriod
    ) {

        groupAccessService.requireActiveMember(
                groupId,
                userId
        );

        String period =
                normalizePeriod(
                        rawPeriod
                );

        LocalDate today =
                LocalDate.now();

        LocalDate fromDate =
                switch (period) {

                    case "WEEK" ->
                            today.minusDays(6);

                    case "MONTH" ->
                            today.withDayOfMonth(1);

                    case "ALL" ->
                            LocalDate.of(
                                    1970,
                                    1,
                                    1
                            );

                    default ->
                            throw new IllegalStateException(
                                    "Period không hợp lệ"
                            );
                };

        List<Expense> expenses =
                expenseRepository
                        .findByGroupIdAndExpenseDateBetween(
                                groupId,
                                fromDate,
                                today
                        );

        BigDecimal totalExpense =
                expenses.stream()
                        .map(
                                Expense::getTotalAmount
                        )
                        .reduce(
                                BigDecimal.ZERO,
                                BigDecimal::add
                        );

        BigDecimal totalPaidByCurrentUser =
                expenses.stream()
                        .filter(expense ->
                                expense
                                        .getPayer()
                                        .getId()
                                        .equals(userId)
                        )
                        .map(
                                Expense::getTotalAmount
                        )
                        .reduce(
                                BigDecimal.ZERO,
                                BigDecimal::add
                        );

        Map<String, BigDecimal> byCategory =
                new LinkedHashMap<>();

        Map<String, BigDecimal> byMember =
                new LinkedHashMap<>();

        for (Expense expense : expenses) {

            String categoryName =
                    expense.getCategory() == null
                            ? "Khác"
                            : expense
                            .getCategory()
                            .getName();

            byCategory.merge(
                    categoryName,
                    expense.getTotalAmount(),
                    BigDecimal::add
            );

            String payerName =
                    expense
                            .getPayer()
                            .getFullName();

            byMember.merge(
                    payerName,
                    expense.getTotalAmount(),
                    BigDecimal::add
            );
        }

        var snapshot =
                debtCalculationService
                        .calculate(groupId);

        DebtSummaryDto debtSummary =
                debtCalculationService.summary(
                        groupId,
                        userId,
                        snapshot
                );

        return new FinancialStatsDto(
                groupId,
                period,
                fromDate,
                today,
                money(totalExpense),
                money(totalPaidByCurrentUser),
                debtSummary.totalToPay(),
                debtSummary.totalToReceive(),
                toSlices(byCategory),
                toSlices(byMember)
        );
    }

    private List<ChartSliceDto> toSlices(
            Map<String, BigDecimal> source
    ) {

        return source
                .entrySet()
                .stream()
                .sorted(
                        Map.Entry
                                .<String, BigDecimal>
                                        comparingByValue()
                                .reversed()
                )
                .map(entry ->
                        new ChartSliceDto(
                                entry.getKey(),
                                money(
                                        entry.getValue()
                                )
                        )
                )
                .toList();
    }

    private String normalizePeriod(
            String rawPeriod
    ) {

        if (
                rawPeriod == null
                        ||
                        rawPeriod.isBlank()
        ) {
            return "MONTH";
        }

        String period =
                rawPeriod
                        .trim()
                        .toUpperCase(
                                Locale.ROOT
                        );

        if (
                !Set.of(
                        "WEEK",
                        "MONTH",
                        "ALL"
                ).contains(period)
        ) {

            throw new IllegalArgumentException(
                    "period chỉ nhận WEEK, MONTH hoặc ALL"
            );
        }

        return period;
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