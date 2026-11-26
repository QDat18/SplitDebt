/**
 * Trách nhiệm file: Xử lý nghiệp vụ ghi nhận, kiểm tra và cập nhật bằng chứng đồng ý của người dùng.
 */

package com.splitdebt.api.service;

import com.splitdebt.api.config.LegalProperties;
import com.splitdebt.api.dto.consent.ConsentItemDto;
import com.splitdebt.api.dto.consent.ConsentStatusDto;
import com.splitdebt.api.dto.consent.ConsentUpdateRequest;
import com.splitdebt.api.dto.consent.RegisterConsentsDto;
import com.splitdebt.api.entity.User;
import com.splitdebt.api.entity.UserConsent;
import com.splitdebt.api.entity.enums.ConsentSource;
import com.splitdebt.api.entity.enums.ConsentType;
import com.splitdebt.api.repository.UserConsentRepository;
import com.splitdebt.api.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Service
@RequiredArgsConstructor
public class ConsentService {

    private static final String AGE_16_VERSION = "1";
    private static final String MISSING_CONSENT_MSG =
            "Bạn cần đồng ý Điều khoản, Chính sách và xác nhận đủ 16 tuổi để đăng ký.";
    private static final String STALE_VERSION_MSG =
            "Văn bản đã được cập nhật, vui lòng tải lại.";
    private static final String WITHDRAW_REQUIRED_MSG =
            "Để rút lại đồng ý bắt buộc, hãy xoá tài khoản.";

    private final UserConsentRepository userConsentRepository;
    private final UserRepository userRepository;
    private final LegalProperties legalProperties;

    @Transactional
    public void recordRegistration(User user, RegisterConsentsDto c, String platform, String appVersion) {
        if (c == null
                || isBlank(c.getTermsVersion())
                || isBlank(c.getPrivacyVersion())
                || !Boolean.TRUE.equals(c.getAgeConfirmed())) {
            throw new IllegalArgumentException(MISSING_CONSENT_MSG);
        }
        if (!legalProperties.getTermsVersion().equals(c.getTermsVersion().trim())
                || !legalProperties.getPrivacyVersion().equals(c.getPrivacyVersion().trim())) {
            throw new IllegalArgumentException(STALE_VERSION_MSG);
        }

        List<UserConsent> records = List.of(
                buildRecord(user, ConsentType.TERMS, legalProperties.getTermsVersion(), true,
                        ConsentSource.REGISTER, platform, appVersion),
                buildRecord(user, ConsentType.PRIVACY, legalProperties.getPrivacyVersion(), true,
                        ConsentSource.REGISTER, platform, appVersion),
                buildRecord(user, ConsentType.AGE_16, AGE_16_VERSION, true,
                        ConsentSource.REGISTER, platform, appVersion)
        );
        userConsentRepository.saveAll(records);
    }

    @Transactional(readOnly = true)
    public ConsentStatusDto status(Long userId) {
        boolean required = reconsentRequired(userId);
        Optional<UserConsent> latestPrivacy = userConsentRepository
                .findFirstByUserIdAndConsentTypeOrderByIdDesc(userId, ConsentType.PRIVACY);
        LocalDateTime acceptedAt = latestPrivacy
                .filter(UserConsent::isGranted)
                .map(UserConsent::getCreatedAt)
                .orElse(null);

        return ConsentStatusDto.builder()
                .termsVersion(legalProperties.getTermsVersion())
                .privacyVersion(legalProperties.getPrivacyVersion())
                .reconsentRequired(required)
                .acceptedAt(acceptedAt)
                .build();
    }

    @Transactional(readOnly = true)
    public boolean reconsentRequired(Long userId) {
        return !hasCurrentGrantedConsent(userId, ConsentType.TERMS, legalProperties.getTermsVersion())
                || !hasCurrentGrantedConsent(userId, ConsentType.PRIVACY, legalProperties.getPrivacyVersion());
    }

    @Transactional
    public ConsentStatusDto update(Long userId, ConsentUpdateRequest req) {
        if (req == null || req.getItems() == null || req.getItems().isEmpty()) {
            throw new IllegalArgumentException("Danh sách đồng ý không được để trống.");
        }
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy người dùng."));
        ConsentSource source = req.getSource() != null ? req.getSource() : ConsentSource.RECONSENT;

        for (ConsentItemDto item : req.getItems()) {
            if (item == null || item.getType() == null || item.getGranted() == null || isBlank(item.getVersion())) {
                throw new IllegalArgumentException("Dữ liệu đồng ý không hợp lệ.");
            }
            if (!Boolean.TRUE.equals(item.getGranted())) {
                throw new IllegalArgumentException(WITHDRAW_REQUIRED_MSG);
            }
            String expectedVersion = expectedVersionFor(item.getType());
            if (!expectedVersion.equals(item.getVersion().trim())) {
                throw new IllegalArgumentException(STALE_VERSION_MSG);
            }
            userConsentRepository.save(buildRecord(
                    user,
                    item.getType(),
                    expectedVersion,
                    true,
                    source,
                    req.getPlatform(),
                    req.getAppVersion()
            ));
        }
        return status(userId);
    }

    private boolean hasCurrentGrantedConsent(Long userId, ConsentType type, String currentVersion) {
        return userConsentRepository.findFirstByUserIdAndConsentTypeOrderByIdDesc(userId, type)
                .map(c -> c.isGranted() && currentVersion.equals(c.getVersion()))
                .orElse(false);
    }

    private String expectedVersionFor(ConsentType type) {
        return switch (type) {
            case TERMS -> legalProperties.getTermsVersion();
            case PRIVACY -> legalProperties.getPrivacyVersion();
            case AGE_16 -> AGE_16_VERSION;
        };
    }

    private UserConsent buildRecord(
            User user,
            ConsentType type,
            String version,
            boolean granted,
            ConsentSource source,
            String platform,
            String appVersion
    ) {
        return UserConsent.builder()
                .user(user)
                .consentType(type)
                .version(version)
                .granted(granted)
                .source(source)
                .platform(platform)
                .appVersion(appVersion)
                .build();
    }

    private boolean isBlank(String s) {
        return s == null || s.trim().isEmpty();
    }
}

