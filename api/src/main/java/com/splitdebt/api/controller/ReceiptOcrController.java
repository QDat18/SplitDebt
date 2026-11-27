package com.splitdebt.api.controller;

import com.splitdebt.api.dto.ApiResponse;
import com.splitdebt.api.ocr.ReceiptOcrService;
import com.splitdebt.api.ocr.ReceiptParser;
import com.splitdebt.api.ocr.ReceiptLayoutAnalyzer;
import com.splitdebt.api.ocr.ReceiptAdvancedService;
import com.splitdebt.api.ocr.ReceiptAdvancedAnalysis;
import java.util.List;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/receipts")
public class ReceiptOcrController {
    private final ReceiptOcrService service;
    private final ReceiptAdvancedService advanced;
    public ReceiptOcrController(ReceiptOcrService service, ReceiptAdvancedService advanced) { this.service = service; this.advanced = advanced; }
    @PostMapping(value="/advanced",consumes="multipart/form-data")
    public ApiResponse<List<ReceiptAdvancedAnalysis.Candidate>> advanced(@RequestParam("image") MultipartFile image, @RequestParam(defaultValue="ocr") String mode) {
        return ApiResponse.ok(advanced.scan(image,mode));
    }
    public record ParseRequest(String text, List<ReceiptLayoutAnalyzer.Word> words) {}
    @PostMapping("/parse")
    public ApiResponse<ReceiptParser.Result> parse(@RequestBody ParseRequest body) {
        String text = body == null ? null : body.text();
        if (text == null || text.isBlank() || text.length() > 24000 || (body.words() != null && body.words().size() > 1500)) {
            throw new org.springframework.web.server.ResponseStatusException(
                org.springframework.http.HttpStatus.BAD_REQUEST, "Văn bản OCR không hợp lệ.");
        }
        return ApiResponse.ok(ReceiptLayoutAnalyzer.analyze(text, body.words()));
    }
    @GetMapping("/capabilities")
    public ApiResponse<Map<String,Boolean>> capabilities() { return ApiResponse.ok(Map.of("handwriting",service.handwritingAvailable())); }
    @PostMapping(value="/scan",consumes="multipart/form-data")
    public ApiResponse<ReceiptParser.Result> scan(@RequestParam("image") MultipartFile image, @RequestParam(defaultValue="false") boolean handwriting) {
        return ApiResponse.ok(service.scan(image,handwriting));
    }
}
