/**
 * Trách nhiệm file: Mô tả và kiểm tra payload yêu cầu Confirm Settlement Request nhận từ API.
 */

package com.splitdebt.api.dto.settlement;

public record ConfirmSettlementRequest(
        Long creditorUserId
) {
}
