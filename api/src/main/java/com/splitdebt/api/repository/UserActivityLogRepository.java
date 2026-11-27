/**
 * Trách nhiệm file: Tầng truy xuất dữ liệu JPA cho nhật ký hoạt động người dùng.
 */

package com.splitdebt.api.repository;

import com.splitdebt.api.entity.UserActivityLog;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface UserActivityLogRepository extends JpaRepository<UserActivityLog, Long> {
    List<UserActivityLog> findByUserIdOrderByCreatedAtDesc(Long userId);
}

