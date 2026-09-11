package com.splitdebt.api.repository;

import com.splitdebt.api.entity.ItemParticipant;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ItemParticipantRepository extends JpaRepository<ItemParticipant, Long> {

    List<ItemParticipant> findByItemId(Long itemId);

    List<ItemParticipant> findByUserId(Long userId);

    void deleteByItemId(Long itemId);
}
