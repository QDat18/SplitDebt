package com.splitdebt.api.service;

import com.splitdebt.api.entity.FcmToken;
import com.splitdebt.api.entity.User;
import com.splitdebt.api.repository.FcmTokenRepository;
import com.splitdebt.api.repository.UserRepository;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@Slf4j
public class FcmTokenService {

    private final FcmTokenRepository fcmTokenRepository;
    private final UserRepository userRepository;

    @Transactional
    public void registerToken(
            Long userId,
            String token,
            String platform
    ) {

        if (userId == null) {
            throw new IllegalArgumentException(
                    "userId không được để trống"
            );
        }

        if (token == null ||
                token.isBlank()) {
            throw new IllegalArgumentException(
                    "FCM token không được để trống"
            );
        }

        User user =
                userRepository
                        .findById(userId)
                        .orElseThrow(
                                () -> new IllegalArgumentException(
                                        "Không tìm thấy người dùng"
                                )
                        );

        String normalizedPlatform =
                platform == null ||
                platform.isBlank()
                        ? "UNKNOWN"
                        : platform
                        .trim()
                        .toUpperCase();

        FcmToken fcmToken =
                fcmTokenRepository
                        .findByToken(token)
                        .orElseGet(
                                FcmToken::new
                        );

        fcmToken.setUser(user);
        fcmToken.setToken(token);
        fcmToken.setPlatform(
                normalizedPlatform
        );

        fcmTokenRepository.save(
                fcmToken
        );

        log.info(
                "Registered FCM token. userId={}, platform={}",
                userId,
                normalizedPlatform
        );
    }

    @Transactional
    public void removeToken(
            String token
    ) {

        if (token == null ||
                token.isBlank()) {
            return;
        }

        fcmTokenRepository
                .findByToken(token)
                .ifPresent(
                        fcmTokenRepository::delete
                );
    }
}