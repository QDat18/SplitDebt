/**
 * Trách nhiệm file: Trạng thái đồng ý hiện tại của người dùng trả về trong /users/me và /users/me/consents.
 */

package com.splitdebt.api.dto.consent;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ConsentStatusDto {
    private String termsVersion;
    private String privacyVersion;
    private boolean reconsentRequired;
    private LocalDateTime acceptedAt;
}

