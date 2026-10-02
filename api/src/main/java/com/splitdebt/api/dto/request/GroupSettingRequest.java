package com.splitdebt.api.dto.request;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class GroupSettingRequest {

    private String currencyCode;

    private Integer decimalScale;

    private Boolean smartSettlementEnabled;

    private Boolean requireApproval;

    private BigDecimal monthlyBudgetLimit;

    private Integer autoFreezeDay;

    private Boolean imageOptimizationEnabled;

    private String cloudStorageSync;
}
