/**
 * Trách nhiệm file: Định nghĩa hoặc thực thi nghiệp vụ Group Access Service dùng chung cho các controller backend.
 */

package com.splitdebt.api.service;

import com.splitdebt.api.entity.enums.GroupMemberStatus;
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
}
