package com.splitdebt.api.service;

import com.splitdebt.api.dto.request.GroupSettingRequest;
import com.splitdebt.api.dto.request.UserSettingRequest;
import com.splitdebt.api.dto.response.GroupSettingResponse;
import com.splitdebt.api.dto.response.UserSettingResponse;

public interface SettingService {

    GroupSettingResponse getGroupSetting(Long groupId);

    GroupSettingResponse updateGroupSetting(Long groupId, GroupSettingRequest request);

    UserSettingResponse getUserSetting(Long userId);

    UserSettingResponse updateUserSetting(Long userId, UserSettingRequest request);

    int getDecimalScaleByGroupId(Long groupId);
}
