package com.splitdebt.api.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class GroupSettingResponse {

    private Long id;

    private Long groupId;

    private String currencyCode;

    private Integer decimalScale;

    private Boolean smartSettlementEnabled;

    private Boolean requireApproval;

    private BigDecimal monthlyBudgetLimit;

    private Integer autoFreezeDay;

    private Boolean imageOptimizationEnabled;

    private String cloudStorageSync;

    private LocalDateTime createdAt;

    private LocalDateTime updatedAt;
}
