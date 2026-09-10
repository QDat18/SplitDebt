package com.splitdebt.api.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "user_preferences")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserPreferences extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false, unique = true)
    private User user;

    @Column(name = "language", length = 10, nullable = false)
    private String language = "en"; // Default

    @Column(name = "currency", length = 10, nullable = false)
    private String currency = "USD"; // Default

    @Column(name = "theme", length = 20)
    private String theme = "light";
}
