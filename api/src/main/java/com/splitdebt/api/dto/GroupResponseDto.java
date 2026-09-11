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
public class GroupResponseDto {
    private UUID id;
    private String name;
    private String description;
    private UUID createdById;
    private String createdByName;
    private GroupRole currentUserRole;
    private int memberCount;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
