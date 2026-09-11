package com.splitdebt.api.repository;

import com.splitdebt.api.entity.ExpenseParticipant;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface ExpenseParticipantRepository
        extends JpaRepository<ExpenseParticipant, Long> {

    // DEV4: dùng để tính debt/net balance theo group
    @EntityGraph(attributePaths = {
            "expense",
            "expense.group",
            "expense.payer",
            "user"
    })
    List<ExpenseParticipant> findByExpenseGroupId(Long groupId);

    // DEV2: lấy participants của một expense
    @EntityGraph(attributePaths = {
            "expense",
            "user"
    })
    List<ExpenseParticipant> findByExpenseId(Long expenseId);

    // DEV2: xóa participants khi xóa/cập nhật expense
    void deleteByExpenseId(Long expenseId);
}