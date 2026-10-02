package com.splitdebt.api.repository;

import com.splitdebt.api.entity.ExpenseItem;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ExpenseItemRepository extends JpaRepository<ExpenseItem, Long> {

    List<ExpenseItem> findByExpenseId(Long expenseId);

    void deleteByExpenseId(Long expenseId);
}
