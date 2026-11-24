/**
 * Trách nhiệm file: Định nghĩa hoặc thực thi nghiệp vụ Notification Service dùng chung cho các controller backend.
 */

package com.splitdebt.api.service;

import com.splitdebt.api.entity.Notification;
import com.splitdebt.api.entity.User;
import com.splitdebt.api.repository.NotificationRepository;
import com.splitdebt.api.repository.UserSettingRepository;

import lombok.RequiredArgsConstructor;

import org.springframework.stereotype.Service;

import java.util.Map;
import java.util.HashMap;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;

@Service
@RequiredArgsConstructor
public class NotificationService {

    private final NotificationRepository notificationRepository;
    private final FcmPushService fcmPushService;
    private final UserSettingRepository userSettingRepository;

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
        Long userId = user != null ? user.getId() : null;
        boolean allowPush = shouldPush(userId, type);

        if (allowPush) {
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
        }

        return saved;
    }

    private boolean shouldPush(Long userId, String type) {
        if (userId == null) {
            return true;
        }
        return userSettingRepository.findByUserId(userId)
                .map(setting -> {
                    if ("SETTLEMENT_REQUEST".equals(type)) {
                        return !Boolean.FALSE.equals(setting.getNotifyOnDebtReminder());
                    } else if ("SETTLEMENT_PAID".equals(type) || "SETTLEMENT_CONFIRMED".equals(type)) {
                        return !Boolean.FALSE.equals(setting.getNotifyOnSettlement());
                    }
                    return true;
                })
                .orElse(true);
    }
}
