package com.splitdebt.api.controller;

import com.splitdebt.api.ocr.ReceiptAdvancedService;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;
import java.util.List;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class HealthControllerTest {
    @Test void readyWithBothOcrModels() {
        var jdbc = mock(JdbcTemplate.class);
        var ocr = mock(ReceiptAdvancedService.class);
        when(jdbc.queryForObject("SELECT 1", Integer.class)).thenReturn(1);
        when(ocr.loadedModels()).thenReturn(List.of("ocr", "structure"));
        var response = new HealthController(jdbc, ocr).readiness();
        assertEquals(200, response.getStatusCode().value());
        assertEquals(true, response.getBody().get("ocr"));
        assertEquals(true, response.getBody().get("structure"));
    }
    @Test void databaseUnavailableDoesNotLeakDetails() {
        var jdbc = mock(JdbcTemplate.class);
        var ocr = mock(ReceiptAdvancedService.class);
        when(jdbc.queryForObject("SELECT 1", Integer.class)).thenThrow(new RuntimeException("secret"));
        when(ocr.loadedModels()).thenReturn(List.of());
        var response = new HealthController(jdbc, ocr).readiness();
        assertEquals(503, response.getStatusCode().value());
        assertEquals(false, response.getBody().get("database"));
        assertFalse(response.getBody().toString().contains("secret"));
    }
}
