package com.splitdebt.api.service;

import com.splitdebt.api.dto.request.CreateExpenseRequest;
import com.splitdebt.api.dto.response.ExpenseResponse;

import java.util.List;

public interface ExpenseService {

    ExpenseResponse createExpense(CreateExpenseRequest request);

    ExpenseResponse getExpenseById(Long id);

    List<ExpenseResponse> getExpensesByGroupId(Long groupId);

    ExpenseResponse updateExpense(Long id, CreateExpenseRequest request);

    void deleteExpense(Long id);
}
