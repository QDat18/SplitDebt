package com.splitdebt.api.controller;

import com.splitdebt.api.dto.ApiResponse;
import com.splitdebt.api.dto.stats.FinancialStatsDto;
import com.splitdebt.api.service.FinancialStatsService;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@Tag(name = "7. Statistics", description = "Các API báo cáo và thống kê tài chính")
@RestController
@RequestMapping("/api/groups/{groupId}/stats")
@RequiredArgsConstructor
public class StatsController {

    private final FinancialStatsService financialStatsService;

    @Operation(summary = "Lấy dữ liệu thống kê tài chính của nhóm", description = "Trả về tổng chi tiêu, công nợ và số liệu theo kỳ (MONTH, YEAR, ALL).")
    @GetMapping
    public ResponseEntity<ApiResponse<FinancialStatsDto>> stats(
            @PathVariable Long groupId,
            @RequestParam Long userId,
            @RequestParam(defaultValue = "MONTH")
            String period
    ) {

        return ResponseEntity.ok(
                ApiResponse.success(
                        financialStatsService.getStats(
                                groupId,
                                userId,
                                period
                        ),
                        "Tải thống kê thành công"
                )
        );
    }
}