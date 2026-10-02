package com.splitdebt.api.controller;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@Tag(name = "0. System Health", description = "Kiểm tra trạng thái hoạt động của Backend")
@RestController
@RequestMapping("/api")
public class HealthController {

    @Operation(summary = "Kiểm tra tình trạng sống của API (Health check)")
    @GetMapping("/health")
    public ResponseEntity<String> checkHealth() {
        return ResponseEntity.ok("Backend SplitDebt đang chạy tốt và sẵn sàng!");
    }
}