package com.splitdebt.api.dto.request;

import com.splitdebt.api.entity.enums.SplitType;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ExpenseParticipantRequest {

    private Long userId;

    private SplitType splitType;

    private BigDecimal amount;

    private BigDecimal percentage;

    private BigDecimal weight;
}
