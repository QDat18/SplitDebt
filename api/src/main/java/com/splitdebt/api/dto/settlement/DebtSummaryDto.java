package com.splitdebt.api.dto.settlement;

import java.math.BigDecimal;
import java.util.List;

public record DebtSummaryDto(

        Long groupId,

        Long currentUserId,

        BigDecimal totalToPay,

        BigDecimal totalToReceive,

        List<DebtEdgeDto> youOwe,

        List<DebtEdgeDto> owedToYou,

        List<NetBalanceDto> netBalances

) {
}