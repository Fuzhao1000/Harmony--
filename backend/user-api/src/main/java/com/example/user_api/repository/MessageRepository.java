package com.example.user_api.repository;

import com.example.user_api.entity.Message;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface MessageRepository extends JpaRepository<Message, Long> {
    
    // 获取两个用户之间的聊天记录
    @Query("SELECT m FROM Message m WHERE (m.senderId = ?1 AND m.receiverId = ?2) OR (m.senderId = ?2 AND m.receiverId = ?1) ORDER BY m.createTime ASC")
    List<Message> findChatHistory(String userId1, String userId2);
    
    // 获取用户接收到的未读消息
    List<Message> findByReceiverIdAndIsReadFalse(String receiverId);
    
    // 获取用户的所有消息（发送和接收）
    @Query("SELECT m FROM Message m WHERE m.senderId = ?1 OR m.receiverId = ?1 ORDER BY m.createTime DESC")
    List<Message> findAllUserMessages(String userId);
    
    // 获取未读消息数量
    long countByReceiverIdAndIsReadFalse(String receiverId);
}
