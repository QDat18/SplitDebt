package com.splitdebt.api.controller;

import com.splitdebt.api.dto.ApiResponse;
import com.splitdebt.api.dto.request.CreateSettlementRequest;
import com.splitdebt.api.dto.request.UpdateSettlementStatusRequest;
import com.splitdebt.api.dto.response.DebtResponse;
import com.splitdebt.api.dto.response.NetBalanceResponse;
import com.splitdebt.api.dto.response.SettlementResponse;
import com.splitdebt.api.dto.response.SimplifiedDebtResponse;
import com.splitdebt.api.service.SettlementEngineService;
import com.splitdebt.api.service.SettlementService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/settlements")
@RequiredArgsConstructor
public class SettlementController {

    private final SettlementEngineService settlementEngineService;
    private final SettlementService settlementService;

    // --- ENGINE TASK BE2-SET-01: DƯ NỢ RÒNG & XÉN NỢ TỐI ƯU ---

    // GET /api/v1/settlements/net-balances/group/{groupId} - Lay dư nợ ròng từng thanh vien
    @GetMapping("/net-balances/group/{groupId}")
    public ResponseEntity<ApiResponse<List<NetBalanceResponse>>> getNetBalances(@PathVariable Long groupId) {
        List<NetBalanceResponse> response = settlementEngineService.getNetBalances(groupId);
        return ResponseEntity.ok(ApiResponse.success(response, "Lay du no rong nhom thanh cong"));
    }

    // GET /api/v1/settlements/simplified/group/{groupId} - Lay bảng xén nợ tối ưu (Min-Cash-Flow)
    @GetMapping("/simplified/group/{groupId}")
    public ResponseEntity<ApiResponse<List<SimplifiedDebtResponse>>> getSimplifiedDebts(@PathVariable Long groupId) {
        List<SimplifiedDebtResponse> response = settlementEngineService.getSimplifiedDebts(groupId);
        return ResponseEntity.ok(ApiResponse.success(response, "Lay bang xen no toi uu thanh cong"));
    }

    // GET /api/v1/settlements/debts/group/{groupId} - Lay danh sach cong no hien tai
    @GetMapping("/debts/group/{groupId}")
    public ResponseEntity<ApiResponse<List<DebtResponse>>> getGroupDebts(@PathVariable Long groupId) {
        List<DebtResponse> response = settlementEngineService.getGroupDebts(groupId);
        return ResponseEntity.ok(ApiResponse.success(response, "Lay danh sach cong no thanh cong"));
    }

    // --- STATE TASK BE2-SET-02: QUY TRÌNH QUYẾT TOÁN 2 CHIỀU ---

    // POST /api/v1/settlements - Tạo yêu cau quyet toan / tra tien
    @PostMapping
    public ResponseEntity<ApiResponse<SettlementResponse>> createSettlement(
            @RequestBody CreateSettlementRequest request,
            @RequestHeader(value = "X-User-Id", defaultValue = "1") Long currentUserId) {
        SettlementResponse response = settlementService.createSettlement(request, currentUserId);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success(response, "Tao yeu cau quyet toan thanh cong"));
    }

    // PUT /api/v1/settlements/{settlementId}/status - Cap nhat trang thai thanh toan (PAID, CONFIRMED, CANCELLED)
    @PutMapping("/{settlementId}/status")
    public ResponseEntity<ApiResponse<SettlementResponse>> updateSettlementStatus(
            @PathVariable Long settlementId,
            @RequestBody UpdateSettlementStatusRequest request,
            @RequestHeader(value = "X-User-Id", defaultValue = "1") Long currentUserId) {
        SettlementResponse response = settlementService.updateSettlementStatus(settlementId, request, currentUserId);
        return ResponseEntity.ok(ApiResponse.success(response, "Cap nhat trang thai quyet toan thanh cong"));
    }

    // GET /api/v1/settlements/group/{groupId} - Lay danh sach lich su quyet toan
    @GetMapping("/group/{groupId}")
    public ResponseEntity<ApiResponse<List<SettlementResponse>>> getSettlementsByGroupId(@PathVariable Long groupId) {
        List<SettlementResponse> response = settlementService.getSettlementsByGroupId(groupId);
        return ResponseEntity.ok(ApiResponse.success(response, "Lay danh sach quyet toan thanh cong"));
    }

    // GET /api/v1/settlements/{settlementId} - Chi tiet phieu quyet toan
    @GetMapping("/{settlementId}")
    public ResponseEntity<ApiResponse<SettlementResponse>> getSettlementById(@PathVariable Long settlementId) {
        SettlementResponse response = settlementService.getSettlementById(settlementId);
        return ResponseEntity.ok(ApiResponse.success(response, "Lay chi tiet phieu quyet toan thanh cong"));
    }
}
