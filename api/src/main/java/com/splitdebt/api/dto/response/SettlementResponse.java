package com.splitdebt.api.dto.response;

import com.splitdebt.api.entity.enums.SettlementStatus;
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
public class SettlementResponse {

    private Long id;

    private Long groupId;

    private String groupName;

    private Long debtorId;

    private String debtorName;

    private String debtorAvatar;

    private Long creditorId;

    private String creditorName;

    private String creditorAvatar;

    private BigDecimal amount;

    private SettlementStatus status;

    private String paymentMethod;

    private LocalDateTime requestedAt;

    private LocalDateTime paidAt;

    private LocalDateTime confirmedAt;
}
