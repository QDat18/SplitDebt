package com.splitdebt.api.service;

import com.google.firebase.FirebaseApp;
import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.Message;
import com.google.firebase.messaging.Notification;

import lombok.extern.slf4j.Slf4j;

import org.springframework.stereotype.Service;

import java.util.Map;

@Service
@Slf4j
public class FcmPushService {

    public void sendToUserTopic(
            Long userId,
            String title,
            String body,
            Map<String, String> data
    ) {

        if (FirebaseApp.getApps().isEmpty()) {

            log.debug(
                    "Skip FCM because Firebase is not configured. userId={}, title={}",
                    userId,
                    title
            );

            return;
        }

        try {

            Message message =
                    Message.builder()
                            .setTopic(
                                    "user_" + userId
                            )
                            .setNotification(
                                    Notification
                                            .builder()
                                            .setTitle(title)
                                            .setBody(body)
                                            .build()
                            )
                            .putAllData(
                                    data == null
                                            ? Map.of()
                                            : data
                            )
                            .build();

            FirebaseMessaging
                    .getInstance()
                    .send(message);

        } catch (Exception ex) {

            log.warn(
                    "Could not send FCM to user_{}: {}",
                    userId,
                    ex.getMessage()
            );
        }
    }
}