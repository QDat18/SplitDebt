package com.splitdebt.api.dto;

import com.splitdebt.api.entity.GroupRole;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AddMemberRequestDto {
    private UUID userId;
    private String email;
    private GroupRole role; // Default MEMBER if null
}
