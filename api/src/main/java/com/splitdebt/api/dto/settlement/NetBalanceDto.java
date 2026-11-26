/**
 * Trách nhiệm file: Mô hình hóa dữ liệu trao đổi Net Balance DTO giữa các tầng và qua API.
 */

package com.splitdebt.api.dto.settlement;

import java.math.BigDecimal;

public record NetBalanceDto(
        Long userId,
        String fullName,
        BigDecimal netBalance
) {
}
