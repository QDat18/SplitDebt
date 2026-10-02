package com.splitdebt.api.service;

import com.splitdebt.api.dto.AddMemberRequestDto;
import com.splitdebt.api.dto.GroupMemberResponseDto;
import com.splitdebt.api.dto.GroupRequestDto;
import com.splitdebt.api.dto.GroupResponseDto;

import java.util.List;


public interface GroupService {
    GroupResponseDto createGroup(GroupRequestDto request, Long currentUserId);

    GroupResponseDto getGroupDetails(Long groupId, Long currentUserId);

    GroupResponseDto updateGroup(Long groupId, GroupRequestDto request, Long currentUserId);

    void deleteGroup(Long groupId, Long currentUserId);

    List<GroupResponseDto> getUserGroups(Long currentUserId);

    GroupMemberResponseDto addGroupMember(Long groupId, AddMemberRequestDto request, Long currentUserId);

    List<GroupMemberResponseDto> getGroupMembers(Long groupId, Long currentUserId);

    void leaveGroup(Long groupId, Long currentUserId);

    void removeMember(Long groupId, Long memberUserId, Long currentUserId);
}
