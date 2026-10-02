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
public class SimplifiedDebtResponse {

    private Long debtorId;

    private String debtorName;

    private String debtorAvatar;

    private Long creditorId;

    private String creditorName;

    private String creditorAvatar;

    private BigDecimal amount;
}
