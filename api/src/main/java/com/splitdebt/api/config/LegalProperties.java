/**
 * Trách nhiệm file: Cấu hình phiên bản Điều khoản sử dụng và Chính sách quyền riêng tư hiện hành.
 */

package com.splitdebt.api.config;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties("app.legal")
@Getter
@Setter
public class LegalProperties {
    private String termsVersion = "2026-11-26";
    private String privacyVersion = "2026-11-26";
}

