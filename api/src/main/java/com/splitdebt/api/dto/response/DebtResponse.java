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
public class DebtResponse {

    private Long id;

    private Long groupId;

    private Long debtorId;

    private String debtorName;

    private String debtorAvatar;

    private Long creditorId;

    private String creditorName;

    private String creditorAvatar;

    private BigDecimal amount;

    private String sourceType;

    private String status;

    private LocalDateTime createdAt;

    private LocalDateTime updatedAt;
}
