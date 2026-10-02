package com.splitdebt.api.dto;

import lombok.Data;

@Data
public class GroupSettingsDto {
    private Boolean requireApproval;
    private String defaultCurrency;
}
