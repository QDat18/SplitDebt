package com.splitdebt.api.repository;

import com.splitdebt.api.entity.GroupMember;
import com.splitdebt.api.entity.enums.GroupMemberStatus;
import org.springframework.data.jpa.repository.JpaRepository;

public interface GroupMemberRepository
        extends JpaRepository<GroupMember, Long> {

    boolean existsByGroupIdAndUserIdAndStatus(
            Long groupId,
            Long userId,
            GroupMemberStatus status
    );
}