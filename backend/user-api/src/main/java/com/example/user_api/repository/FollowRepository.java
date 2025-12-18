package com.example.user_api.repository;

import com.example.user_api.entity.Follow;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface FollowRepository extends JpaRepository<Follow, Long> {
    
    // 查找某个用户是否关注了另一个用户
    Optional<Follow> findByFollowerIdAndFollowingId(Long followerId, Long followingId);
    
    // 统计某个用户的关注数
    long countByFollowerId(Long followerId);
    
    // 统计某个用户的粉丝数
    long countByFollowingId(Long followingId);
    
    // 检查是否存在关注关系
    boolean existsByFollowerIdAndFollowingId(Long followerId, Long followingId);
    
    // 获取某个用户关注的所有人的ID列表
    List<Follow> findByFollowerId(Long followerId);
    
    // 获取某个用户的所有粉丝ID列表
    List<Follow> findByFollowingId(Long followingId);
}
