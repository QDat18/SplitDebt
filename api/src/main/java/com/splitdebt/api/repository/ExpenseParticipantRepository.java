package com.splitdebt.api.repository;

import com.splitdebt.api.entity.ExpenseParticipant;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface ExpenseParticipantRepository
        extends JpaRepository<ExpenseParticipant, Long> {

    @EntityGraph(attributePaths = {
            "expense",
            "expense.group",
            "expense.payer",
            "user"
    })
    List<ExpenseParticipant> findByExpenseGroupId(Long groupId);
}