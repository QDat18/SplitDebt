package com.splitdebt.api.service;

import com.splitdebt.api.dto.request.CreateSettlementRequest;
import com.splitdebt.api.dto.request.UpdateSettlementStatusRequest;
import com.splitdebt.api.dto.response.SettlementResponse;

import java.util.List;

public interface SettlementService {

    SettlementResponse createSettlement(CreateSettlementRequest request, Long currentUserId);

    SettlementResponse updateSettlementStatus(Long settlementId, UpdateSettlementStatusRequest request, Long currentUserId);

    List<SettlementResponse> getSettlementsByGroupId(Long groupId);

    SettlementResponse getSettlementById(Long settlementId);
}
