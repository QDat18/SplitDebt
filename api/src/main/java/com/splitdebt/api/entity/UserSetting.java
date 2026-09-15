package com.splitdebt.api.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "user_settings", uniqueConstraints = {
    @UniqueConstraint(name = "uq_user_setting", columnNames = {"user_id"})
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserSetting extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(name = "theme", nullable = false, length = 15)
    @Builder.Default
    private String theme = "LIGHT"; // LIGHT vs DARK

    @Column(name = "language", nullable = false, length = 10)
    @Builder.Default
    private String language = "VI"; // VI vs EN

    @Column(name = "currency", nullable = false, length = 10, columnDefinition = "varchar(10) default 'VND'")
    @Builder.Default
    private String currency = "VND";

    @Column(name = "notify_on_new_expense", nullable = false)
    @Builder.Default
    private Boolean notifyOnNewExpense = true;

    @Column(name = "notify_on_debt_reminder", nullable = false)
    @Builder.Default
    private Boolean notifyOnDebtReminder = true;

    @Column(name = "notify_on_settlement", nullable = false)
    @Builder.Default
    private Boolean notifyOnSettlement = true;

    @Column(name = "biometrics_enabled", nullable = false)
    @Builder.Default
    private Boolean biometricsEnabled = false;
}
