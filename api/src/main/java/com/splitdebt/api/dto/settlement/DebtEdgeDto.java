/**
 * Trách nhiệm file: Mô hình hóa dữ liệu trao đổi Debt Edge DTO giữa các tầng và qua API.
 */

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
