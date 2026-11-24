package com.splitdebt.api.repository;

import com.splitdebt.api.entity.GroupMessage;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface GroupMessageRepository extends JpaRepository<GroupMessage, Long> {

    List<GroupMessage> findByGroupIdOrderByIdDesc(Long groupId, Pageable pageable);

    List<GroupMessage> findByGroupIdAndIdLessThanOrderByIdDesc(Long groupId, Long id, Pageable pageable);

    List<GroupMessage> findByGroupIdAndIdGreaterThanOrderByIdAsc(Long groupId, Long id, Pageable pageable);

    Optional<GroupMessage> findBySenderIdAndClientMessageId(Long senderId, String clientMessageId);
}
