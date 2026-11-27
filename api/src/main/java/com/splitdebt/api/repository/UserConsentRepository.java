/**
 * Trách nhiệm file: Truy vấn bảng user_consents (chỉ đọc và thêm bản ghi mới).
 */

package com.splitdebt.api.repository;

import com.splitdebt.api.entity.UserConsent;
import com.splitdebt.api.entity.enums.ConsentType;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface UserConsentRepository extends JpaRepository<UserConsent, Long> {
    Optional<UserConsent> findFirstByUserIdAndConsentTypeOrderByIdDesc(Long userId, ConsentType consentType);
    List<UserConsent> findByUserIdOrderByIdAsc(Long userId);
}

