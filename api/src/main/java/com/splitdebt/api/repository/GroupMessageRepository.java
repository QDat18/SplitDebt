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

    List<GroupMessage> findBySenderIdOrderByIdAsc(Long senderId);

    @org.springframework.data.jpa.repository.Query("SELECT COUNT(m) FROM GroupMessage m WHERE m.group.id = :groupId AND m.id > :afterId AND m.sender.id <> :viewerId")
    long countUnread(@org.springframework.data.repository.query.Param("groupId") Long groupId,
                     @org.springframework.data.repository.query.Param("afterId") Long afterId,
                     @org.springframework.data.repository.query.Param("viewerId") Long viewerId);

    @org.springframework.data.jpa.repository.Modifying
    @org.springframework.transaction.annotation.Transactional
    @org.springframework.data.jpa.repository.Query("DELETE FROM GroupMessage m WHERE m.group.id = :groupId")
    void deleteByGroupId(@org.springframework.data.repository.query.Param("groupId") Long groupId);
}
