/**
 * Trách nhiệm file: Mô tả và kiểm tra payload yêu cầu Add Member Request DTO nhận từ API.
 */

package com.splitdebt.api.dto;

import com.splitdebt.api.entity.enums.GroupRole;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;



@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AddMemberRequestDto {
    private Long userId;
    private String email;
    private GroupRole role; // Default MEMBER if null
}
