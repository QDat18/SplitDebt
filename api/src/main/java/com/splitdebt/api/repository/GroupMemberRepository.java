package com.splitdebt.api.repository;

import com.splitdebt.api.entity.GroupMember;
import com.splitdebt.api.entity.enums.GroupMemberStatus;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface GroupMemberRepository
        extends JpaRepository<GroupMember, Long> {

    // DEV4: kiểm tra user có phải thành viên ACTIVE hay không
    boolean existsByGroupIdAndUserIdAndStatus(
            Long groupId,
            Long userId,
            GroupMemberStatus status
    );

    // DEV2: lấy danh sách thành viên group
    List<GroupMember> findByGroupId(Long groupId);

    List<GroupMember> findByUserIdAndStatus(Long userId, GroupMemberStatus status);

    // DEV2: tìm một thành viên cụ thể trong group
    Optional<GroupMember> findByGroupIdAndUserId(
            Long groupId,
            Long userId
    );
}
