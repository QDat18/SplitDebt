package com.splitdebt.api.repository;

import com.splitdebt.api.entity.Settlement;
import com.splitdebt.api.entity.enums.SettlementStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface SettlementRepository extends JpaRepository<Settlement, Long> {

    List<Settlement> findByGroupId(Long groupId);

    List<Settlement> findByGroupIdAndStatus(Long groupId, SettlementStatus status);

    List<Settlement> findByDebtorIdOrCreditorId(Long debtorId, Long creditorId);
}
