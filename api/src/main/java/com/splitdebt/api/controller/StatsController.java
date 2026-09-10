package com.splitdebt.api.controller;

import com.splitdebt.api.dto.ApiResponse;
import com.splitdebt.api.dto.stats.FinancialStatsDto;
import com.splitdebt.api.service.FinancialStatsService;

import lombok.RequiredArgsConstructor;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/groups/{groupId}/stats")
@RequiredArgsConstructor
public class StatsController {

    private final FinancialStatsService financialStatsService;

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