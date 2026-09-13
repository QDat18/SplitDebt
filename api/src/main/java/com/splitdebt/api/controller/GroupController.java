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


@RestController
@RequestMapping("/api/groups")
@RequiredArgsConstructor
public class GroupController {

    private final GroupService groupService;

    private final com.splitdebt.api.repository.UserRepository users;

    private Long resolveCurrentUserId() {
        String email = org.springframework.security.core.context.SecurityContextHolder
                .getContext().getAuthentication().getName();
        return users.findByEmail(email).orElseThrow(() ->
                new com.splitdebt.api.exception.UserNotFoundException("Không tìm thấy tài khoản")).getId();
    }

    @PostMapping
    public ResponseEntity<ApiResponse<GroupResponseDto>> createGroup(
            @RequestBody GroupRequestDto request) {
        Long currentUserId = resolveCurrentUserId();
        GroupResponseDto dto = groupService.createGroup(request, currentUserId);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.ok("Group created successfully", dto));
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<GroupResponseDto>>> getUserGroups() {
        Long currentUserId = resolveCurrentUserId();
        List<GroupResponseDto> groups = groupService.getUserGroups(currentUserId);
        return ResponseEntity.ok(ApiResponse.ok("User groups retrieved", groups));
    }

    @GetMapping("/{groupId}")
    public ResponseEntity<ApiResponse<GroupResponseDto>> getGroupDetails(
            @PathVariable Long groupId) {
        Long currentUserId = resolveCurrentUserId();
        GroupResponseDto dto = groupService.getGroupDetails(groupId, currentUserId);
        return ResponseEntity.ok(ApiResponse.ok(dto));
    }

    @PutMapping("/{groupId}")
    public ResponseEntity<ApiResponse<GroupResponseDto>> updateGroup(
            @PathVariable Long groupId,
            @RequestBody GroupRequestDto request) {
        Long currentUserId = resolveCurrentUserId();
        GroupResponseDto dto = groupService.updateGroup(groupId, request, currentUserId);
        return ResponseEntity.ok(ApiResponse.ok("Group updated successfully", dto));
    }

    @DeleteMapping("/{groupId}")
    public ResponseEntity<ApiResponse<Void>> deleteGroup(
            @PathVariable Long groupId) {
        Long currentUserId = resolveCurrentUserId();
        groupService.deleteGroup(groupId, currentUserId);
        return ResponseEntity.ok(ApiResponse.ok("Group deleted successfully", null));
    }

    @GetMapping("/{groupId}/members")
    public ResponseEntity<ApiResponse<List<GroupMemberResponseDto>>> getGroupMembers(
            @PathVariable Long groupId) {
        Long currentUserId = resolveCurrentUserId();
        List<GroupMemberResponseDto> members = groupService.getGroupMembers(groupId, currentUserId);
        return ResponseEntity.ok(ApiResponse.ok(members));
    }

    @PostMapping("/{groupId}/members")
    public ResponseEntity<ApiResponse<GroupMemberResponseDto>> addGroupMember(
            @PathVariable Long groupId,
            @RequestBody AddMemberRequestDto request) {
        Long currentUserId = resolveCurrentUserId();
        GroupMemberResponseDto dto = groupService.addGroupMember(groupId, request, currentUserId);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.ok("Member added successfully", dto));
    }

    @DeleteMapping("/{groupId}/members/me")
    public ResponseEntity<ApiResponse<Void>> leaveGroup(
            @PathVariable Long groupId) {
        Long currentUserId = resolveCurrentUserId();
        groupService.leaveGroup(groupId, currentUserId);
        return ResponseEntity.ok(ApiResponse.ok("Left group successfully", null));
    }

    @DeleteMapping("/{groupId}/members/{userId}")
    public ResponseEntity<ApiResponse<Void>> removeMember(
            @PathVariable Long groupId,
            @PathVariable Long userId) {
        Long currentUserId = resolveCurrentUserId();
        groupService.removeMember(groupId, userId, currentUserId);
        return ResponseEntity.ok(ApiResponse.ok("Member removed successfully", null));
    }
}
