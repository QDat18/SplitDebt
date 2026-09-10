package com.splitdebt.api.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "group_settings")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class GroupSettings extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "group_id", nullable = false, unique = true)
    private Group group;

    @Column(name = "require_approval", nullable = false)
    private Boolean requireApproval = false;

    @Column(name = "default_currency", length = 10, nullable = false)
    private String defaultCurrency = "USD";
}
