package com.splitdebt.api.repository;

import com.splitdebt.api.entity.Expense;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDate;
import java.util.List;

public interface ExpenseRepository
        extends JpaRepository<Expense, Long> {

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
}