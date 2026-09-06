package com.splitdebt.api.repository;

import com.splitdebt.api.entity.ExpenseParticipant;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ExpenseParticipantRepository extends JpaRepository<ExpenseParticipant, Long> {

    List<ExpenseParticipant> findByExpenseId(Long expenseId);

    List<ExpenseParticipant> findByUserId(Long userId);

    Optional<ExpenseParticipant> findByExpenseIdAndUserId(Long expenseId, Long userId);

    void deleteByExpenseId(Long expenseId);
}
