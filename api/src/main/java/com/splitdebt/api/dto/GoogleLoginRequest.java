/**
 * Trách nhiệm file: Nhận Google ID token do ứng dụng Flutter gửi tới để backend xác minh.
 */

package com.splitdebt.api.dto;

import lombok.Data;

@Data
public class GoogleLoginRequest {

    private String idToken;
}
