/**
 * Trách nhiệm file: Mô tả và kiểm tra payload yêu cầu Create Settlement Request nhận từ API.
 */

package com.splitdebt.api.dto.settlement;

import java.math.BigDecimal;

public record CreateSettlementRequest(
        Long debtorId,
        Long creditorId,
        BigDecimal amount
) {
}
