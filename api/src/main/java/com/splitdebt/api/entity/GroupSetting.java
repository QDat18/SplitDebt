package com.splitdebt.api.entity;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;

@Entity
@Table(name = "group_settings", uniqueConstraints = {
    @UniqueConstraint(name = "uq_group_setting", columnNames = {"group_id"})
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class GroupSetting extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "group_id", nullable = false)
    private Group group;

    @Column(name = "currency_code", nullable = false, length = 10)
    @Builder.Default
    private String currencyCode = "VND";

    @Column(name = "decimal_scale", nullable = false)
    @Builder.Default
    private Integer decimalScale = 0;

    @Column(name = "smart_settlement_enabled", nullable = false)
    @Builder.Default
    private Boolean smartSettlementEnabled = true;

    @Column(name = "require_approval", nullable = false, columnDefinition = "boolean default false")
    @Builder.Default
    private Boolean requireApproval = false;

    @Column(name = "monthly_budget_limit", precision = 15, scale = 2)
    private BigDecimal monthlyBudgetLimit;

    @Column(name = "auto_freeze_day")
    private Integer autoFreezeDay;

    // AI & OCR Settings (Dev 2)
    @Column(name = "image_optimization_enabled", nullable = false)
    @Builder.Default
    private Boolean imageOptimizationEnabled = true;

    @Column(name = "cloud_storage_sync", nullable = false, length = 20)
    @Builder.Default
    private String cloudStorageSync = "FULL"; 
}
