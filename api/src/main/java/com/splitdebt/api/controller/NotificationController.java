package com.splitdebt.api.controller;

import com.splitdebt.api.dto.ApiResponse;
import com.splitdebt.api.dto.notification.NotificationDto;
import com.splitdebt.api.entity.Notification;
import com.splitdebt.api.repository.NotificationRepository;

import lombok.RequiredArgsConstructor;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/notifications")
@RequiredArgsConstructor
public class NotificationController {

    private final NotificationRepository notificationRepository;

    @GetMapping
    public ResponseEntity<ApiResponse<List<NotificationDto>>> list(
            @RequestParam Long userId
    ) {

        List<NotificationDto> data =
                notificationRepository
                        .findByUserIdOrderByCreatedAtDesc(userId)
                        .stream()
                        .map(this::toDto)
                        .toList();

        return ResponseEntity.ok(
                ApiResponse.success(
                        data,
                        "Tải thông báo thành công"
                )
        );
    }

    @PatchMapping("/{id}/read")
    public ResponseEntity<ApiResponse<Void>> read(
            @PathVariable Long id,
            @RequestParam Long userId
    ) {

        Notification notification =
                notificationRepository
                        .findById(id)
                        .orElseThrow(
                                () -> new IllegalArgumentException(
                                        "Không tìm thấy thông báo"
                                )
                        );

        if (!notification.getUser()
                .getId()
                .equals(userId)) {

            throw new IllegalArgumentException(
                    "Không có quyền cập nhật thông báo này"
            );
        }

        notification.setIsRead(true);

        notificationRepository.save(notification);

        return ResponseEntity.ok(
                ApiResponse.success(
                        null,
                        "Đã đánh dấu thông báo là đã đọc"
                )
        );
    }

    private NotificationDto toDto(
            Notification notification
    ) {

        return new NotificationDto(
                notification.getId(),
                notification.getUser().getId(),
                notification.getTitle(),
                notification.getContent(),
                notification.getType(),
                notification.getIsRead(),
                notification.getCreatedAt()
        );
    }
}