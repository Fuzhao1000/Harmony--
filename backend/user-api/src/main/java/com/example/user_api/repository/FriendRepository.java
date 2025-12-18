package com.example.user_api.repository;

import com.example.user_api.entity.Friend;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface FriendRepository extends JpaRepository<Friend, Long> {
    
    // 查找用户的所有好友
    List<Friend> findByUserIdAndStatus(String userId, Friend.FriendStatus status);
    
    // 查找用户的所有待确认好友请求
    List<Friend> findByFriendIdAndStatus(String friendId, Friend.FriendStatus status);
    
    // 检查是否已经是好友
    Optional<Friend> findByUserIdAndFriendId(String userId, String friendId);
    
    // 查找所有相关的好友关系（包括双向）
    @Query("SELECT f FROM Friend f WHERE (f.userId = ?1 OR f.friendId = ?1) AND f.status = ?2")
    List<Friend> findAllRelationships(String userId, Friend.FriendStatus status);
}
