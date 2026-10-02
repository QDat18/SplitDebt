package com.splitdebt.api.repository;

import com.splitdebt.api.entity.FcmToken;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.EntityGraph;

import java.util.List;
import java.util.Optional;

public interface FcmTokenRepository
        extends JpaRepository<FcmToken, Long> {

    Optional<FcmToken> findByToken(
            String token
    );

    @EntityGraph(attributePaths = "user")
    List<FcmToken> findByUserId(
            Long userId
    );

    void deleteByToken(
            String token
    );
}
