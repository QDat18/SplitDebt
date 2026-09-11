package com.splitdebt.api.service;

import com.splitdebt.api.dto.AddMemberRequestDto;
import com.splitdebt.api.dto.GroupMemberResponseDto;
import com.splitdebt.api.dto.GroupRequestDto;
import com.splitdebt.api.dto.GroupResponseDto;

import java.util.List;
import java.util.UUID;

public interface GroupService {
    GroupResponseDto createGroup(GroupRequestDto request, UUID currentUserId);

    GroupResponseDto getGroupDetails(UUID groupId, UUID currentUserId);

    GroupResponseDto updateGroup(UUID groupId, GroupRequestDto request, UUID currentUserId);

    void deleteGroup(UUID groupId, UUID currentUserId);

    List<GroupResponseDto> getUserGroups(UUID currentUserId);

    GroupMemberResponseDto addGroupMember(UUID groupId, AddMemberRequestDto request, UUID currentUserId);

    List<GroupMemberResponseDto> getGroupMembers(UUID groupId, UUID currentUserId);

    void leaveGroup(UUID groupId, UUID currentUserId);

    void removeMember(UUID groupId, UUID memberUserId, UUID currentUserId);
}
