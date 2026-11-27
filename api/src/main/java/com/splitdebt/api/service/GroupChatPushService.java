package com.splitdebt.api.service;

import com.splitdebt.api.entity.GroupMember;
import com.splitdebt.api.entity.GroupMessage;
import com.splitdebt.api.entity.enums.GroupMemberStatus;
import com.splitdebt.api.repository.GroupMemberRepository;
import com.splitdebt.api.repository.UserSettingRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;

@Service
@RequiredArgsConstructor
public class GroupChatPushService {

    private final GroupMemberRepository groupMemberRepository;
    private final UserSettingRepository userSettingRepository;
    private final FcmPushService fcmPushService;

    public void notifyNewMessage(GroupMessage saved) {
        if (saved == null || saved.getGroup() == null || saved.getSender() == null) {
            return;
        }

        Long groupId = saved.getGroup().getId();
        Long senderId = saved.getSender().getId();
        String groupName = saved.getGroup().getName();
        String senderName = saved.getSender().getFullName();

        String rawBody = senderName + ": " + saved.getContent();
        String body;
        if (rawBody.length() > 100) {
            body = rawBody.substring(0, 99) + "…";
        } else {
            body = rawBody;
        }

        Map<String, String> data = new HashMap<>();
        data.put("type", "GROUP_MESSAGE");
        data.put("groupId", String.valueOf(groupId));
        data.put("messageId", String.valueOf(saved.getId()));

        List<GroupMember> activeMembers = groupMemberRepository.findByGroupIdAndStatus(groupId, GroupMemberStatus.ACTIVE);
        List<Long> targetUserIds = activeMembers.stream()
                .map(GroupMember::getUser)
                .filter(Objects::nonNull)
                .map(u -> u.getId())
                .filter(uid -> uid != null && !uid.equals(senderId))
                .filter(uid -> {
                    return userSettingRepository.findByUserId(uid)
                            .map(s -> !Boolean.FALSE.equals(s.getNotifyOnGroupMessage()))
                            .orElse(true);
                })
                .toList();

        if (targetUserIds.isEmpty()) {
            return;
        }

        Runnable push = () -> {
            for (Long uid : targetUserIds) {
                fcmPushService.sendToUserTopic(uid, groupName, body, data);
            }
        };

        if (TransactionSynchronizationManager.isSynchronizationActive()) {
            TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
                @Override
                public void afterCommit() {
                    push.run();
                }
            });
        } else {
            push.run();
        }
    }
}

