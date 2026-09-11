package com.splitdebt.api.repository;

import com.splitdebt.api.entity.Expense;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDate;
import java.util.List;

public interface ExpenseRepository
        extends JpaRepository<Expense, Long> {

    // DEV4: thống kê theo khoảng ngày
    @EntityGraph(attributePaths = {
            "category",
            "payer",
            "group"
    })
    List<Expense> findByGroupIdAndExpenseDateBetween(
            Long groupId,
            LocalDate from,
            LocalDate to
    );

    // DEV2: lấy toàn bộ expense của group
    @EntityGraph(attributePaths = {
            "category",
            "payer",
            "group"
    })
    List<Expense> findByGroupId(Long groupId);

    // DEV2: lịch sử expense mới nhất trước
    @EntityGraph(attributePaths = {
            "category",
            "payer",
            "group"
    })
    List<Expense> findByGroupIdOrderByExpenseDateDesc(Long groupId);
}