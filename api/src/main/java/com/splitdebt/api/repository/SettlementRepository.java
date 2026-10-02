package com.splitdebt.api.repository;

import com.splitdebt.api.entity.Settlement;
import com.splitdebt.api.entity.enums.SettlementStatus;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface SettlementRepository
        extends JpaRepository<Settlement, Long> {

    @EntityGraph(attributePaths = {
            "group",
            "debtor",
            "creditor"
    })
    List<Settlement> findByGroupId(Long groupId);

    @EntityGraph(attributePaths = {
            "group",
            "debtor",
            "creditor"
    })
    List<Settlement> findByGroupIdAndStatus(
            Long groupId,
            SettlementStatus status
    );

    @Query("""
        SELECT s
        FROM Settlement s
        JOIN FETCH s.group
        JOIN FETCH s.debtor
        JOIN FETCH s.creditor
        WHERE s.id = :id
    """)
    Optional<Settlement> findWithRelationsById(
            @Param("id") Long id
    );
}