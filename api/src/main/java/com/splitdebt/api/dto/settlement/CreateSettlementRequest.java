package com.splitdebt.api.dto.settlement;

import java.math.BigDecimal;

public record CreateSettlementRequest(
        Long debtorId,
        Long creditorId,
        BigDecimal amount
) {
}