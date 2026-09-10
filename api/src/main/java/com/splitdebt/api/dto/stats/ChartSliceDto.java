package com.splitdebt.api.dto.stats;

import java.math.BigDecimal;

public record ChartSliceDto(
        String label,
        BigDecimal amount
) {
}