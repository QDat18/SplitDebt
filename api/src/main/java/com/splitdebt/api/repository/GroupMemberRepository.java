package com.splitdebt.api.repository;

import com.splitdebt.api.entity.GroupMember;
import com.splitdebt.api.entity.enums.GroupMemberStatus;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface GroupMemberRepository
        extends JpaRepository<GroupMember, Long> {

    List<GroupMember> findByUserId(Long userId);
    boolean existsByGroupIdAndUserId(Long groupId, Long userId);
    int countByGroupId(Long groupId);
    int countByGroupIdAndRole(Long groupId, com.splitdebt.api.entity.enums.GroupRole role);

    boolean existsByGroupIdAndUserIdAndStatus(
            Long groupId,
            Long userId,
            GroupMemberStatus status
    );

    List<GroupMember> findByGroupId(Long groupId);

    List<GroupMember> findByUserIdAndStatus(Long userId, GroupMemberStatus status);

    Optional<GroupMember> findByGroupIdAndUserId(
            Long groupId,
            Long userId
    );
}
