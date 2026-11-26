/**
 * Trách nhiệm file: Mô tả và kiểm tra payload yêu cầu Group Request DTO nhận từ API.
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
public class GroupRequestDto {
    private String name;
    private String description;
}
