/**
 * Trách nhiệm file: Ánh xạ thực thể UserConsent (chỉ thêm, không sửa) lưu bằng chứng đồng ý.
 */

package com.splitdebt.api.entity;

import com.splitdebt.api.entity.enums.ConsentSource;
import com.splitdebt.api.entity.enums.ConsentType;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(
        name = "user_consents",
        indexes = @Index(name = "idx_user_consents_user_id", columnList = "user_id")
)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserConsent {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Enumerated(EnumType.STRING)
    @Column(name = "consent_type", nullable = false, length = 20)
    private ConsentType consentType;

    @Column(name = "version", nullable = false, length = 20)
    private String version;

    @Column(name = "granted", nullable = false)
    private boolean granted;

    @Enumerated(EnumType.STRING)
    @Column(name = "source", nullable = false, length = 20)
    private ConsentSource source;

    @Column(name = "platform", length = 10)
    private String platform;

    @Column(name = "app_version", length = 20)
    private String appVersion;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;
}

