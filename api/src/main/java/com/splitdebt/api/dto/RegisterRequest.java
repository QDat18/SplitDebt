/**
 * Trách nhiệm file: Mô tả và kiểm tra payload yêu cầu Register Request nhận từ API.
 */

package com.splitdebt.api.dto;

import com.splitdebt.api.dto.consent.RegisterConsentsDto;
import lombok.Data;

@Data
public class RegisterRequest {
    private String fullName;
    private String email;
    private String password;
    private RegisterConsentsDto consents;
    private String platform;
    private String appVersion;
}
