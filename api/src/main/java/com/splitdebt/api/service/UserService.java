/**
 * Trách nhiệm file: Định nghĩa interface UserService xử lý nghiệp vụ thông tin và nhật ký người dùng.
 */

package com.splitdebt.api.service;

import com.splitdebt.api.dto.UserDto;
import com.splitdebt.api.dto.request.UpdateProfileRequest;
import com.splitdebt.api.dto.response.UserActivityLogDto;

import java.util.List;

public interface UserService {
    UserDto getCurrentUser(String email);
    UserDto updateProfile(String email, UpdateProfileRequest request);
    List<UserActivityLogDto> getUserLogs(String email);
    void logActivity(Long userId, String action, String description, String oldValue, String newValue);
}

