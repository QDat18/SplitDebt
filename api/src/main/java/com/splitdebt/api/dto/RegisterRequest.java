/**
 * Trách nhiệm file: Mô tả và kiểm tra payload yêu cầu Register Request nhận từ API.
 */

package com.splitdebt.api.dto;

import lombok.Data;

@Data
public class RegisterRequest {
    private String fullName;
    private String email;
    private String password;
}
