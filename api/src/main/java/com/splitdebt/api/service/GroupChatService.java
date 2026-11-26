package com.splitdebt.api.service;

import com.splitdebt.api.dto.chat.MessageDto;
import com.splitdebt.api.dto.chat.MessagePageDto;
import com.splitdebt.api.dto.chat.SendMessageRequest;
import com.splitdebt.api.entity.Group;
import com.splitdebt.api.entity.GroupMessage;
import com.splitdebt.api.entity.User;
import com.splitdebt.api.exception.GroupNotFoundException;
import com.splitdebt.api.exception.UserNotFoundException;
import com.splitdebt.api.repository.GroupMessageRepository;
import com.splitdebt.api.repository.GroupRepository;
import com.splitdebt.api.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionTemplate;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class GroupChatService {

    private final GroupMessageRepository groupMessageRepository;
    private final GroupRepository groupRepository;
    private final UserRepository userRepository;
    private final GroupAccessService groupAccessService;
    private final com.splitdebt.api.repository.GroupMemberRepository groupMemberRepository;
    private final GroupChatPushService groupChatPushService;
    private final TransactionTemplate transactionTemplate;

    public record SendResult(MessageDto message, boolean created) {}

    @Transactional
    public void markRead(Long groupId, Long userId, Long lastReadMessageId) {
        groupAccessService.requireActiveMember(groupId, userId);
        if (lastReadMessageId == null) {
            throw new IllegalArgumentException("lastReadMessageId không được để trống");
        }
        GroupMessage message = groupMessageRepository.findById(lastReadMessageId)
                .orElseThrow(() -> new IllegalArgumentException("Tin nhắn không tồn tại"));
        if (!message.getGroup().getId().equals(groupId)) {
            throw new IllegalArgumentException("Tin nhắn không thuộc nhóm này");
        }

        com.splitdebt.api.entity.GroupMember member = groupMemberRepository.findByGroupIdAndUserId(groupId, userId)
                .orElseThrow(() -> new IllegalArgumentException("Thành viên không tồn tại trong nhóm"));

        Long current = member.getLastReadMessageId();
        if (current == null || lastReadMessageId > current) {
            member.setLastReadMessageId(lastReadMessageId);
            groupMemberRepository.save(member);
        }
    }

    public SendResult send(Long groupId, Long userId, SendMessageRequest req) {
        groupAccessService.requireActiveMember(groupId, userId);

        if (req == null || req.content() == null || req.content().trim().isEmpty()) {
            throw new IllegalArgumentException("Tin nhắn không được để trống");
        }

        String trimmed = req.content().trim();
        int codePoints = trimmed.codePointCount(0, trimmed.length());
        if (codePoints > 2000) {
            throw new IllegalArgumentException("Tin nhắn tối đa 2000 ký tự");
        }

        if (req.clientMessageId() == null || req.clientMessageId().isBlank() || req.clientMessageId().length() != 36) {
            throw new IllegalArgumentException("Mã tin nhắn không hợp lệ");
        }

        try {
            UUID.fromString(req.clientMessageId());
        } catch (Exception e) {
            throw new IllegalArgumentException("Mã tin nhắn không hợp lệ");
        }

        Optional<GroupMessage> existing = groupMessageRepository.findBySenderIdAndClientMessageId(userId, req.clientMessageId());
        if (existing.isPresent()) {
            return new SendResult(toDto(existing.get()), false);
        }

        try {
            GroupMessage saved = transactionTemplate.execute(status -> {
                Group group = groupRepository.findById(groupId)
                        .orElseThrow(() -> new GroupNotFoundException("Không tìm thấy nhóm"));
                User sender = userRepository.findById(userId)
                        .orElseThrow(() -> new UserNotFoundException("Không tìm thấy tài khoản"));

                GroupMessage message = GroupMessage.builder()
                        .group(group)
                        .sender(sender)
                        .content(trimmed)
                        .clientMessageId(req.clientMessageId())
                        .build();

                return groupMessageRepository.saveAndFlush(message);
            });
            groupChatPushService.notifyNewMessage(saved);
            return new SendResult(toDto(saved), true);
        } catch (DataIntegrityViolationException ex) {
            GroupMessage raced = groupMessageRepository
                    .findBySenderIdAndClientMessageId(userId, req.clientMessageId())
                    .orElseThrow(() -> ex);
            return new SendResult(toDto(raced), false);
        }
    }

    @Transactional(readOnly = true)
    public MessagePageDto list(Long groupId, Long userId, Long before, Long after, Integer limit) {
        groupAccessService.requireActiveMember(groupId, userId);

        if (before != null && after != null) {
            throw new IllegalArgumentException("Không thể dùng đồng thời before và after");
        }

        int effectiveLimit = (limit == null || limit <= 0) ? 30 : Math.min(limit, 50);

        if (after != null) {
            List<GroupMessage> list = groupMessageRepository.findByGroupIdAndIdGreaterThanOrderByIdAsc(
                    groupId, after, PageRequest.of(0, 100)
            );
            List<MessageDto> dtos = list.stream().map(this::toDto).toList();
            return new MessagePageDto(dtos, false);
        }

        if (before != null) {
            List<GroupMessage> list = new ArrayList<>(groupMessageRepository.findByGroupIdAndIdLessThanOrderByIdDesc(
                    groupId, before, PageRequest.of(0, effectiveLimit + 1)
            ));
            boolean hasMore = list.size() > effectiveLimit;
            if (hasMore) {
                list = new ArrayList<>(list.subList(0, effectiveLimit));
            }
            Collections.reverse(list);
            List<MessageDto> dtos = list.stream().map(this::toDto).toList();
            return new MessagePageDto(dtos, hasMore);
        }

        // Latest messages (before == null && after == null)
        List<GroupMessage> list = new ArrayList<>(groupMessageRepository.findByGroupIdOrderByIdDesc(
                groupId, PageRequest.of(0, effectiveLimit + 1)
        ));
        boolean hasMore = list.size() > effectiveLimit;
        if (hasMore) {
            list = new ArrayList<>(list.subList(0, effectiveLimit));
        }
        Collections.reverse(list);
        List<MessageDto> dtos = list.stream().map(this::toDto).toList();
        return new MessagePageDto(dtos, hasMore);
    }

    private MessageDto toDto(GroupMessage message) {
        return new MessageDto(
                message.getId(),
                message.getGroup() != null ? message.getGroup().getId() : null,
                message.getSender() != null ? message.getSender().getId() : null,
                message.getSender() != null ? message.getSender().getFullName() : null,
                message.getContent(),
                message.getCreatedAt(),
                message.getClientMessageId()
        );
    }
}
