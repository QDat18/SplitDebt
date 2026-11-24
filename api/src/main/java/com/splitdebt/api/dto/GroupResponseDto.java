/**
 * Trách nhiệm file: Mô tả dữ liệu phản hồi Group Response DTO trả về cho client.
 */

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
    private String inviteCode;
    private int unreadMessageCount;
    private java.math.BigDecimal userBalance;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    public GroupResponseDto(Long id, String name, String description, Long createdById, String createdByName,
                            GroupRole currentUserRole, int memberCount, String inviteCode,
                            java.math.BigDecimal userBalance, LocalDateTime createdAt, LocalDateTime updatedAt) {
        this.id = id;
        this.name = name;
        this.description = description;
        this.createdById = createdById;
        this.createdByName = createdByName;
        this.currentUserRole = currentUserRole;
        this.memberCount = memberCount;
        this.inviteCode = inviteCode;
        this.unreadMessageCount = 0;
        this.userBalance = userBalance;
        this.createdAt = createdAt;
        this.updatedAt = updatedAt;
    }
}
