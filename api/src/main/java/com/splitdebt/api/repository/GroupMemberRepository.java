package com.splitdebt.api.repository;

import com.splitdebt.api.entity.GroupMember;
import com.splitdebt.api.entity.GroupRole;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface GroupMemberRepository extends JpaRepository<GroupMember, UUID> {

    List<GroupMember> findByUserId(UUID userId);

    List<GroupMember> findByGroupId(UUID groupId);

    Optional<GroupMember> findByGroupIdAndUserId(UUID groupId, UUID userId);

    boolean existsByGroupIdAndUserId(UUID groupId, UUID userId);

    int countByGroupId(UUID groupId);

    int countByGroupIdAndRole(UUID groupId, GroupRole role);

    void deleteByGroupIdAndUserId(UUID groupId, UUID userId);
}
