package com.splitdebt.api.repository;

import com.splitdebt.api.entity.Expense;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ExpenseRepository extends JpaRepository<Expense, Long> {

    List<Expense> findByGroupId(Long groupId);

    List<Expense> findByPayerId(Long payerId);

    List<Expense> findByGroupIdOrderByExpenseDateDesc(Long groupId);
}
