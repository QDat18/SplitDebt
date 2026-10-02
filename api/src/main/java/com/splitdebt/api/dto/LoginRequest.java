/**
 * Trách nhiệm file: Mô tả và kiểm tra payload yêu cầu Login Request nhận từ API.
 */

package com.splitdebt.api.dto;

import lombok.Data;

@Data
public class LoginRequest {
    private String email;
    private String password;
}
