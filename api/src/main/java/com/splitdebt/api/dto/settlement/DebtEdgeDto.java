package com.splitdebt.api.dto.settlement;

import java.math.BigDecimal;

public record DebtEdgeDto(
        Long debtorId,
        String debtorName,
        Long creditorId,
        String creditorName,
        BigDecimal amount
) {
}