/**
 * Trách nhiệm file: Mô tả và kiểm tra payload yêu cầu Create Settlement Request nhận từ API.
 */

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
public class CreateSettlementRequest {

    private Long groupId;

    private Long creditorId;

    private BigDecimal amount;

    private String paymentMethod;
}
