package com.splitdebt.api.dto;

import com.splitdebt.api.entity.GroupRole;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class GroupMemberResponseDto {
    private UUID id;
    private UUID groupId;
    private UUID userId;
    private String fullName;
    private String email;
    private String avatarUrl;
    private GroupRole role;
    private LocalDateTime joinedAt;
}
