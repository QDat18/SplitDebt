package com.splitdebt.api.controller;

import com.splitdebt.api.dto.ApiResponse;
import com.splitdebt.api.dto.settlement.CreateSettlementRequest;
import com.splitdebt.api.dto.settlement.DebtSummaryDto;
import com.splitdebt.api.dto.settlement.MarkPaidRequest;
import com.splitdebt.api.dto.settlement.ConfirmSettlementRequest;
import com.splitdebt.api.dto.settlement.SettlementDto;
import com.splitdebt.api.dto.settlement.SmartSettlementDto;

import com.splitdebt.api.service.DebtCalculationService;
import com.splitdebt.api.service.GroupAccessService;
import com.splitdebt.api.service.SettlementService;
import com.splitdebt.api.service.SmartSettlementService;

import lombok.RequiredArgsConstructor;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/groups/{groupId}")
@RequiredArgsConstructor
public class DebtSettlementController {

    private final GroupAccessService groupAccessService;

    private final DebtCalculationService debtCalculationService;

    private final SmartSettlementService smartSettlementService;

    private final SettlementService settlementService;

    private final com.splitdebt.api.repository.UserRepository userRepository;

    private Long currentUserId() {
        String email = org.springframework.security.core.context.SecurityContextHolder
                .getContext().getAuthentication().getName();
        return userRepository.findByEmail(email).orElseThrow().getId();
    }

    @GetMapping("/debts")
    public ResponseEntity<ApiResponse<DebtSummaryDto>>
    getDebts(
            @PathVariable Long groupId,
            @RequestParam Long userId
    ) {

        groupAccessService.requireActiveMember(
                groupId,
                userId
        );

        var snapshot =
                debtCalculationService
                        .calculate(groupId);

        DebtSummaryDto result =
                debtCalculationService.summary(
                        groupId,
                        userId,
                        snapshot
                );

        return ResponseEntity.ok(
                ApiResponse.success(
                        result,
                        "Tải công nợ thành công"
                )
        );
    }

    @GetMapping("/smart-settlement")
    public ResponseEntity<ApiResponse<SmartSettlementDto>>
    smartSettlement(
            @PathVariable Long groupId,
            @RequestParam Long userId
    ) {

        groupAccessService.requireActiveMember(
                groupId,
                userId
        );

        var snapshot =
                debtCalculationService
                        .calculate(groupId);

        SmartSettlementDto result =
                smartSettlementService.optimize(
                        groupId,
                        snapshot.originalTransactionCount(),
                        snapshot.netBalances()
                );

        return ResponseEntity.ok(
                ApiResponse.success(
                        result,
                        result.suggestions().isEmpty()
                                ? "Nhóm đã cân bằng"
                                : "Xén nợ thành công"
                )
        );
    }

    @GetMapping("/settlements")
    public ResponseEntity<
            ApiResponse<List<SettlementDto>>
            > getSettlements(
            @PathVariable Long groupId,
            @RequestParam Long userId
    ) {

        return ResponseEntity.ok(
                ApiResponse.success(
                        settlementService.list(
                                groupId,
                                userId
                        ),
                        "Tải danh sách quyết toán thành công"
                )
        );
    }

    @PostMapping("/settlements")
    public ResponseEntity<ApiResponse<SettlementDto>>
    createSettlement(
            @PathVariable Long groupId,
            @RequestParam Long userId,
            @RequestBody CreateSettlementRequest request
    ) {

        return ResponseEntity.ok(
                ApiResponse.success(
                        settlementService.create(
                                groupId,
                                userId,
                                request
                        ),
                        "Tạo giao dịch quyết toán thành công"
                )
        );
    }

    @PostMapping("/settlements/{settlementId}/pay")
    public ResponseEntity<ApiResponse<SettlementDto>>
    markPaid(
            @PathVariable Long groupId,
            @PathVariable Long settlementId,
            @RequestBody MarkPaidRequest request
    ) {

        return ResponseEntity.ok(
                ApiResponse.success(
                        settlementService.markPaid(
                                groupId,
                                settlementId,
                                new MarkPaidRequest(currentUserId(), request.paymentMethod())
                        ),
                        "Đã ghi nhận thanh toán, chờ xác nhận"
                )
        );
    }

    @PostMapping("/settlements/{settlementId}/confirm")
    public ResponseEntity<ApiResponse<SettlementDto>>
    confirm(
            @PathVariable Long groupId,
            @PathVariable Long settlementId,
            @RequestBody ConfirmSettlementRequest request
    ) {

        return ResponseEntity.ok(
                ApiResponse.success(
                        settlementService.confirm(
                                groupId,
                                settlementId,
                                new ConfirmSettlementRequest(currentUserId())
                        ),
                        "Thanh toán đã hoàn tất"
                )
        );
    }
}
