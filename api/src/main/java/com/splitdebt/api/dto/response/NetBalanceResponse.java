package com.splitdebt.api.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class NetBalanceResponse {

    private Long userId;

    private String userName;

    private String userAvatar;

    private BigDecimal totalPaid;

    private BigDecimal totalOwed;

    private BigDecimal netBalance; // positive = receives, negative = pays
}
