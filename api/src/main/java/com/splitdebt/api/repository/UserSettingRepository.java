/**
 * Trách nhiệm file: Khai báo truy vấn và thao tác lưu trữ cho User Setting Repository bằng Spring Data JPA.
 */

package com.splitdebt.api.repository;

import com.splitdebt.api.entity.UserSetting;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface UserSettingRepository extends JpaRepository<UserSetting, Long> {

    Optional<UserSetting> findByUserId(Long userId);
}
