/**
 * Trách nhiệm file: Mô tả và kiểm tra payload yêu cầu Register FCM Token Request nhận từ API.
 */

package com.splitdebt.api.dto.notification;

import lombok.Data;

@Data
public class RegisterFcmTokenRequest {

    private Long userId;

    private String token;

    private String platform;
}
