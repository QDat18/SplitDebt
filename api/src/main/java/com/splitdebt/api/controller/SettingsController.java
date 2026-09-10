package com.splitdebt.api.controller;

import com.splitdebt.api.dto.GroupSettingsDto;
import com.splitdebt.api.dto.UserPreferencesDto;
import com.splitdebt.api.entity.Group;
import com.splitdebt.api.entity.GroupSettings;
import com.splitdebt.api.entity.User;
import com.splitdebt.api.entity.UserPreferences;
import com.splitdebt.api.repository.GroupSettingsRepository;
import com.splitdebt.api.repository.UserPreferencesRepository;
import com.splitdebt.api.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/settings")
@RequiredArgsConstructor
public class SettingsController {

    private final UserPreferencesRepository userPreferencesRepository;
    private final GroupSettingsRepository groupSettingsRepository;
    private final UserRepository userRepository;
    
    // In a real scenario, you'd also need a GroupRepository to verify if group exists when creating group settings
    
    @GetMapping("/user/me")
    public ResponseEntity<UserPreferencesDto> getMyPreferences() {
        User user = getCurrentUser();
        UserPreferences prefs = userPreferencesRepository.findByUserId(user.getId())
                .orElseGet(() -> createDefaultPreferences(user));

        UserPreferencesDto dto = new UserPreferencesDto();
        dto.setLanguage(prefs.getLanguage());
        dto.setCurrency(prefs.getCurrency());
        dto.setTheme(prefs.getTheme());
        return ResponseEntity.ok(dto);
    }

    @PutMapping("/user/me")
    public ResponseEntity<UserPreferencesDto> updateMyPreferences(@RequestBody UserPreferencesDto dto) {
        User user = getCurrentUser();
        UserPreferences prefs = userPreferencesRepository.findByUserId(user.getId())
                .orElseGet(() -> createDefaultPreferences(user));

        if (dto.getLanguage() != null) prefs.setLanguage(dto.getLanguage());
        if (dto.getCurrency() != null) prefs.setCurrency(dto.getCurrency());
        if (dto.getTheme() != null) prefs.setTheme(dto.getTheme());

        userPreferencesRepository.save(prefs);
        return ResponseEntity.ok(dto);
    }

    @GetMapping("/group/{groupId}")
    public ResponseEntity<GroupSettingsDto> getGroupSettings(@PathVariable Long groupId) {
        GroupSettings settings = groupSettingsRepository.findByGroupId(groupId)
                .orElseThrow(() -> new IllegalArgumentException("Group settings not found for id: " + groupId));

        GroupSettingsDto dto = new GroupSettingsDto();
        dto.setRequireApproval(settings.getRequireApproval());
        dto.setDefaultCurrency(settings.getDefaultCurrency());
        return ResponseEntity.ok(dto);
    }

    @PutMapping("/group/{groupId}")
    public ResponseEntity<GroupSettingsDto> updateGroupSettings(@PathVariable Long groupId, @RequestBody GroupSettingsDto dto) {
        GroupSettings settings = groupSettingsRepository.findByGroupId(groupId)
                .orElseThrow(() -> new IllegalArgumentException("Group settings not found for id: " + groupId));

        if (dto.getRequireApproval() != null) settings.setRequireApproval(dto.getRequireApproval());
        if (dto.getDefaultCurrency() != null) settings.setDefaultCurrency(dto.getDefaultCurrency());

        groupSettingsRepository.save(settings);
        return ResponseEntity.ok(dto);
    }

    private User getCurrentUser() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        return userRepository.findByEmail(authentication.getName())
                .orElseThrow(() -> new RuntimeException("User not found"));
    }

    private UserPreferences createDefaultPreferences(User user) {
        UserPreferences prefs = new UserPreferences();
        prefs.setUser(user);
        prefs.setLanguage("en");
        prefs.setCurrency("USD");
        prefs.setTheme("light");
        return userPreferencesRepository.save(prefs);
    }
}
