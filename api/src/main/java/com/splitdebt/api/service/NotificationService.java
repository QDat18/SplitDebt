package com.splitdebt.api.service;

import com.splitdebt.api.entity.Notification;
import com.splitdebt.api.entity.User;
import com.splitdebt.api.repository.NotificationRepository;

import lombok.RequiredArgsConstructor;

import org.springframework.stereotype.Service;

import java.util.Map;
import java.util.HashMap;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;

@Service
@RequiredArgsConstructor
public class NotificationService {

    private final NotificationRepository
            notificationRepository;

    private final FcmPushService
            fcmPushService;

    public Notification createAndPush(
            User user,
            String title,
            String content,
            String type,
            Map<String, String> data
    ) {

        Notification saved =
                notificationRepository.save(
                        Notification
                                .builder()
                                .user(user)
                                .title(title)
                                .content(content)
                                .type(type)
                                .isRead(false)
                                .build()
                );

        Map<String, String> payload = new HashMap<>(data == null ? Map.of() : data);
        payload.put("type", type);
        Long userId = user.getId();
        Runnable push = () -> fcmPushService.sendToUserTopic(userId, title, content, payload);
        // Clients re-fetch balances on push: the transaction must be visible first.
        if (TransactionSynchronizationManager.isSynchronizationActive()) {
            TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
                @Override
                public void afterCommit() { push.run(); }
            });
        } else {
            push.run();
        }

        return saved;
    }
}
