package com.splitdebt.api.dto.response;

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
public class ExpenseParticipantResponse {

    private Long id;

    private Long userId;

    private String userName;

    private String userAvatar;

    private SplitType splitType;

    private BigDecimal amount;

    private BigDecimal percentage;

    private BigDecimal weight;
}
