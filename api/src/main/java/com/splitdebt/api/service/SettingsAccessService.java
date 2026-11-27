package com.splitdebt.api.service;

import com.splitdebt.api.entity.enums.GroupRole;
import com.splitdebt.api.entity.enums.GroupMemberStatus;
import com.splitdebt.api.exception.GroupPermissionException;
import com.splitdebt.api.repository.GroupMemberRepository;
import com.splitdebt.api.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class SettingsAccessService {
    private final UserRepository users;
    private final GroupMemberRepository members;
    private Long currentUser() {
        var auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || !auth.isAuthenticated()) throw new GroupPermissionException("Cần đăng nhập");
        return users.findByEmail(auth.getName()).orElseThrow(() -> new GroupPermissionException("Cần đăng nhập")).getId();
    }
    public void requireOwner(Long id) {
        if (!currentUser().equals(id)) throw new GroupPermissionException("Không được truy cập cài đặt của tài khoản khác");
    }
    public void requireGroup(Long groupId, boolean edit) {
        var member=members.findByGroupIdAndUserId(groupId,currentUser()).orElseThrow(() -> new GroupPermissionException("Bạn không thuộc nhóm này"));
        if (member.getStatus()!=GroupMemberStatus.ACTIVE || (edit && member.getRole()!=GroupRole.OWNER && member.getRole()!=GroupRole.ADMIN)) throw new GroupPermissionException("Bạn không có quyền chỉnh sửa cấu hình nhóm");
    }
}
