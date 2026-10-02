/**
 * Trách nhiệm file: Mô hình hóa dữ liệu trao đổi Smart Settlement DTO giữa các tầng và qua API.
 */

package com.splitdebt.api.dto.settlement;

import java.util.List;

public record SmartSettlementDto(

        Long groupId,

        int beforeTransactionCount,

        int afterTransactionCount,

        List<DebtEdgeDto> suggestions

) {
}
