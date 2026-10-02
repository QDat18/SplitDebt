/**
 * Trách nhiệm file: Mô tả và kiểm tra payload yêu cầu Expense Item Request nhận từ API.
 */

package com.splitdebt.api.dto.request;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ExpenseItemRequest {

    private String itemName;

    private BigDecimal quantity;

    private BigDecimal unitPrice;

    private BigDecimal totalPrice;

    private List<ItemParticipantRequest> participants;
}
