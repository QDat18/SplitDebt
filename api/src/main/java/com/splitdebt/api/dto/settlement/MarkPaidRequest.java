/**
 * Trách nhiệm file: Mô tả và kiểm tra payload yêu cầu Mark Paid Request nhận từ API.
 */

package com.splitdebt.api.dto.settlement;

public record MarkPaidRequest(
        Long debtorUserId,
        String paymentMethod
) {
}
