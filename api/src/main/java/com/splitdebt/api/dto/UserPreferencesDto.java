/**
 * Trách nhiệm file: Mô hình hóa dữ liệu trao đổi User Preferences DTO giữa các tầng và qua API.
 */

package com.splitdebt.api.dto;

import lombok.Data;

@Data
public class UserPreferencesDto {
    private String language;
    private String currency;
    private String theme;
}
