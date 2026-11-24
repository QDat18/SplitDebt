/**
 * Trách nhiệm file: Kiểm thử đơn vị cho NotificationService (Mockito thuần), xác minh việc tuân thủ cấu hình thông báo khi gửi push.
 */

package com.splitdebt.api.service;

import com.splitdebt.api.entity.Notification;
import com.splitdebt.api.entity.User;
import com.splitdebt.api.entity.UserSetting;
import com.splitdebt.api.repository.NotificationRepository;
import com.splitdebt.api.repository.UserSettingRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Map;
import java.util.Optional;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
public class NotificationServiceTest {

    @Mock
    private NotificationRepository notificationRepository;

    @Mock
    private FcmPushService fcmPushService;

    @Mock
    private UserSettingRepository userSettingRepository;

    @InjectMocks
    private NotificationService notificationService;

    private User user;

    @BeforeEach
    void setUp() {
        user = User.builder().id(7L).email("user7@test.com").build();
        lenient().when(notificationRepository.save(any(Notification.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));
    }

    @Test
    void settlementPush_skipped_whenNotifyOnSettlementFalse() {
        UserSetting setting = UserSetting.builder()
                .user(user)
                .notifyOnSettlement(false)
                .notifyOnDebtReminder(true)
                .build();
        when(userSettingRepository.findByUserId(7L)).thenReturn(Optional.of(setting));

        notificationService.createAndPush(user, "Title", "Content", "SETTLEMENT_PAID", Map.of());

        verify(notificationRepository).save(any(Notification.class));
        verify(fcmPushService, never()).sendToUserTopic(any(), any(), any(), any());
    }

    @Test
    void requestPush_skipped_whenNotifyOnDebtReminderFalse() {
        UserSetting setting = UserSetting.builder()
                .user(user)
                .notifyOnSettlement(true)
                .notifyOnDebtReminder(false)
                .build();
        when(userSettingRepository.findByUserId(7L)).thenReturn(Optional.of(setting));

        notificationService.createAndPush(user, "Title", "Content", "SETTLEMENT_REQUEST", Map.of());

        verify(notificationRepository).save(any(Notification.class));
        verify(fcmPushService, never()).sendToUserTopic(any(), any(), any(), any());
    }

    @Test
    void push_sent_whenNoSettingRow() {
        when(userSettingRepository.findByUserId(7L)).thenReturn(Optional.empty());

        notificationService.createAndPush(user, "Title", "Content", "SETTLEMENT_PAID", Map.of());

        verify(notificationRepository).save(any(Notification.class));
        verify(fcmPushService, times(1)).sendToUserTopic(eq(7L), eq("Title"), eq("Content"), any());
    }

    @Test
    void push_sent_forUnmappedType() {
        UserSetting setting = UserSetting.builder()
                .user(user)
                .notifyOnSettlement(false)
                .notifyOnDebtReminder(false)
                .build();
        when(userSettingRepository.findByUserId(7L)).thenReturn(Optional.of(setting));

        notificationService.createAndPush(user, "Title", "Content", "OTHER", Map.of());

        verify(notificationRepository).save(any(Notification.class));
        verify(fcmPushService, times(1)).sendToUserTopic(eq(7L), eq("Title"), eq("Content"), any());
    }
}

