package com.example.user_api.repository;

import com.example.user_api.entity.Favorite;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface FavoriteRepository extends JpaRepository<Favorite, Long> {

    Optional<Favorite> findByUserIdAndPostId(String userId, Long postId);

    List<Favorite> findByUserId(String userId);

    boolean existsByUserIdAndPostId(String userId, Long postId);

    void deleteByUserIdAndPostId(String userId, Long postId);
}
