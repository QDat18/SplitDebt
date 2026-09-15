package com.splitdebt.api.controller;

import com.splitdebt.api.dto.GroupSettingsDto;
import com.splitdebt.api.dto.UserPreferencesDto;
import com.splitdebt.api.dto.request.GroupSettingRequest;
import com.splitdebt.api.dto.request.UserSettingRequest;
import com.splitdebt.api.dto.response.GroupSettingResponse;
import com.splitdebt.api.dto.response.UserSettingResponse;
import com.splitdebt.api.entity.User;
import com.splitdebt.api.repository.UserRepository;
import com.splitdebt.api.service.SettingService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/settings")
@RequiredArgsConstructor
public class SettingsController {

    private final SettingService settingService;
    private final UserRepository userRepository;

    @GetMapping("/user/me")
    public ResponseEntity<UserPreferencesDto> getMyPreferences() {
        User user = getCurrentUser();
        UserSettingResponse setting = settingService.getUserSetting(user.getId());

        UserPreferencesDto dto = new UserPreferencesDto();
        dto.setLanguage(setting.getLanguage());
        dto.setCurrency(setting.getCurrency());
        dto.setTheme(setting.getTheme());
        return ResponseEntity.ok(dto);
    }

    @PutMapping("/user/me")
    public ResponseEntity<UserPreferencesDto> updateMyPreferences(@RequestBody UserPreferencesDto dto) {
        User user = getCurrentUser();
        UserSettingRequest request = UserSettingRequest.builder()
                .language(dto.getLanguage())
                .currency(dto.getCurrency())
                .theme(dto.getTheme())
                .build();
        UserSettingResponse updated = settingService.updateUserSetting(user.getId(), request);

        UserPreferencesDto resDto = new UserPreferencesDto();
        resDto.setLanguage(updated.getLanguage());
        resDto.setCurrency(updated.getCurrency());
        resDto.setTheme(updated.getTheme());
        return ResponseEntity.ok(resDto);
    }

    @GetMapping("/group/{groupId}")
    public ResponseEntity<GroupSettingsDto> getGroupSettings(@PathVariable Long groupId) {
        GroupSettingResponse setting = settingService.getGroupSetting(groupId);

        GroupSettingsDto dto = new GroupSettingsDto();
        dto.setRequireApproval(setting.getRequireApproval());
        dto.setDefaultCurrency(setting.getCurrencyCode());
        return ResponseEntity.ok(dto);
    }

    @PutMapping("/group/{groupId}")
    public ResponseEntity<GroupSettingsDto> updateGroupSettings(@PathVariable Long groupId, @RequestBody GroupSettingsDto dto) {
        GroupSettingRequest request = GroupSettingRequest.builder()
                .requireApproval(dto.getRequireApproval())
                .currencyCode(dto.getDefaultCurrency())
                .build();
        GroupSettingResponse updated = settingService.updateGroupSetting(groupId, request);

        GroupSettingsDto resDto = new GroupSettingsDto();
        resDto.setRequireApproval(updated.getRequireApproval());
        resDto.setDefaultCurrency(updated.getCurrencyCode());
        return ResponseEntity.ok(resDto);
    }

    private User getCurrentUser() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        return userRepository.findByEmail(authentication.getName())
                .orElseThrow(() -> new RuntimeException("User not found"));
    }
}
