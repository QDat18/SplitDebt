package com.splitdebt.api.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ExpenseResponse {

    private Long id;

    private Long groupId;

    private String groupName;

    private Long categoryId;

    private String categoryName;

    private String categoryIcon;

    private Long payerId;

    private String payerName;

    private String payerAvatar;

    private String title;

    private String description;

    private BigDecimal totalAmount;

    private LocalDate expenseDate;

    private String receiptUrl;

    private LocalDateTime createdAt;

    private LocalDateTime updatedAt;

    private List<ExpenseParticipantResponse> participants;

    private List<ExpenseItemResponse> items;
}
