/**
 * Trách nhiệm file: Khai báo truy vấn và thao tác lưu trữ cho Group Setting Repository bằng Spring Data JPA.
 */

package com.splitdebt.api.repository;

import com.splitdebt.api.entity.GroupSetting;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface GroupSettingRepository extends JpaRepository<GroupSetting, Long> {

    Optional<GroupSetting> findByGroupId(Long groupId);
}
