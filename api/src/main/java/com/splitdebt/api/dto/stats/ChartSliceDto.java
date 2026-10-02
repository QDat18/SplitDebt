/**
 * Trách nhiệm file: Mô hình hóa dữ liệu trao đổi Chart Slice DTO giữa các tầng và qua API.
 */

package com.splitdebt.api.dto.stats;

import java.math.BigDecimal;

public record ChartSliceDto(
        String label,
        BigDecimal amount
) {
}
