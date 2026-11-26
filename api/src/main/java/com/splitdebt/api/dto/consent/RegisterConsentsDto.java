/**
 * Trách nhiệm file: Payload đồng ý khi đăng ký tài khoản.
 */

package com.splitdebt.api.dto.consent;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class RegisterConsentsDto {
    private String termsVersion;
    private String privacyVersion;
    private Boolean ageConfirmed;
}

