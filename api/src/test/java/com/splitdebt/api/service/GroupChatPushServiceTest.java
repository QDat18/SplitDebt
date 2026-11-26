package com.splitdebt.api.service;

import com.splitdebt.api.entity.Group;
import com.splitdebt.api.entity.GroupMember;
import com.splitdebt.api.entity.GroupMessage;
import com.splitdebt.api.entity.User;
import com.splitdebt.api.entity.UserSetting;
import com.splitdebt.api.entity.enums.GroupMemberStatus;
import com.splitdebt.api.repository.GroupMemberRepository;
import com.splitdebt.api.repository.UserSettingRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;
import java.util.Map;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class GroupChatPushServiceTest {

    @Mock
    private GroupMemberRepository groupMemberRepository;

    @Mock
    private UserSettingRepository userSettingRepository;

    @Mock
    private FcmPushService fcmPushService;

    @InjectMocks
    private GroupChatPushService groupChatPushService;

    private Group group;
    private User userA;
    private User userB;
    private User userC;

    @BeforeEach
    void setUp() {
        group = Group.builder().id(10L).name("Du lịch Đà Lạt").build();
        userA = User.builder().id(1L).fullName("Lan").build();
        userB = User.builder().id(2L).fullName("Minh").build();
        userC = User.builder().id(3L).fullName("Hoa").build();
    }

    @Test
    void pushesToOtherActiveMembersOnly() {
        GroupMessage message = GroupMessage.builder()
                .id(100L)
                .group(group)
                .sender(userA)
                .content("Chào mọi người!")
                .build();

        GroupMember memberA = GroupMember.builder().user(userA).group(group).status(GroupMemberStatus.ACTIVE).build();
        GroupMember memberB = GroupMember.builder().user(userB).group(group).status(GroupMemberStatus.ACTIVE).build();
        GroupMember memberC = GroupMember.builder().user(userC).group(group).status(GroupMemberStatus.ACTIVE).build();

        when(groupMemberRepository.findByGroupIdAndStatus(10L, GroupMemberStatus.ACTIVE))
                .thenReturn(List.of(memberA, memberB, memberC));
        when(userSettingRepository.findByUserId(anyLong())).thenReturn(Optional.empty());

        groupChatPushService.notifyNewMessage(message);

        // Should push to B and C, never to A (the sender)
        verify(fcmPushService, never()).sendToUserTopic(eq(1L), anyString(), anyString(), any());
        verify(fcmPushService, times(1)).sendToUserTopic(eq(2L), eq("Du lịch Đà Lạt"), eq("Lan: Chào mọi người!"), any());
        verify(fcmPushService, times(1)).sendToUserTopic(eq(3L), eq("Du lịch Đà Lạt"), eq("Lan: Chào mọi người!"), any());
    }

    @Test
    void skipsMembersWhoOptedOut() {
        GroupMessage message = GroupMessage.builder()
                .id(101L)
                .group(group)
                .sender(userA)
                .content("Họp lúc 9h")
                .build();

        GroupMember memberA = GroupMember.builder().user(userA).group(group).status(GroupMemberStatus.ACTIVE).build();
        GroupMember memberB = GroupMember.builder().user(userB).group(group).status(GroupMemberStatus.ACTIVE).build();
        GroupMember memberC = GroupMember.builder().user(userC).group(group).status(GroupMemberStatus.ACTIVE).build();

        when(groupMemberRepository.findByGroupIdAndStatus(10L, GroupMemberStatus.ACTIVE))
                .thenReturn(List.of(memberA, memberB, memberC));

        // Member B has setting enabled, Member C has notifyOnGroupMessage = false
        UserSetting settingC = UserSetting.builder().user(userC).notifyOnGroupMessage(false).build();
        when(userSettingRepository.findByUserId(2L)).thenReturn(Optional.empty());
        when(userSettingRepository.findByUserId(3L)).thenReturn(Optional.of(settingC));

        groupChatPushService.notifyNewMessage(message);

        // Push only to B, not to C
        verify(fcmPushService, times(1)).sendToUserTopic(eq(2L), anyString(), anyString(), any());
        verify(fcmPushService, never()).sendToUserTopic(eq(3L), anyString(), anyString(), any());
    }

    @Test
    void bodyIsTruncatedTo100Chars() {
        String longContent = "A".repeat(300);
        GroupMessage message = GroupMessage.builder()
                .id(102L)
                .group(group)
                .sender(userA)
                .content(longContent)
                .build();

        GroupMember memberB = GroupMember.builder().user(userB).group(group).status(GroupMemberStatus.ACTIVE).build();
        when(groupMemberRepository.findByGroupIdAndStatus(10L, GroupMemberStatus.ACTIVE))
                .thenReturn(List.of(memberB));
        when(userSettingRepository.findByUserId(2L)).thenReturn(Optional.empty());

        groupChatPushService.notifyNewMessage(message);

        ArgumentCaptor<String> bodyCaptor = ArgumentCaptor.forClass(String.class);
        verify(fcmPushService).sendToUserTopic(eq(2L), eq("Du lịch Đà Lạt"), bodyCaptor.capture(), any());

        String capturedBody = bodyCaptor.getValue();
        assertTrue(capturedBody.length() <= 100);
        assertTrue(capturedBody.endsWith("…"));
    }

    @Test
    void dataHasTypeGroupAndMessageIds() {
        GroupMessage message = GroupMessage.builder()
                .id(555L)
                .group(group)
                .sender(userA)
                .content("Alo alo")
                .build();

        GroupMember memberB = GroupMember.builder().user(userB).group(group).status(GroupMemberStatus.ACTIVE).build();
        when(groupMemberRepository.findByGroupIdAndStatus(10L, GroupMemberStatus.ACTIVE))
                .thenReturn(List.of(memberB));
        when(userSettingRepository.findByUserId(2L)).thenReturn(Optional.empty());

        groupChatPushService.notifyNewMessage(message);

        @SuppressWarnings("unchecked")
        ArgumentCaptor<Map<String, String>> dataCaptor = ArgumentCaptor.forClass(Map.class);
        verify(fcmPushService).sendToUserTopic(eq(2L), eq("Du lịch Đà Lạt"), anyString(), dataCaptor.capture());

        Map<String, String> data = dataCaptor.getValue();
        assertEquals("GROUP_MESSAGE", data.get("type"));
        assertEquals("10", data.get("groupId"));
        assertEquals("555", data.get("messageId"));
    }
}

