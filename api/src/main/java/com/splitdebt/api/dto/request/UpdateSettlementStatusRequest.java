package com.splitdebt.api.dto.request;

import com.splitdebt.api.entity.enums.SettlementStatus;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UpdateSettlementStatusRequest {

    private SettlementStatus status;
}
