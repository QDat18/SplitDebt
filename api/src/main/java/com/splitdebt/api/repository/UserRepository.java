/**
 * Trách nhiệm file: Khai báo truy vấn và thao tác lưu trữ cho User Repository bằng Spring Data JPA.
 */

package com.splitdebt.api.repository;

import com.splitdebt.api.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface UserRepository extends JpaRepository<User, Long> {

    Optional<User> findByEmail(String email);

    boolean existsByEmail(String email);
}
