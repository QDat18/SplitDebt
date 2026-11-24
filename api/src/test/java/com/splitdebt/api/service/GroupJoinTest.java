package com.splitdebt.api.service;

import com.splitdebt.api.dto.GroupResponseDto;
import com.splitdebt.api.entity.Group;
import com.splitdebt.api.entity.GroupMember;
import com.splitdebt.api.entity.User;
import com.splitdebt.api.entity.enums.GroupRole;
import com.splitdebt.api.exception.GroupNotFoundException;
import com.splitdebt.api.repository.GroupMemberRepository;
import com.splitdebt.api.repository.GroupRepository;
import com.splitdebt.api.repository.UserRepository;
import com.splitdebt.api.service.impl.GroupServiceImpl;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class GroupJoinTest {

    @Mock
    private GroupRepository groupRepository;

    @Mock
    private GroupMemberRepository groupMemberRepository;

    @Mock
    private UserRepository userRepository;

    @InjectMocks
    private GroupServiceImpl groupService;

    private Group sampleGroup;
    private User sampleUser;

    @BeforeEach
    void setUp() {
        sampleUser = User.builder()
                .id(2L)
                .fullName("Tran Van B")
                .email("b@example.com")
                .build();

        sampleGroup = Group.builder()
                .id(100L)
                .name("Nhom Du Lich")
                .inviteCode("INVITE12345678901234")
                .owner(sampleUser)
                .build();
    }

    @Test
    void joinGroupByInviteCode_success_newMember() {
        when(groupRepository.findByInviteCode("INVITE12345678901234")).thenReturn(Optional.of(sampleGroup));
        when(userRepository.findById(2L)).thenReturn(Optional.of(sampleUser));
        when(groupMemberRepository.findByGroupIdAndUserId(100L, 2L)).thenReturn(Optional.empty());
        when(groupMemberRepository.countByGroupId(100L)).thenReturn(2);

        GroupResponseDto result = groupService.joinGroupByInviteCode("INVITE12345678901234", 2L);

        assertNotNull(result);
        assertEquals(100L, result.getId());
        assertEquals("Nhom Du Lich", result.getName());
        assertEquals("INVITE12345678901234", result.getInviteCode());
        assertEquals(GroupRole.MEMBER, result.getCurrentUserRole());

        verify(groupMemberRepository).save(any(GroupMember.class));
    }

    @Test
    void joinGroupByInviteCode_alreadyMember_doesNotDuplicate() {
        when(groupRepository.findByInviteCode("INVITE12345678901234")).thenReturn(Optional.of(sampleGroup));
        when(userRepository.findById(2L)).thenReturn(Optional.of(sampleUser));

        GroupMember existingMember = GroupMember.builder()
                .id(10L)
                .group(sampleGroup)
                .user(sampleUser)
                .role(GroupRole.ADMIN)
                .build();

        when(groupMemberRepository.findByGroupIdAndUserId(100L, 2L)).thenReturn(Optional.of(existingMember));
        when(groupMemberRepository.countByGroupId(100L)).thenReturn(2);

        GroupResponseDto result = groupService.joinGroupByInviteCode("INVITE12345678901234", 2L);

        assertNotNull(result);
        assertEquals(GroupRole.ADMIN, result.getCurrentUserRole());
        verify(groupMemberRepository, never()).save(any());
    }

    @Test
    void joinGroupByInviteCode_invalidCode_throwsGroupNotFound() {
        when(groupRepository.findByInviteCode("INVALID_CODE")).thenReturn(Optional.empty());

        assertThrows(GroupNotFoundException.class, () ->
                groupService.joinGroupByInviteCode("INVALID_CODE", 2L));
    }
}

