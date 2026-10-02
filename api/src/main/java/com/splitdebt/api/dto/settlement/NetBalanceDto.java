package com.splitdebt.api.dto.settlement;

import java.math.BigDecimal;

public record NetBalanceDto(
        Long userId,
        String fullName,
        BigDecimal netBalance
) {
}