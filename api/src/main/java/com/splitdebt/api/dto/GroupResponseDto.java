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
public class GroupResponseDto {
    private Long id;
    private String name;
    private String description;
    private Long createdById;
    private String createdByName;
    private GroupRole currentUserRole;
    private int memberCount;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
