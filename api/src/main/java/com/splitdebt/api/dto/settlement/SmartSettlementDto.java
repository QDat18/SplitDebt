package com.splitdebt.api.dto.settlement;

import java.util.List;

public record SmartSettlementDto(

        Long groupId,

        int beforeTransactionCount,

        int afterTransactionCount,

        List<DebtEdgeDto> suggestions

) {
}