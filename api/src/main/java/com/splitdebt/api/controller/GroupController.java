package com.splitdebt.api.controller;

import com.splitdebt.api.dto.AddMemberRequestDto;
import com.splitdebt.api.dto.ApiResponse;
import com.splitdebt.api.dto.GroupMemberResponseDto;
import com.splitdebt.api.dto.GroupRequestDto;
import com.splitdebt.api.dto.GroupResponseDto;
import com.splitdebt.api.service.GroupService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/groups")
@RequiredArgsConstructor
public class GroupController {

    private final GroupService groupService;

    private static final UUID DEFAULT_DEV_USER_ID = UUID.fromString("00000000-0000-0000-0000-000000000001");

    private UUID resolveCurrentUserId(String userIdHeader) {
        if (userIdHeader != null && !userIdHeader.isBlank()) {
            try {
                return UUID.fromString(userIdHeader.trim());
            } catch (IllegalArgumentException ignored) {
            }
        }
        return DEFAULT_DEV_USER_ID;
    }

    @PostMapping
    public ResponseEntity<ApiResponse<GroupResponseDto>> createGroup(
            @RequestBody GroupRequestDto request,
            @RequestHeader(value = "X-User-Id", required = false) String userIdHeader) {
        UUID currentUserId = resolveCurrentUserId(userIdHeader);
        GroupResponseDto dto = groupService.createGroup(request, currentUserId);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.ok("Group created successfully", dto));
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<GroupResponseDto>>> getUserGroups(
            @RequestHeader(value = "X-User-Id", required = false) String userIdHeader) {
        UUID currentUserId = resolveCurrentUserId(userIdHeader);
        List<GroupResponseDto> groups = groupService.getUserGroups(currentUserId);
        return ResponseEntity.ok(ApiResponse.ok("User groups retrieved", groups));
    }

    @GetMapping("/{groupId}")
    public ResponseEntity<ApiResponse<GroupResponseDto>> getGroupDetails(
            @PathVariable UUID groupId,
            @RequestHeader(value = "X-User-Id", required = false) String userIdHeader) {
        UUID currentUserId = resolveCurrentUserId(userIdHeader);
        GroupResponseDto dto = groupService.getGroupDetails(groupId, currentUserId);
        return ResponseEntity.ok(ApiResponse.ok(dto));
    }

    @PutMapping("/{groupId}")
    public ResponseEntity<ApiResponse<GroupResponseDto>> updateGroup(
            @PathVariable UUID groupId,
            @RequestBody GroupRequestDto request,
            @RequestHeader(value = "X-User-Id", required = false) String userIdHeader) {
        UUID currentUserId = resolveCurrentUserId(userIdHeader);
        GroupResponseDto dto = groupService.updateGroup(groupId, request, currentUserId);
        return ResponseEntity.ok(ApiResponse.ok("Group updated successfully", dto));
    }

    @DeleteMapping("/{groupId}")
    public ResponseEntity<ApiResponse<Void>> deleteGroup(
            @PathVariable UUID groupId,
            @RequestHeader(value = "X-User-Id", required = false) String userIdHeader) {
        UUID currentUserId = resolveCurrentUserId(userIdHeader);
        groupService.deleteGroup(groupId, currentUserId);
        return ResponseEntity.ok(ApiResponse.ok("Group deleted successfully", null));
    }

    @GetMapping("/{groupId}/members")
    public ResponseEntity<ApiResponse<List<GroupMemberResponseDto>>> getGroupMembers(
            @PathVariable UUID groupId,
            @RequestHeader(value = "X-User-Id", required = false) String userIdHeader) {
        UUID currentUserId = resolveCurrentUserId(userIdHeader);
        List<GroupMemberResponseDto> members = groupService.getGroupMembers(groupId, currentUserId);
        return ResponseEntity.ok(ApiResponse.ok(members));
    }

    @PostMapping("/{groupId}/members")
    public ResponseEntity<ApiResponse<GroupMemberResponseDto>> addGroupMember(
            @PathVariable UUID groupId,
            @RequestBody AddMemberRequestDto request,
            @RequestHeader(value = "X-User-Id", required = false) String userIdHeader) {
        UUID currentUserId = resolveCurrentUserId(userIdHeader);
        GroupMemberResponseDto dto = groupService.addGroupMember(groupId, request, currentUserId);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.ok("Member added successfully", dto));
    }

    @DeleteMapping("/{groupId}/members/me")
    public ResponseEntity<ApiResponse<Void>> leaveGroup(
            @PathVariable UUID groupId,
            @RequestHeader(value = "X-User-Id", required = false) String userIdHeader) {
        UUID currentUserId = resolveCurrentUserId(userIdHeader);
        groupService.leaveGroup(groupId, currentUserId);
        return ResponseEntity.ok(ApiResponse.ok("Left group successfully", null));
    }

    @DeleteMapping("/{groupId}/members/{userId}")
    public ResponseEntity<ApiResponse<Void>> removeMember(
            @PathVariable UUID groupId,
            @PathVariable UUID userId,
            @RequestHeader(value = "X-User-Id", required = false) String userIdHeader) {
        UUID currentUserId = resolveCurrentUserId(userIdHeader);
        groupService.removeMember(groupId, userId, currentUserId);
        return ResponseEntity.ok(ApiResponse.ok("Member removed successfully", null));
    }
}
