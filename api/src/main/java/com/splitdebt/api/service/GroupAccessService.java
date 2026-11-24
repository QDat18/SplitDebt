/**
 * Trách nhiệm file: Định nghĩa hoặc thực thi nghiệp vụ Group Access Service dùng chung cho các controller backend.
 */

package com.splitdebt.api.service;

import com.splitdebt.api.entity.GroupMember;
import com.splitdebt.api.entity.enums.GroupMemberStatus;
import com.splitdebt.api.entity.enums.GroupRole;
import com.splitdebt.api.exception.GroupPermissionException;
import com.splitdebt.api.repository.GroupMemberRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class GroupAccessService {

    private final GroupMemberRepository groupMemberRepository;

    public void requireActiveMember(
            Long groupId,
            Long userId
    ) {

        if (groupId == null || userId == null) {
            throw new IllegalArgumentException(
                    "groupId và userId không được để trống"
            );
        }

        boolean exists =
                groupMemberRepository
                        .existsByGroupIdAndUserIdAndStatus(
                                groupId,
                                userId,
                                GroupMemberStatus.ACTIVE
                        );

        if (!exists) {
            throw new GroupPermissionException(
                    "Người dùng không phải thành viên đang hoạt động của nhóm"
            );
        }
    }

    public void requireAdmin(
            Long groupId,
            Long userId
    ) {
        if (groupId == null || userId == null) {
            throw new IllegalArgumentException(
                    "groupId và userId không được để trống"
            );
        }

        GroupMember member = groupMemberRepository
                .findByGroupIdAndUserId(groupId, userId)
                .orElseThrow(() -> new GroupPermissionException(
                        "Người dùng không phải thành viên của nhóm"
                ));

        if (member.getStatus() != GroupMemberStatus.ACTIVE) {
            throw new GroupPermissionException(
                    "Thành viên không còn hoạt động trong nhóm"
            );
        }

        if (member.getRole() != GroupRole.OWNER && member.getRole() != GroupRole.ADMIN) {
            throw new GroupPermissionException(
                    "Chỉ OWNER hoặc ADMIN mới có quyền thay đổi cài đặt nhóm"
            );
        }
    }
}
