package com.splitdebt.api.dto.settlement;

import com.splitdebt.api.entity.enums.SettlementStatus;

import java.math.BigDecimal;
import java.time.LocalDateTime;

public record SettlementDto(

        Long id,

        Long groupId,

        Long debtorId,

        String debtorName,

        Long creditorId,

        String creditorName,

        BigDecimal amount,

        SettlementStatus status,

        String paymentMethod,

        LocalDateTime requestedAt,

        LocalDateTime paidAt,

        LocalDateTime confirmedAt

) {
}