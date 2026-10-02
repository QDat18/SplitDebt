/**
 * Trách nhiệm file: Định nghĩa hoặc thực thi nghiệp vụ Expense Service dùng chung cho các controller backend.
 */

package com.splitdebt.api.service;

import com.splitdebt.api.dto.request.CreateExpenseRequest;
import com.splitdebt.api.dto.response.ExpenseResponse;

import java.util.List;

public interface ExpenseService {

    ExpenseResponse createExpense(CreateExpenseRequest request, Long currentUserId);

    ExpenseResponse getExpenseById(Long id, Long currentUserId);

    List<ExpenseResponse> getExpensesByGroupId(Long groupId, Long currentUserId);

    ExpenseResponse updateExpense(Long id, CreateExpenseRequest request, Long currentUserId);

    void deleteExpense(Long id, Long currentUserId);
}
