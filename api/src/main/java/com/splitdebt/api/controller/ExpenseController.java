package com.splitdebt.api.controller;

import com.splitdebt.api.dto.ApiResponse;
import com.splitdebt.api.dto.request.CreateExpenseRequest;
import com.splitdebt.api.dto.response.ExpenseResponse;
import com.splitdebt.api.service.ExpenseService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/expenses")
@RequiredArgsConstructor
public class ExpenseController {

    private final ExpenseService expenseService;

    // POST /api/v1/expenses - Tao khoản chi tiêu moi (ho tro 4 thuat toan chia tien + chia theo mon)
    @PostMapping
    public ResponseEntity<ApiResponse<ExpenseResponse>> createExpense(@RequestBody CreateExpenseRequest request) {
        ExpenseResponse response = expenseService.createExpense(request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success(response, "Tao khoan chi tieu thanh cong"));
    }

    // GET /api/v1/expenses/{id} - Xem chi tiet khoản chi tieu
    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<ExpenseResponse>> getExpenseById(@PathVariable Long id) {
        ExpenseResponse response = expenseService.getExpenseById(id);
        return ResponseEntity.ok(ApiResponse.success(response, "Lay chi tiet khoan chi tieu thanh cong"));
    }

    // GET /api/v1/expenses/group/{groupId} - Lay tat ca chi tieu trong nhom
    @GetMapping("/group/{groupId}")
    public ResponseEntity<ApiResponse<List<ExpenseResponse>>> getExpensesByGroupId(@PathVariable Long groupId) {
        List<ExpenseResponse> response = expenseService.getExpensesByGroupId(groupId);
        return ResponseEntity.ok(ApiResponse.success(response, "Lay danh sach chi tieu trong nhom thanh cong"));
    }

    // PUT /api/v1/expenses/{id} - Cap nhat khoản chi tieu (check khoa logic khi da chot nợ)
    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<ExpenseResponse>> updateExpense(
            @PathVariable Long id,
            @RequestBody CreateExpenseRequest request) {
        ExpenseResponse response = expenseService.updateExpense(id, request);
        return ResponseEntity.ok(ApiResponse.success(response, "Cap nhat khoan chi tieu thanh cong"));
    }

    // DELETE /api/v1/expenses/{id} - Xoa khoản chi tieu (check khoa logic khi da chot nợ)
    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteExpense(@PathVariable Long id) {
        expenseService.deleteExpense(id);
        return ResponseEntity.ok(ApiResponse.success(null, "Xoa khoan chi tieu thanh cong"));
    }
}
