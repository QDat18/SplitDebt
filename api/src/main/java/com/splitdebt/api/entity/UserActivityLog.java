/**
 * Trách nhiệm file: Ánh xạ thực thể UserActivityLog lưu nhật ký các thay đổi thông tin của người dùng.
 */

package com.splitdebt.api.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "user_activity_logs")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserActivityLog {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(name = "action", nullable = false, length = 50)
    private String action; // e.g. "UPDATE_PROFILE", "UPDATE_AVATAR"

    @Column(name = "description", nullable = false, length = 500)
    private String description; // Mô tả ngắn gọn: "Đổi họ tên thành Nguyễn Văn A"

    @Column(name = "old_value", columnDefinition = "TEXT")
    private String oldValue;

    @Column(name = "new_value", columnDefinition = "TEXT")
    private String newValue;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        if (this.createdAt == null) {
            this.createdAt = LocalDateTime.now();
        }
    }
}

