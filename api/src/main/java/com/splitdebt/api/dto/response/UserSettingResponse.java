package com.splitdebt.api.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UserSettingResponse {

    private Long id;

    private Long userId;

    private String theme;

    private String language;

    private Boolean notifyOnNewExpense;

    private Boolean notifyOnDebtReminder;

    private Boolean notifyOnSettlement;

    private Boolean biometricsEnabled;

    private LocalDateTime createdAt;

    private LocalDateTime updatedAt;
}
