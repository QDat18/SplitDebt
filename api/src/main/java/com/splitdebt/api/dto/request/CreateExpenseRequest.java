package com.splitdebt.api.dto.request;

import com.splitdebt.api.entity.enums.SplitType;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CreateExpenseRequest {

    private Long groupId;

    private Long categoryId;

    private Long payerId;

    private String title;

    private String description;

    private BigDecimal totalAmount;

    private LocalDate expenseDate;

    private String receiptUrl;

    private SplitType splitType;

    private List<ExpenseParticipantRequest> participants;

    private List<ExpenseItemRequest> items;
}
