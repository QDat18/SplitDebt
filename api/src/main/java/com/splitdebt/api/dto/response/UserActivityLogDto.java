/**
 * Trách nhiệm file: DTO phản hồi nhật ký hoạt động người dùng qua API.
 */

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
public class UserActivityLogDto {
    private Long id;
    private String action;
    private String description;
    private String oldValue;
    private String newValue;
    private LocalDateTime createdAt;
}

