package com.splitdebt.api.service.impl;

import com.splitdebt.api.dto.AddMemberRequestDto;
import com.splitdebt.api.dto.GroupMemberResponseDto;
import com.splitdebt.api.dto.GroupRequestDto;
import com.splitdebt.api.dto.GroupResponseDto;
import com.splitdebt.api.entity.Group;
import com.splitdebt.api.entity.GroupMember;
import com.splitdebt.api.entity.enums.GroupRole;
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

import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class GroupServiceImpl implements GroupService {

    private final GroupRepository groupRepository;
    private final GroupMemberRepository groupMemberRepository;
    private final UserRepository userRepository;

    @Override
    @Transactional
    public GroupResponseDto createGroup(GroupRequestDto request, Long currentUserId) {
        if (request.getName() == null || request.getName().isBlank() || request.getName().trim().length() > 150) {
            throw new IllegalArgumentException("Tên nhóm phải có từ 1 đến 150 ký tự");
        }
        User currentUser = requireUser(currentUserId);

        Group group = Group.builder()
                .name(request.getName().trim())
                .description(request.getDescription())
                .owner(currentUser)
                .inviteCode(java.util.UUID.randomUUID().toString().replace("-", "").substring(0, 20))
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
    public GroupResponseDto getGroupDetails(Long groupId, Long currentUserId) {
        Group group = groupRepository.findById(groupId)
                .orElseThrow(() -> new GroupNotFoundException("Group not found with ID: " + groupId));

        GroupMember currentMember = groupMemberRepository.findByGroupIdAndUserId(groupId, currentUserId)
                .orElseThrow(() -> new GroupPermissionException("You are not a member of this group"));

        int memberCount = groupMemberRepository.countByGroupId(groupId);

        return mapToGroupResponseDto(group, currentMember.getRole(), memberCount);
    }

    @Override
    @Transactional
    public GroupResponseDto updateGroup(Long groupId, GroupRequestDto request, Long currentUserId) {
        Group group = groupRepository.findById(groupId)
                .orElseThrow(() -> new GroupNotFoundException("Group not found with ID: " + groupId));

        GroupMember currentMember = groupMemberRepository.findByGroupIdAndUserId(groupId, currentUserId)
                .orElseThrow(() -> new GroupPermissionException("You are not a member of this group"));

        if (currentMember.getRole() != GroupRole.OWNER && currentMember.getRole() != GroupRole.ADMIN) {
            throw new GroupPermissionException("Only OWNER or ADMIN can update group details");
        }

        if (request.getName() != null && !request.getName().isBlank()) {
            if (request.getName().trim().length() > 150) throw new IllegalArgumentException("Tên nhóm tối đa 150 ký tự");
            group.setName(request.getName().trim());
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
    public void deleteGroup(Long groupId, Long currentUserId) {
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
    public List<GroupResponseDto> getUserGroups(Long currentUserId) {
        requireUser(currentUserId);

        List<GroupMember> userMemberships = groupMemberRepository.findByUserId(currentUserId);

        return userMemberships.stream().map(membership -> {
            Group group = membership.getGroup();
            int count = groupMemberRepository.countByGroupId(group.getId());
            return mapToGroupResponseDto(group, membership.getRole(), count);
        }).collect(Collectors.toList());
    }

    @Override
    @Transactional
    public GroupMemberResponseDto addGroupMember(Long groupId, AddMemberRequestDto request, Long currentUserId) {
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
            targetUser = userRepository.findByEmail(request.getEmail().trim().toLowerCase(java.util.Locale.ROOT))
                    .orElseThrow(() -> new UserNotFoundException("Email chưa đăng ký tài khoản SplitDebt"));
        } else {
            throw new IllegalArgumentException("Either userId or email must be provided");
        }

        if (groupMemberRepository.existsByGroupIdAndUserId(groupId, targetUser.getId())) {
            throw new MemberAlreadyExistsException("User is already a member of this group");
        }

        GroupRole assignedRole = request.getRole() != null ? request.getRole() : GroupRole.MEMBER;
        if (assignedRole == GroupRole.OWNER ||
                (assignedRole == GroupRole.ADMIN && currentMember.getRole() != GroupRole.OWNER)) {
            throw new GroupPermissionException("Chỉ chủ nhóm được thêm quản trị viên; không thể thêm chủ nhóm thứ hai");
        }

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
    public List<GroupMemberResponseDto> getGroupMembers(Long groupId, Long currentUserId) {
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
    public void leaveGroup(Long groupId, Long currentUserId) {
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
    public void removeMember(Long groupId, Long memberUserId, Long currentUserId) {
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

    private User requireUser(Long userId) {
        return userRepository.findById(userId)
                .orElseThrow(() -> new UserNotFoundException("Không tìm thấy tài khoản"));
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
        User creator = group.getOwner();
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
