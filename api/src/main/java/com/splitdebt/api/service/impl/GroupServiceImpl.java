package com.splitdebt.api.service.impl;

import com.splitdebt.api.dto.AddMemberRequestDto;
import com.splitdebt.api.dto.GroupMemberResponseDto;
import com.splitdebt.api.dto.GroupRequestDto;
import com.splitdebt.api.dto.GroupResponseDto;
import com.splitdebt.api.entity.Group;
import com.splitdebt.api.entity.GroupMember;
import com.splitdebt.api.entity.GroupRole;
import com.splitdebt.api.entity.User;
import com.splitdebt.api.exception.GroupNotFoundException;
import com.splitdebt.api.exception.GroupPermissionException;
import com.splitdebt.api.exception.MemberAlreadyExistsException;
import com.splitdebt.api.exception.UserNotFoundException;
import com.splitdebt.api.repository.GroupMemberRepository;
import com.splitdebt.api.repository.GroupRepository;
import com.splitdebt.api.repository.UserRepository;
import com.splitdebt.api.service.GroupService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class GroupServiceImpl implements GroupService {

    private final GroupRepository groupRepository;
    private final GroupMemberRepository groupMemberRepository;
    private final UserRepository userRepository;

    @Override
    @Transactional
    public GroupResponseDto createGroup(GroupRequestDto request, UUID currentUserId) {
        User currentUser = getOrCreateUser(currentUserId);

        Group group = Group.builder()
                .name(request.getName())
                .description(request.getDescription())
                .createdBy(currentUser)
                .build();

        Group savedGroup = groupRepository.save(group);

        GroupMember ownerMember = GroupMember.builder()
                .group(savedGroup)
                .user(currentUser)
                .role(GroupRole.OWNER)
                .build();

        groupMemberRepository.save(ownerMember);

        return mapToGroupResponseDto(savedGroup, GroupRole.OWNER, 1);
    }

    @Override
    @Transactional(readOnly = true)
    public GroupResponseDto getGroupDetails(UUID groupId, UUID currentUserId) {
        Group group = groupRepository.findById(groupId)
                .orElseThrow(() -> new GroupNotFoundException("Group not found with ID: " + groupId));

        GroupMember currentMember = groupMemberRepository.findByGroupIdAndUserId(groupId, currentUserId)
                .orElseThrow(() -> new GroupPermissionException("You are not a member of this group"));

        int memberCount = groupMemberRepository.countByGroupId(groupId);

        return mapToGroupResponseDto(group, currentMember.getRole(), memberCount);
    }

    @Override
    @Transactional
    public GroupResponseDto updateGroup(UUID groupId, GroupRequestDto request, UUID currentUserId) {
        Group group = groupRepository.findById(groupId)
                .orElseThrow(() -> new GroupNotFoundException("Group not found with ID: " + groupId));

        GroupMember currentMember = groupMemberRepository.findByGroupIdAndUserId(groupId, currentUserId)
                .orElseThrow(() -> new GroupPermissionException("You are not a member of this group"));

        if (currentMember.getRole() != GroupRole.OWNER && currentMember.getRole() != GroupRole.ADMIN) {
            throw new GroupPermissionException("Only OWNER or ADMIN can update group details");
        }

        if (request.getName() != null && !request.getName().isBlank()) {
            group.setName(request.getName());
        }
        if (request.getDescription() != null) {
            group.setDescription(request.getDescription());
        }

        Group updatedGroup = groupRepository.save(group);
        int memberCount = groupMemberRepository.countByGroupId(groupId);

        return mapToGroupResponseDto(updatedGroup, currentMember.getRole(), memberCount);
    }

    @Override
    @Transactional
    public void deleteGroup(UUID groupId, UUID currentUserId) {
        Group group = groupRepository.findById(groupId)
                .orElseThrow(() -> new GroupNotFoundException("Group not found with ID: " + groupId));

        GroupMember currentMember = groupMemberRepository.findByGroupIdAndUserId(groupId, currentUserId)
                .orElseThrow(() -> new GroupPermissionException("You are not a member of this group"));

        if (currentMember.getRole() != GroupRole.OWNER && currentMember.getRole() != GroupRole.ADMIN) {
            throw new GroupPermissionException("Only OWNER or ADMIN can delete group");
        }

        List<GroupMember> members = groupMemberRepository.findByGroupId(groupId);
        groupMemberRepository.deleteAll(members);
        groupRepository.delete(group);
    }

    @Override
    @Transactional(readOnly = true)
    public List<GroupResponseDto> getUserGroups(UUID currentUserId) {
        getOrCreateUser(currentUserId);

        List<GroupMember> userMemberships = groupMemberRepository.findByUserId(currentUserId);

        return userMemberships.stream().map(membership -> {
            Group group = membership.getGroup();
            int count = groupMemberRepository.countByGroupId(group.getId());
            return mapToGroupResponseDto(group, membership.getRole(), count);
        }).collect(Collectors.toList());
    }

    @Override
    @Transactional
    public GroupMemberResponseDto addGroupMember(UUID groupId, AddMemberRequestDto request, UUID currentUserId) {
        Group group = groupRepository.findById(groupId)
                .orElseThrow(() -> new GroupNotFoundException("Group not found with ID: " + groupId));

        GroupMember currentMember = groupMemberRepository.findByGroupIdAndUserId(groupId, currentUserId)
                .orElseThrow(() -> new GroupPermissionException("You are not a member of this group"));

        if (currentMember.getRole() != GroupRole.OWNER && currentMember.getRole() != GroupRole.ADMIN) {
            throw new GroupPermissionException("Only OWNER or ADMIN can add members to the group");
        }

        User targetUser;
        if (request.getUserId() != null) {
            targetUser = userRepository.findById(request.getUserId())
                    .orElseThrow(() -> new UserNotFoundException("User not found with ID: " + request.getUserId()));
        } else if (request.getEmail() != null && !request.getEmail().isBlank()) {
            targetUser = userRepository.findByEmail(request.getEmail())
                    .orElseGet(() -> userRepository.save(User.builder()
                            .email(request.getEmail().trim().toLowerCase())
                            .fullName(extractNameFromEmail(request.getEmail()))
                            .build()));
        } else {
            throw new IllegalArgumentException("Either userId or email must be provided");
        }

        if (groupMemberRepository.existsByGroupIdAndUserId(groupId, targetUser.getId())) {
            throw new MemberAlreadyExistsException("User is already a member of this group");
        }

        GroupRole assignedRole = request.getRole() != null ? request.getRole() : GroupRole.MEMBER;

        GroupMember newMember = GroupMember.builder()
                .group(group)
                .user(targetUser)
                .role(assignedRole)
                .build();

        GroupMember savedMember = groupMemberRepository.save(newMember);

        return mapToMemberResponseDto(savedMember);
    }

    @Override
    @Transactional(readOnly = true)
    public List<GroupMemberResponseDto> getGroupMembers(UUID groupId, UUID currentUserId) {
        if (!groupRepository.existsById(groupId)) {
            throw new GroupNotFoundException("Group not found with ID: " + groupId);
        }

        if (!groupMemberRepository.existsByGroupIdAndUserId(groupId, currentUserId)) {
            throw new GroupPermissionException("You are not a member of this group");
        }

        List<GroupMember> members = groupMemberRepository.findByGroupId(groupId);
        return members.stream().map(this::mapToMemberResponseDto).collect(Collectors.toList());
    }

    @Override
    @Transactional
    public void leaveGroup(UUID groupId, UUID currentUserId) {
        Group group = groupRepository.findById(groupId)
                .orElseThrow(() -> new GroupNotFoundException("Group not found with ID: " + groupId));

        GroupMember currentMember = groupMemberRepository.findByGroupIdAndUserId(groupId, currentUserId)
                .orElseThrow(() -> new GroupPermissionException("You are not a member of this group"));

        if (currentMember.getRole() == GroupRole.OWNER) {
            int ownerCount = groupMemberRepository.countByGroupIdAndRole(groupId, GroupRole.OWNER);
            int totalMembers = groupMemberRepository.countByGroupId(groupId);

            if (ownerCount <= 1 && totalMembers > 1) {
                throw new GroupPermissionException("As the sole OWNER, you cannot leave the group while other members exist. Promote another member or delete group.");
            } else if (totalMembers == 1) {
                // Sole member leaving -> delete group
                groupMemberRepository.delete(currentMember);
                groupRepository.delete(group);
                return;
            }
        }

        groupMemberRepository.delete(currentMember);
    }

    @Override
    @Transactional
    public void removeMember(UUID groupId, UUID memberUserId, UUID currentUserId) {
        if (memberUserId.equals(currentUserId)) {
            leaveGroup(groupId, currentUserId);
            return;
        }

        GroupMember callerMember = groupMemberRepository.findByGroupIdAndUserId(groupId, currentUserId)
                .orElseThrow(() -> new GroupPermissionException("You are not a member of this group"));

        if (callerMember.getRole() != GroupRole.OWNER && callerMember.getRole() != GroupRole.ADMIN) {
            throw new GroupPermissionException("Only OWNER or ADMIN can remove members");
        }

        GroupMember targetMember = groupMemberRepository.findByGroupIdAndUserId(groupId, memberUserId)
                .orElseThrow(() -> new UserNotFoundException("Target user is not a member of this group"));

        if (targetMember.getRole() == GroupRole.OWNER && callerMember.getRole() != GroupRole.OWNER) {
            throw new GroupPermissionException("ADMIN cannot remove an OWNER");
        }

        groupMemberRepository.delete(targetMember);
    }

    private User getOrCreateUser(UUID userId) {
        return userRepository.findById(userId)
                .orElseGet(() -> {
                    String defaultEmail = "user_" + userId.toString().substring(0, 8) + "@splitdebt.com";
                    return userRepository.save(User.builder()
                            .id(userId)
                            .email(defaultEmail)
                            .fullName("User " + userId.toString().substring(0, 4))
                            .build());
                });
    }

    private String extractNameFromEmail(String email) {
        if (email == null) return "Member";
        int atIndex = email.indexOf('@');
        if (atIndex > 0) {
            return email.substring(0, atIndex);
        }
        return email;
    }

    private GroupResponseDto mapToGroupResponseDto(Group group, GroupRole currentUserRole, int memberCount) {
        User creator = group.getCreatedBy();
        return GroupResponseDto.builder()
                .id(group.getId())
                .name(group.getName())
                .description(group.getDescription())
                .createdById(creator != null ? creator.getId() : null)
                .createdByName(creator != null ? creator.getFullName() : "Unknown")
                .currentUserRole(currentUserRole)
                .memberCount(memberCount)
                .createdAt(group.getCreatedAt())
                .updatedAt(group.getUpdatedAt())
                .build();
    }

    private GroupMemberResponseDto mapToMemberResponseDto(GroupMember member) {
        User u = member.getUser();
        return GroupMemberResponseDto.builder()
                .id(member.getId())
                .groupId(member.getGroup().getId())
                .userId(u.getId())
                .fullName(u.getFullName())
                .email(u.getEmail())
                .avatarUrl(u.getAvatarUrl())
                .role(member.getRole())
                .joinedAt(member.getJoinedAt())
                .build();
    }
}
