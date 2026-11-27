package com.splitdebt.api.service;

import com.splitdebt.api.entity.User;
import com.splitdebt.api.entity.GroupMember;
import com.splitdebt.api.entity.enums.GroupRole;
import com.splitdebt.api.entity.enums.GroupMemberStatus;
import com.splitdebt.api.exception.GroupPermissionException;
import com.splitdebt.api.repository.GroupMemberRepository;
import com.splitdebt.api.repository.UserRepository;
import org.junit.jupiter.api.*;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import java.util.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class SettingsAccessServiceTest {
    UserRepository users = mock(UserRepository.class);
    GroupMemberRepository members = mock(GroupMemberRepository.class);
    SettingsAccessService access = new SettingsAccessService(users, members);
    @BeforeEach void login() {
        SecurityContextHolder.getContext().setAuthentication(new UsernamePasswordAuthenticationToken("test@example.invalid", "", List.of()));
        User user = mock(User.class); when(user.getId()).thenReturn(1L);
        when(users.findByEmail("test@example.invalid")).thenReturn(Optional.of(user));
    }
    @AfterEach void cleanup() { SecurityContextHolder.clearContext(); }
    @Test void rejectsOtherUser() { assertThrows(GroupPermissionException.class, () -> access.requireOwner(2L)); assertDoesNotThrow(() -> access.requireOwner(1L)); }
    @Test void nonMemberDenied() { when(members.findByGroupIdAndUserId(3L,1L)).thenReturn(Optional.empty()); assertThrows(GroupPermissionException.class, () -> access.requireGroup(3L,false)); }
    @Test void memberMayReadButNotEdit() {
        var m = GroupMember.builder().status(GroupMemberStatus.ACTIVE).role(GroupRole.MEMBER).build();
        when(members.findByGroupIdAndUserId(3L,1L)).thenReturn(Optional.of(m));
        assertDoesNotThrow(() -> access.requireGroup(3L,false)); assertThrows(GroupPermissionException.class, () -> access.requireGroup(3L,true));
        m.setRole(GroupRole.ADMIN); assertDoesNotThrow(() -> access.requireGroup(3L,true));
        m.setStatus(GroupMemberStatus.INACTIVE); assertThrows(GroupPermissionException.class, () -> access.requireGroup(3L,false));
    }
}
