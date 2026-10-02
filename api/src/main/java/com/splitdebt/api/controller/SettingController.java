package com.splitdebt.api.controller;

import com.splitdebt.api.dto.ApiResponse;
import com.splitdebt.api.dto.request.GroupSettingRequest;
import com.splitdebt.api.dto.request.UserSettingRequest;
import com.splitdebt.api.dto.response.GroupSettingResponse;
import com.splitdebt.api.dto.response.UserSettingResponse;
import com.splitdebt.api.service.SettingService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/settings")
@RequiredArgsConstructor
public class SettingController {

    private final SettingService settingService;

    // --- GROUP SETTINGS ---
    @GetMapping("/group/{groupId}")
    public ResponseEntity<ApiResponse<GroupSettingResponse>> getGroupSetting(@PathVariable Long groupId) {
        GroupSettingResponse response = settingService.getGroupSetting(groupId);
        return ResponseEntity.ok(ApiResponse.success(response, "Lay cau hinh nhom thanh cong"));
    }

    @PutMapping("/group/{groupId}")
    public ResponseEntity<ApiResponse<GroupSettingResponse>> updateGroupSetting(
            @PathVariable Long groupId,
            @RequestBody GroupSettingRequest request) {
        GroupSettingResponse response = settingService.updateGroupSetting(groupId, request);
        return ResponseEntity.ok(ApiResponse.success(response, "Cap nhat cau hinh nhom thanh cong"));
    }

    // --- USER PREFERENCES & SECURITY SETTINGS ---
    @GetMapping("/user/{userId}")
    public ResponseEntity<ApiResponse<UserSettingResponse>> getUserSetting(@PathVariable Long userId) {
        UserSettingResponse response = settingService.getUserSetting(userId);
        return ResponseEntity.ok(ApiResponse.success(response, "Lay cau hinh ca nhan thanh cong"));
    }

    @PutMapping("/user/{userId}")
    public ResponseEntity<ApiResponse<UserSettingResponse>> updateUserSetting(
            @PathVariable Long userId,
            @RequestBody UserSettingRequest request) {
        UserSettingResponse response = settingService.updateUserSetting(userId, request);
        return ResponseEntity.ok(ApiResponse.success(response, "Cap nhat cau hinh ca nhan thanh cong"));
    }
}
