package com.example.user_api.repository;

import com.example.user_api.entity.Post;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface PostRepository extends JpaRepository<Post, Long> {
    List<Post> findByBaname(String baname);
    List<Post> findByUserId(Long userId);
}
