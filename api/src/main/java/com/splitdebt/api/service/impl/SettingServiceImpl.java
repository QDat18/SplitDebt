package com.splitdebt.api.service.impl;

import com.splitdebt.api.dto.request.GroupSettingRequest;
import com.splitdebt.api.dto.request.UserSettingRequest;
import com.splitdebt.api.dto.response.GroupSettingResponse;
import com.splitdebt.api.dto.response.UserSettingResponse;
import com.splitdebt.api.entity.Group;
import com.splitdebt.api.entity.GroupSetting;
import com.splitdebt.api.entity.User;
import com.splitdebt.api.entity.UserSetting;
import com.splitdebt.api.repository.GroupRepository;
import com.splitdebt.api.repository.GroupSettingRepository;
import com.splitdebt.api.repository.UserRepository;
import com.splitdebt.api.repository.UserSettingRepository;
import com.splitdebt.api.service.SettingService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class SettingServiceImpl implements SettingService {

    private final GroupSettingRepository groupSettingRepository;
    private final UserSettingRepository userSettingRepository;
    private final GroupRepository groupRepository;
    private final UserRepository userRepository;

    @Override
    @Transactional(readOnly = true)
    public GroupSettingResponse getGroupSetting(Long groupId) {
        GroupSetting setting = groupSettingRepository.findByGroupId(groupId)
                .orElseGet(() -> createDefaultGroupSetting(groupId));
        return mapToGroupSettingResponse(setting);
    }

    @Override
    @Transactional
    public GroupSettingResponse updateGroupSetting(Long groupId, GroupSettingRequest request) {
        GroupSetting setting = groupSettingRepository.findByGroupId(groupId)
                .orElseGet(() -> createDefaultGroupSetting(groupId));

        if (request.getCurrencyCode() != null) {
            setting.setCurrencyCode(request.getCurrencyCode());
            // Automatic mapping scale based on currency code
            if ("VND".equalsIgnoreCase(request.getCurrencyCode()) || "JPY".equalsIgnoreCase(request.getCurrencyCode())) {
                setting.setDecimalScale(0);
            } else {
                setting.setDecimalScale(2);
            }
        }

        if (request.getDecimalScale() != null) {
            setting.setDecimalScale(request.getDecimalScale());
        }

        if (request.getSmartSettlementEnabled() != null) {
            setting.setSmartSettlementEnabled(request.getSmartSettlementEnabled());
        }

        if (request.getMonthlyBudgetLimit() != null) {
            setting.setMonthlyBudgetLimit(request.getMonthlyBudgetLimit());
        }

        if (request.getAutoFreezeDay() != null) {
            setting.setAutoFreezeDay(request.getAutoFreezeDay());
        }

        if (request.getImageOptimizationEnabled() != null) {
            setting.setImageOptimizationEnabled(request.getImageOptimizationEnabled());
        }

        if (request.getCloudStorageSync() != null) {
            setting.setCloudStorageSync(request.getCloudStorageSync());
        }

        setting = groupSettingRepository.save(setting);
        return mapToGroupSettingResponse(setting);
    }

    @Override
    @Transactional(readOnly = true)
    public UserSettingResponse getUserSetting(Long userId) {
        UserSetting setting = userSettingRepository.findByUserId(userId)
                .orElseGet(() -> createDefaultUserSetting(userId));
        return mapToUserSettingResponse(setting);
    }

    @Override
    @Transactional
    public UserSettingResponse updateUserSetting(Long userId, UserSettingRequest request) {
        UserSetting setting = userSettingRepository.findByUserId(userId)
                .orElseGet(() -> createDefaultUserSetting(userId));

        if (request.getTheme() != null) {
            setting.setTheme(request.getTheme());
        }

        if (request.getLanguage() != null) {
            setting.setLanguage(request.getLanguage());
        }

        if (request.getNotifyOnNewExpense() != null) {
            setting.setNotifyOnNewExpense(request.getNotifyOnNewExpense());
        }

        if (request.getNotifyOnDebtReminder() != null) {
            setting.setNotifyOnDebtReminder(request.getNotifyOnDebtReminder());
        }

        if (request.getNotifyOnSettlement() != null) {
            setting.setNotifyOnSettlement(request.getNotifyOnSettlement());
        }

        if (request.getBiometricsEnabled() != null) {
            setting.setBiometricsEnabled(request.getBiometricsEnabled());
        }

        setting = userSettingRepository.save(setting);
        return mapToUserSettingResponse(setting);
    }

    @Override
    @Transactional(readOnly = true)
    public int getDecimalScaleByGroupId(Long groupId) {
        return groupSettingRepository.findByGroupId(groupId)
                .map(GroupSetting::getDecimalScale)
                .orElse(0); // Default scale 0 for VND
    }

    private GroupSetting createDefaultGroupSetting(Long groupId) {
        Group group = groupRepository.findById(groupId)
                .orElseThrow(() -> new IllegalArgumentException("Khong tim thay nhom voi ID: " + groupId));

        GroupSetting setting = GroupSetting.builder()
                .group(group)
                .currencyCode("VND")
                .decimalScale(0)
                .smartSettlementEnabled(true)
                .imageOptimizationEnabled(true)
                .cloudStorageSync("FULL")
                .build();

        return groupSettingRepository.save(setting);
    }

    private UserSetting createDefaultUserSetting(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("Khong tim thay nguoi dung voi ID: " + userId));

        UserSetting setting = UserSetting.builder()
                .user(user)
                .theme("LIGHT")
                .language("VI")
                .notifyOnNewExpense(true)
                .notifyOnDebtReminder(true)
                .notifyOnSettlement(true)
                .biometricsEnabled(false)
                .build();

        return userSettingRepository.save(setting);
    }

    private GroupSettingResponse mapToGroupSettingResponse(GroupSetting s) {
        return GroupSettingResponse.builder()
                .id(s.getId())
                .groupId(s.getGroup().getId())
                .currencyCode(s.getCurrencyCode())
                .decimalScale(s.getDecimalScale())
                .smartSettlementEnabled(s.getSmartSettlementEnabled())
                .monthlyBudgetLimit(s.getMonthlyBudgetLimit())
                .autoFreezeDay(s.getAutoFreezeDay())
                .imageOptimizationEnabled(s.getImageOptimizationEnabled())
                .cloudStorageSync(s.getCloudStorageSync())
                .createdAt(s.getCreatedAt())
                .updatedAt(s.getUpdatedAt())
                .build();
    }

    private UserSettingResponse mapToUserSettingResponse(UserSetting s) {
        return UserSettingResponse.builder()
                .id(s.getId())
                .userId(s.getUser().getId())
                .theme(s.getTheme())
                .language(s.getLanguage())
                .notifyOnNewExpense(s.getNotifyOnNewExpense())
                .notifyOnDebtReminder(s.getNotifyOnDebtReminder())
                .notifyOnSettlement(s.getNotifyOnSettlement())
                .biometricsEnabled(s.getBiometricsEnabled())
                .createdAt(s.getCreatedAt())
                .updatedAt(s.getUpdatedAt())
                .build();
    }
}
