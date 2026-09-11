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
public class ItemParticipantResponse {

    private Long id;

    private Long userId;

    private String userName;

    private String userAvatar;

    private BigDecimal shareAmount;
}
