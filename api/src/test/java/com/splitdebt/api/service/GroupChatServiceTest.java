package com.splitdebt.api.service;

import com.splitdebt.api.dto.chat.SendMessageRequest;
import com.splitdebt.api.entity.Group;
import com.splitdebt.api.entity.GroupMessage;
import com.splitdebt.api.entity.User;
import com.splitdebt.api.repository.GroupMemberRepository;
import com.splitdebt.api.repository.GroupMessageRepository;
import com.splitdebt.api.repository.GroupRepository;
import com.splitdebt.api.repository.UserRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.transaction.TransactionStatus;
import org.springframework.transaction.support.TransactionCallback;
import org.springframework.transaction.support.TransactionTemplate;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class GroupChatServiceTest {

    @Mock private GroupMessageRepository groupMessageRepository;
    @Mock private GroupRepository groupRepository;
    @Mock private UserRepository userRepository;
    @Mock private GroupAccessService groupAccessService;
    @Mock private GroupMemberRepository groupMemberRepository;
    @Mock private GroupChatPushService groupChatPushService;

    @Test
    void send_whenDataIntegrityViolationOnSave_rereadsExistingAndReturnsCreatedFalse() {
        TransactionTemplate txTemplate = mock(TransactionTemplate.class);
        when(txTemplate.execute(any())).thenAnswer(invocation -> {
            TransactionCallback<?> cb = invocation.getArgument(0);
            return cb.doInTransaction(mock(TransactionStatus.class));
        });

        GroupChatService service = new GroupChatService(
                groupMessageRepository,
                groupRepository,
                userRepository,
                groupAccessService,
                groupMemberRepository,
                groupChatPushService,
                txTemplate
        );

        Long groupId = 10L;
        Long userId = 1L;
        String clientMessageId = UUID.randomUUID().toString();

        Group group = Group.builder().id(groupId).name("Test Group").build();
        User user = User.builder().id(userId).fullName("User 1").build();
        GroupMessage existing = GroupMessage.builder()
                .id(42L)
                .group(group)
                .sender(user)
                .content("Hello")
                .clientMessageId(clientMessageId)
                .build();

        when(groupMessageRepository.findBySenderIdAndClientMessageId(userId, clientMessageId))
                .thenReturn(Optional.empty())
                .thenReturn(Optional.of(existing));
        when(groupRepository.findById(groupId)).thenReturn(Optional.of(group));
        when(userRepository.findById(userId)).thenReturn(Optional.of(user));
        when(groupMessageRepository.saveAndFlush(any(GroupMessage.class)))
                .thenThrow(new DataIntegrityViolationException("duplicate key"));

        GroupChatService.SendResult result = service.send(
                groupId,
                userId,
                new SendMessageRequest("Hello", clientMessageId)
        );

        assertThat(result.created()).isFalse();
        assertThat(result.message().id()).isEqualTo(42L);
        assertThat(result.message().clientMessageId()).isEqualTo(clientMessageId);
        verify(groupChatPushService, never()).notifyNewMessage(any());
        verify(groupMessageRepository, times(2)).findBySenderIdAndClientMessageId(userId, clientMessageId);
    }
}

