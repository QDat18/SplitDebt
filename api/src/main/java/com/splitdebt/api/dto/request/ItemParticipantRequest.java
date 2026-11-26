/**
 * Trách nhiệm file: Mô tả và kiểm tra payload yêu cầu Item Participant Request nhận từ API.
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
public class ItemParticipantRequest {

    private Long userId;

    private BigDecimal shareAmount;
}
