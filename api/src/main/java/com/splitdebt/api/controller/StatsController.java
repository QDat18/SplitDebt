/**
 * Trách nhiệm file: Cung cấp các HTTP endpoint của Stats Controller, nhận request đã xác thực và chuyển xử lý xuống tầng nghiệp vụ.
 */

package com.splitdebt.api.controller;

import com.splitdebt.api.dto.ApiResponse;
import com.splitdebt.api.dto.stats.FinancialStatsDto;
import com.splitdebt.api.service.FinancialStatsService;
import com.splitdebt.api.repository.UserRepository;
import com.splitdebt.api.exception.UserNotFoundException;

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
    private final UserRepository userRepository;

    private Long currentUserId() {
        String email = org.springframework.security.core.context.SecurityContextHolder
                .getContext().getAuthentication().getName();
        return userRepository.findByEmail(email)
                .orElseThrow(() -> new UserNotFoundException("Không tìm thấy tài khoản"))
                .getId();
    }

    @Operation(summary = "Lấy dữ liệu thống kê tài chính của nhóm", description = "Trả về tổng chi tiêu, công nợ và số liệu theo kỳ (MONTH, YEAR, ALL).")
    @GetMapping
    public ResponseEntity<ApiResponse<FinancialStatsDto>> stats(
            @PathVariable Long groupId,
            @RequestParam(defaultValue = "MONTH")
            String period
    ) {

        Long userId = currentUserId();

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
