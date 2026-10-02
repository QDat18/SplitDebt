package com.splitdebt.api.service;

import com.splitdebt.api.dto.response.DebtResponse;
import com.splitdebt.api.dto.response.NetBalanceResponse;
import com.splitdebt.api.dto.response.SimplifiedDebtResponse;

import java.util.List;

public interface SettlementEngineService {

    List<NetBalanceResponse> getNetBalances(Long groupId);

    List<SimplifiedDebtResponse> getSimplifiedDebts(Long groupId);

    List<DebtResponse> getGroupDebts(Long groupId);

    void recalculateGroupDebts(Long groupId);
}
