package com.splitdebt.api.repository;

import com.splitdebt.api.entity.Debt;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface DebtRepository extends JpaRepository<Debt, Long> {

    List<Debt> findByGroupId(Long groupId);

    List<Debt> findByGroupIdAndStatus(Long groupId, String status);

    Optional<Debt> findByGroupIdAndDebtorIdAndCreditorId(Long groupId, Long debtorId, Long creditorId);

    List<Debt> findByDebtorIdOrCreditorId(Long debtorId, Long creditorId);
}
