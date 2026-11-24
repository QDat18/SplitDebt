/**
 * Trách nhiệm file: Hiện thực UserService, quản lý cập nhật hồ sơ và lưu nhật ký thay đổi thông tin.
 */

package com.splitdebt.api.service.impl;

import com.splitdebt.api.dto.UserDto;
import com.splitdebt.api.dto.request.UpdateProfileRequest;
import com.splitdebt.api.dto.response.UserActivityLogDto;
import com.splitdebt.api.entity.User;
import com.splitdebt.api.entity.UserActivityLog;
import com.splitdebt.api.repository.UserActivityLogRepository;
import com.splitdebt.api.repository.UserRepository;
import com.splitdebt.api.service.UserService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;
import java.util.Objects;

@Service
@RequiredArgsConstructor
@Slf4j
public class UserServiceImpl implements UserService {

    private final UserRepository userRepository;
    private final UserActivityLogRepository userActivityLogRepository;

    @Override
    @Transactional(readOnly = true)
    public UserDto getCurrentUser(String email) {
        User user = findUserByEmail(email);
        return mapToUserDto(user);
    }

    @Override
    @Transactional
    public UserDto updateProfile(String email, UpdateProfileRequest request) {
        User user = findUserByEmail(email);

        String newFullName = request.getFullName().trim();
        String newPhone = request.getPhone() != null ? request.getPhone().trim() : null;

        boolean nameChanged = !Objects.equals(user.getFullName(), newFullName);
        boolean phoneChanged = !Objects.equals(user.getPhone(), newPhone);

        if (nameChanged) {
            String oldName = user.getFullName();
            user.setFullName(newFullName);
            logActivity(user.getId(), "UPDATE_PROFILE", "Đổi họ và tên thành \"" + newFullName + "\"", oldName, newFullName);
        }

        if (phoneChanged) {
            String oldPhone = user.getPhone() != null ? user.getPhone() : "(chưa có)";
            String displayNewPhone = newPhone != null && !newPhone.isEmpty() ? newPhone : "(xoá)";
            user.setPhone(newPhone);
            logActivity(user.getId(), "UPDATE_PROFILE", "Cập nhật số điện thoại thành \"" + displayNewPhone + "\"", oldPhone, newPhone);
        }

        if (nameChanged || phoneChanged) {
            user = userRepository.save(user);
        }

        return mapToUserDto(user);
    }

    @Override
    @Transactional(readOnly = true)
    public List<UserActivityLogDto> getUserLogs(String email) {
        User user = findUserByEmail(email);
        List<UserActivityLog> logs = userActivityLogRepository.findByUserIdOrderByCreatedAtDesc(user.getId());
        List<UserActivityLogDto> dtos = new ArrayList<>();
        for (UserActivityLog logItem : logs) {
            dtos.add(UserActivityLogDto.builder()
                    .id(logItem.getId())
                    .action(logItem.getAction())
                    .description(logItem.getDescription())
                    .oldValue(logItem.getOldValue())
                    .newValue(logItem.getNewValue())
                    .createdAt(logItem.getCreatedAt())
                    .build());
        }
        return dtos;
    }

    @Override
    @Transactional
    public void logActivity(Long userId, String action, String description, String oldValue, String newValue) {
        try {
            UserActivityLog activityLog = UserActivityLog.builder()
                    .userId(userId)
                    .action(action)
                    .description(description)
                    .oldValue(oldValue)
                    .newValue(newValue)
                    .build();
            userActivityLogRepository.save(activityLog);
        } catch (Exception e) {
            log.error("Không thể ghi nhật ký hoạt động cho user {}: {}", userId, e.getMessage(), e);
        }
    }

    private User findUserByEmail(String email) {
        return userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User not found"));
    }

    private UserDto mapToUserDto(User user) {
        return UserDto.builder()
                .id(user.getId())
                .fullName(user.getFullName())
                .email(user.getEmail())
                .phone(user.getPhone())
                .avatarUrl(user.getAvatarUrl())
                .build();
    }
}

