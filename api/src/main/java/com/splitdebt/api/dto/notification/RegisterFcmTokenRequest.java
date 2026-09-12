package com.splitdebt.api.dto.notification;

import lombok.Data;

@Data
public class RegisterFcmTokenRequest {

    private Long userId;

    private String token;

    private String platform;
}