package com.splitdebt.api.service;

import com.splitdebt.api.entity.Notification;
import com.splitdebt.api.entity.User;
import com.splitdebt.api.repository.NotificationRepository;

import lombok.RequiredArgsConstructor;

import org.springframework.stereotype.Service;

import java.util.Map;

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

        fcmPushService.sendToUserTopic(
                user.getId(),
                title,
                content,
                data
        );

        return saved;
    }
}