/**
 * Trách nhiệm file: Mô hình hóa dữ liệu trao đổi Notification DTO giữa các tầng và qua API.
 */

package com.splitdebt.api.dto.notification;

import java.time.LocalDateTime;

public record NotificationDto(
        Long id,
        Long userId,
        String title,
        String content,
        String type,
        Boolean isRead,
        LocalDateTime createdAt
) {
}
