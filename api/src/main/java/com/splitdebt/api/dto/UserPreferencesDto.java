package com.splitdebt.api.dto;

import lombok.Data;

@Data
public class UserPreferencesDto {
    private String language;
    private String currency;
    private String theme;
}
