/**
 * Trách nhiệm file: Khai báo truy vấn và thao tác lưu trữ cho Group Repository bằng Spring Data JPA.
 */

package com.splitdebt.api.repository;

import com.splitdebt.api.entity.Group;
import org.springframework.data.jpa.repository.JpaRepository;

public interface GroupRepository
        extends JpaRepository<Group, Long> {
}
