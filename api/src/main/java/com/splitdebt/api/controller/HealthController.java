/**
 * Trách nhiệm file: Cung cấp các HTTP endpoint của Health Controller, nhận request đã xác thực và chuyển xử lý xuống tầng nghiệp vụ.
 */

package com.splitdebt.api.controller;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import com.splitdebt.api.ocr.ReceiptAdvancedService;
import java.util.Map;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@Tag(name = "0. System Health", description = "Kiểm tra trạng thái hoạt động của Backend")
@RestController
@RequestMapping("/api")
public class HealthController {
    private final JdbcTemplate jdbc;
    private final ReceiptAdvancedService ocr;
    public HealthController(JdbcTemplate jdbc, ReceiptAdvancedService ocr) {
        this.jdbc = jdbc;
        this.ocr = ocr;
    }
    @GetMapping("/ready")
    public ResponseEntity<Map<String,Object>> readiness() {
        boolean database;
        try { database = Integer.valueOf(1).equals(jdbc.queryForObject("SELECT 1", Integer.class)); }
        catch (Exception e) { database = false; }
        var loaded = ocr.loadedModels();
        return ResponseEntity.status(database ? 200 : 503).body(Map.of(
            "service", "SplitDebt", "database", database,
            "ocr", loaded.contains("ocr"), "structure", loaded.contains("structure")));
    }


    @Operation(summary = "Kiểm tra tình trạng sống của API (Health check)")
    @GetMapping("/health")
    public ResponseEntity<String> checkHealth() {
        return ResponseEntity.ok("Backend SplitDebt đang chạy tốt và sẵn sàng!");
    }
}
