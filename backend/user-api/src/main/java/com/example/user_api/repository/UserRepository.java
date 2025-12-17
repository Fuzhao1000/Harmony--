package com.example.user_api.repository;

import com.example.user_api.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;

public interface UserRepository extends JpaRepository<User, Long> {

    boolean existsByPhone(String phone);

    User findByPhone(String phone);
}
