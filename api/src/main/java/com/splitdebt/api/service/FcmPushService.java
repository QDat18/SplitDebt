package com.splitdebt.api.service;

import com.google.firebase.FirebaseApp;
import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.FirebaseMessagingException;
import com.google.firebase.messaging.Message;
import com.google.firebase.messaging.Notification;

import com.splitdebt.api.entity.FcmToken;
import com.splitdebt.api.repository.FcmTokenRepository;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;

@Service
@RequiredArgsConstructor
@Slf4j
public class FcmPushService {

    private final FcmTokenRepository fcmTokenRepository;

    public void sendToUserTopic(
            Long userId,
            String title,
            String body,
            Map<String, String> data
    ) {

        if (userId == null) {
            return;
        }

        if (FirebaseApp.getApps().isEmpty()) {

            log.debug(
                    "Skip FCM because Firebase is not configured. userId={}, title={}",
                    userId,
                    title
            );

            return;
        }

        // --------------------------------------------------------------------
        // 1. Gửi tới các registration token đã lưu.
        // Chrome và Android đều dùng được.
        // --------------------------------------------------------------------
        List<FcmToken> tokens;
        try {
            tokens = fcmTokenRepository.findByUserId(userId);
        } catch (Exception ex) {
            log.warn("Could not load FCM tokens for user {}: {}", userId, ex.getMessage());
            return;
        }

        for (FcmToken fcmToken : tokens) {

            sendToToken(
                    fcmToken,
                    title,
                    body,
                    data
            );
        }

        // --------------------------------------------------------------------
        // 2. Giữ topic cũ để Android hiện tại vẫn tương thích
        // trong thời gian chuyển đổi.
        // Sau khi Android cũng đăng ký token ổn định,
        // có thể bỏ đoạn này.
        // --------------------------------------------------------------------
        try {

            Message topicMessage =
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
                    .send(topicMessage);

        } catch (Exception ex) {

            log.warn(
                    "Could not send FCM topic user_{}: {}",
                    userId,
                    ex.getMessage()
            );
        }
    }

    private void sendToToken(
            FcmToken fcmToken,
            String title,
            String body,
            Map<String, String> data
    ) {

        try {

            Message message =
                    Message.builder()
                            .setToken(
                                    fcmToken.getToken()
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

            String messageId =
                    FirebaseMessaging
                            .getInstance()
                            .send(message);

            log.info(
                    "FCM sent. userId={}, platform={}, messageId={}",
                    fcmToken
                            .getUser()
                            .getId(),
                    fcmToken
                            .getPlatform(),
                    messageId
            );

        } catch (FirebaseMessagingException ex) {

            log.warn(
                    "Could not send FCM token. tokenId={}, code={}, message={}",
                    fcmToken.getId(),
                    ex.getMessagingErrorCode(),
                    ex.getMessage()
            );

            // Token hết hạn / bị gỡ app thì hiện tại chỉ log.
            // Có thể bổ sung tự xóa token sau.
        } catch (Exception ex) {

            log.warn(
                    "Could not send FCM token. tokenId={}, message={}",
                    fcmToken.getId(),
                    ex.getMessage()
            );
        }
    }
}
