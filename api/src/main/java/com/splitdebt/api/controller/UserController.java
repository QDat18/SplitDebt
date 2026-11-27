/**
 * Trách nhiệm file: Cung cấp các HTTP endpoint của User Controller, nhận request đã xác thực và chuyển xử lý xuống tầng nghiệp vụ.
 */

package com.splitdebt.api.controller;

import com.splitdebt.api.dto.UserDto;
import com.splitdebt.api.entity.User;
import com.splitdebt.api.repository.UserRepository;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@Tag(name = "6. Users", description = "Các API thông tin người dùng")
@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
public class UserController {

    private final UserRepository userRepository;

    @Operation(summary = "Lấy thông tin người dùng đang đăng nhập", description = "Dựa trên JWT Token để lấy thông tin cá nhân của user.")
    @GetMapping("/me")
    public ResponseEntity<UserDto> getCurrentUser() {
        User user = getAuthenticatedUser();
        return ResponseEntity.ok(toDto(user));
    }

    @Operation(summary = "Cập nhật hồ sơ người dùng đang đăng nhập", description = "Lưu thay đổi họ tên, số điện thoại hoặc ảnh đại diện vào cơ sở dữ liệu.")
    @PatchMapping("/me")
    public ResponseEntity<UserDto> updateCurrentUser(@RequestBody Map<String, Object> payload) {
        User user = getAuthenticatedUser();

        if (payload.containsKey("fullName") && payload.get("fullName") != null) {
            String fullName = payload.get("fullName").toString().trim();
            if (fullName.length() < 2 || fullName.length() > 100) {
                throw new IllegalArgumentException("Họ tên phải từ 2 đến 100 ký tự.");
            }
            user.setFullName(fullName);
        }

        if (payload.containsKey("phone")) {
            Object rawPhone = payload.get("phone");
            String phone = rawPhone == null ? "" : rawPhone.toString().trim();
            user.setPhone(phone.isEmpty() ? null : phone);
        }

        if (payload.containsKey("avatarUrl")) {
            Object rawAvatar = payload.get("avatarUrl");
            String avatarUrl = rawAvatar == null ? "" : rawAvatar.toString().trim();
            user.setAvatarUrl(avatarUrl.isEmpty() ? null : avatarUrl);
        }

        User saved = userRepository.save(user);
        return ResponseEntity.ok(toDto(saved));
    }

    private User getAuthenticatedUser() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String email = authentication.getName();
        return userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User not found"));
    }

    private UserDto toDto(User user) {
        return UserDto.builder()
                .id(user.getId())
                .fullName(user.getFullName())
                .email(user.getEmail())
                .phone(user.getPhone())
                .avatarUrl(user.getAvatarUrl())
                .build();
    }
}
