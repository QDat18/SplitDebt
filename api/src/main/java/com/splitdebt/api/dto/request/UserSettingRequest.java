package com.splitdebt.api.dto.request;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UserSettingRequest {

    private String theme;

    private String language;

    private String currency;

    private Boolean notifyOnNewExpense;

    private Boolean notifyOnDebtReminder;

    private Boolean notifyOnSettlement;

    private Boolean biometricsEnabled;
}
