/**
 * Trách nhiệm file: Mô hình hóa dữ liệu trao đổi Group Settings DTO giữa các tầng và qua API.
 */

package com.splitdebt.api.dto;

import lombok.Data;

@Data
public class GroupSettingsDto {
    private Boolean requireApproval;
    private String defaultCurrency;
}
