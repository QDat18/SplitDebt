package com.splitdebt.api.dto;

import com.splitdebt.api.entity.enums.GroupRole;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;


@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class GroupMemberResponseDto {
    private Long id;
    private Long groupId;
    private Long userId;
    private String fullName;
    private String email;
    private String avatarUrl;
    private GroupRole role;
    private LocalDateTime joinedAt;
}
