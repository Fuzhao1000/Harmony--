package com.example.user_api.service;

import com.example.user_api.entity.Message;
import com.example.user_api.repository.MessageRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.*;
import java.util.stream.Collectors;

@Service
public class MessageService {
    
    @Autowired
    private MessageRepository messageRepository;
    
    /**
     * 发送消息
     */
    public Message sendMessage(String senderId, String receiverId, String content) {
        Message message = new Message(senderId, receiverId, content);
        return messageRepository.save(message);
    }
    
    /**
     * 获取聊天历史
     */
    public List<Map<String, Object>> getChatHistory(String userId1, String userId2) {
        List<Message> messages = messageRepository.findChatHistory(userId1, userId2);
        
        return messages.stream().map(msg -> {
            Map<String, Object> map = new HashMap<>();
            map.put("id", msg.getId());
            map.put("senderId", msg.getSenderId());
            map.put("receiverId", msg.getReceiverId());
            map.put("content", msg.getContent());
            map.put("createTime", msg.getCreateTime());
            map.put("isRead", msg.getIsRead());
            map.put("type", msg.getType().toString());
            return map;
        }).collect(Collectors.toList());
    }
    
    /**
     * 标记消息为已读
     */
    public void markAsRead(Long messageId) {
        Optional<Message> message = messageRepository.findById(messageId);
        if (message.isPresent()) {
            Message msg = message.get();
            msg.setIsRead(true);
            messageRepository.save(msg);
        }
    }
    
    /**
     * 标记与某用户的所有消息为已读
     */
    public void markChatAsRead(String currentUserId, String otherUserId) {
        List<Message> messages = messageRepository.findChatHistory(currentUserId, otherUserId);
        messages.stream()
            .filter(msg -> msg.getReceiverId().equals(currentUserId) && !msg.getIsRead())
            .forEach(msg -> {
                msg.setIsRead(true);
                messageRepository.save(msg);
            });
    }
    
    /**
     * 获取未读消息数
     */
    public long getUnreadCount(String userId) {
        return messageRepository.countByReceiverIdAndIsReadFalse(userId);
    }
    
    /**
     * 获取会话列表（最近联系人）
     */
    public List<Map<String, Object>> getConversationList(String userId) {
        List<Message> allMessages = messageRepository.findAllUserMessages(userId);
        
        // 按对话分组，获取每个对话的最后一条消息
        Map<String, Message> latestMessages = new HashMap<>();
        
        for (Message msg : allMessages) {
            String otherUserId = msg.getSenderId().equals(userId) ? msg.getReceiverId() : msg.getSenderId();
            
            if (!latestMessages.containsKey(otherUserId) || 
                msg.getCreateTime() > latestMessages.get(otherUserId).getCreateTime()) {
                latestMessages.put(otherUserId, msg);
            }
        }
        
        // 转换为列表并按时间排序
        return latestMessages.entrySet().stream()
            .map(entry -> {
                Message msg = entry.getValue();
                Map<String, Object> map = new HashMap<>();
                map.put("userId", entry.getKey());
                map.put("lastMessage", msg.getContent());
                map.put("lastMessageTime", msg.getCreateTime());
                map.put("isRead", msg.getReceiverId().equals(userId) ? msg.getIsRead() : true);
                
                // 计算该对话的未读数
                long unreadCount = messageRepository.findChatHistory(userId, entry.getKey())
                    .stream()
                    .filter(m -> m.getReceiverId().equals(userId) && !m.getIsRead())
                    .count();
                map.put("unreadCount", unreadCount);
                
                return map;
            })
            .sorted((a, b) -> Long.compare((Long)b.get("lastMessageTime"), (Long)a.get("lastMessageTime")))
            .collect(Collectors.toList());
    }
}
