package com.splitdebt.api.dto.stats;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

public record FinancialStatsDto(

        Long groupId,

        String period,

        LocalDate fromDate,

        LocalDate toDate,

        BigDecimal totalExpense,

        BigDecimal totalPaidByCurrentUser,

        BigDecimal totalDebtToPay,

        BigDecimal totalDebtToReceive,

        List<ChartSliceDto> byCategory,

        List<ChartSliceDto> byMember

) {
}