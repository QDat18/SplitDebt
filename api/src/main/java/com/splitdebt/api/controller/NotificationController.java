package com.splitdebt.api.controller;

import com.splitdebt.api.dto.ApiResponse;
import com.splitdebt.api.dto.notification.NotificationDto;
import com.splitdebt.api.dto.notification.RegisterFcmTokenRequest;
import com.splitdebt.api.entity.Notification;
import com.splitdebt.api.repository.NotificationRepository;
import com.splitdebt.api.service.FcmTokenService;

import lombok.RequiredArgsConstructor;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/notifications")
@RequiredArgsConstructor
public class NotificationController {

    private final NotificationRepository notificationRepository;
    private final FcmTokenService fcmTokenService;
    private final com.splitdebt.api.repository.UserRepository users;

    private Long currentUserId() {
        String email = org.springframework.security.core.context.SecurityContextHolder
                .getContext().getAuthentication().getName();
        return users.findByEmail(email).orElseThrow(() ->
                new IllegalArgumentException("Không tìm thấy tài khoản")).getId();
    }

    private void requireCurrentUser(Long userId) {
        if (!currentUserId().equals(userId)) {
            throw new org.springframework.security.access.AccessDeniedException("Không có quyền truy cập thông báo của tài khoản khác");
        }
    }

    // =========================================================================
    // Lấy danh sách notification của user
    // =========================================================================
    @GetMapping
    public ResponseEntity<ApiResponse<List<NotificationDto>>> list(
            @RequestParam Long userId
    ) {

        requireCurrentUser(userId);
        List<NotificationDto> data =
                notificationRepository
                        .findByUserIdOrderByCreatedAtDesc(
                                userId
                        )
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

    // =========================================================================
    // Đánh dấu notification đã đọc
    // =========================================================================
    @PatchMapping("/{id}/read")
    public ResponseEntity<ApiResponse<Void>> read(
            @PathVariable Long id,
            @RequestParam Long userId
    ) {

        requireCurrentUser(userId);
        Notification notification =
                notificationRepository
                        .findById(id)
                        .orElseThrow(
                                () ->
                                        new IllegalArgumentException(
                                                "Không tìm thấy thông báo"
                                        )
                        );

        if (!notification
                .getUser()
                .getId()
                .equals(userId)) {

            throw new IllegalArgumentException(
                    "Không có quyền cập nhật thông báo này"
            );
        }

        notification.setIsRead(
                true
        );

        notificationRepository.save(
                notification
        );

        return ResponseEntity.ok(
                ApiResponse.success(
                        null,
                        "Đã đánh dấu thông báo là đã đọc"
                )
        );
    }

    // =========================================================================
    // Đăng ký FCM registration token
    //
    // POST /api/notifications/fcm-token
    //
    // {
    //   "userId": 1,
    //   "token": "...",
    //   "platform": "WEB"
    // }
    // =========================================================================
    @PostMapping("/fcm-token")
    public ResponseEntity<ApiResponse<Void>> registerFcmToken(
            @RequestBody RegisterFcmTokenRequest request
    ) {

        requireCurrentUser(request.getUserId());
        fcmTokenService.registerToken(
                request.getUserId(),
                request.getToken(),
                request.getPlatform()
        );

        return ResponseEntity.ok(
                ApiResponse.success(
                        null,
                        "Đăng ký FCM token thành công"
                )
        );
    }

    // =========================================================================
    // Xóa token khi logout
    // =========================================================================
    @DeleteMapping("/fcm-token")
    public ResponseEntity<ApiResponse<Void>> removeFcmToken(
            @RequestBody Map<String, String> request
    ) {

        fcmTokenService.removeToken(
                currentUserId(),
                request.get("token")
        );

        return ResponseEntity.ok(
                ApiResponse.success(
                        null,
                        "Đã xóa FCM token"
                )
        );
    }

    // =========================================================================
    // Entity -> DTO
    // =========================================================================
    private NotificationDto toDto(
            Notification notification
    ) {

        return new NotificationDto(
                notification.getId(),
                notification
                        .getUser()
                        .getId(),
                notification.getTitle(),
                notification.getContent(),
                notification.getType(),
                notification.getIsRead(),
                notification.getCreatedAt()
        );
    }
}
