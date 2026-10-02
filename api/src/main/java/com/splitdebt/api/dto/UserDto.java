/**
 * Trách nhiệm file: Mô hình hóa dữ liệu trao đổi User DTO giữa các tầng và qua API.
 */

package com.splitdebt.api.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UserDto {
    private Long id;
    private String fullName;
    private String email;
    private String phone;
    private String avatarUrl;
}
