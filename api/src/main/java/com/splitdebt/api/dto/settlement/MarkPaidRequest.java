package com.splitdebt.api.dto.settlement;

public record MarkPaidRequest(
        Long debtorUserId,
        String paymentMethod
) {
}