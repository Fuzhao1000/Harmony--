package com.example.user_api.controller;

import com.example.user_api.service.MessageService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.*;

@RestController
@RequestMapping("/api/message")
public class MessageController {
    
    @Autowired
    private MessageService messageService;
    
    /**
     * 发送消息
     */
    @PostMapping("/send")
    public Map<String, Object> sendMessage(@RequestBody Map<String, String> request) {
        String senderId = request.get("senderId");
        String receiverId = request.get("receiverId");
        String content = request.get("content");
        
        Map<String, Object> res = new HashMap<>();
        try {
            com.example.user_api.entity.Message msg = messageService.sendMessage(senderId, receiverId, content);
            
            // 返回完整的消息对象
            Map<String, Object> messageData = new HashMap<>();
            messageData.put("id", msg.getId());
            messageData.put("senderId", msg.getSenderId());
            messageData.put("receiverId", msg.getReceiverId());
            messageData.put("content", msg.getContent());
            messageData.put("createTime", msg.getCreateTime());
            
            res.put("success", true);
            res.put("message", messageData);
        } catch (Exception e) {
            res.put("success", false);
            res.put("message", "发送失败: " + e.getMessage());
        }
        return res;
    }
    
    /**
     * 获取聊天历史
     */
    @GetMapping("/history")
    public Map<String, Object> getChatHistory(@RequestParam String userId, @RequestParam String friendId) {
        Map<String, Object> res = new HashMap<>();
        try {
            List<Map<String, Object>> messages = messageService.getChatHistory(userId, friendId);
            res.put("success", true);
            res.put("messages", messages);
        } catch (Exception e) {
            res.put("success", false);
            res.put("message", "获取聊天记录失败: " + e.getMessage());
        }
        return res;
    }
    
    /**
     * 获取消息列表（兼容前端/list接口）
     */
    @GetMapping("/list")
    public Map<String, Object> getMessageList(@RequestParam String userId, @RequestParam String targetUserId) {
        Map<String, Object> res = new HashMap<>();
        try {
            List<Map<String, Object>> messages = messageService.getChatHistory(userId, targetUserId);
            res.put("success", true);
            res.put("messages", messages);
        } catch (Exception e) {
            res.put("success", false);
            res.put("message", "获取消息列表失败: " + e.getMessage());
        }
        return res;
    }
    
    /**
     * 获取会话列表
     */
    @GetMapping("/conversations")
    public Map<String, Object> getConversations(@RequestParam String userId) {
        Map<String, Object> res = new HashMap<>();
        try {
            List<Map<String, Object>> conversations = messageService.getConversationList(userId);
            res.put("success", true);
            res.put("conversations", conversations);
        } catch (Exception e) {
            res.put("success", false);
            res.put("message", "获取会话列表失败: " + e.getMessage());
        }
        return res;
    }
    
    /**
     * 标记消息已读
     */
    @PostMapping("/read")
    public Map<String, Object> markAsRead(@RequestBody Map<String, String> request) {
        String userId = request.get("userId");
        String friendId = request.get("friendId");
        
        Map<String, Object> res = new HashMap<>();
        try {
            messageService.markChatAsRead(userId, friendId);
            res.put("success", true);
        } catch (Exception e) {
            res.put("success", false);
            res.put("message", "标记已读失败: " + e.getMessage());
        }
        return res;
    }
    
    /**
     * 获取未读消息数
     */
    @GetMapping("/unread-count")
    public Map<String, Object> getUnreadCount(@RequestParam String userId) {
        Map<String, Object> res = new HashMap<>();
        try {
            long count = messageService.getUnreadCount(userId);
            res.put("success", true);
            res.put("count", count);
        } catch (Exception e) {
            res.put("success", false);
            res.put("message", "获取未读数失败: " + e.getMessage());
        }
        return res;
    }
    
    /**
     * 获取与特定用户的未读消息数
     */
    @GetMapping("/unread")
    public Map<String, Object> getUnreadByUser(@RequestParam String userId, @RequestParam String targetUserId) {
        Map<String, Object> res = new HashMap<>();
        try {
            List<Map<String, Object>> messages = messageService.getChatHistory(userId, targetUserId);
            long unreadCount = messages.stream()
                .filter(msg -> msg.get("receiverId").equals(userId) && !(Boolean)msg.get("isRead"))
                .count();
            res.put("success", true);
            res.put("count", unreadCount);
        } catch (Exception e) {
            res.put("success", false);
            res.put("message", "获取未读数失败: " + e.getMessage());
        }
        return res;
    }
    
    /**
     * 获取最新消息
     */
    @GetMapping("/latest")
    public Map<String, Object> getLatestMessage(@RequestParam String userId, @RequestParam String targetUserId) {
        Map<String, Object> res = new HashMap<>();
        try {
            List<Map<String, Object>> messages = messageService.getChatHistory(userId, targetUserId);
            if (!messages.isEmpty()) {
                Map<String, Object> latest = messages.get(messages.size() - 1);
                res.put("success", true);
                res.put("message", latest);
            } else {
                res.put("success", true);
                res.put("message", null);
            }
        } catch (Exception e) {
            res.put("success", false);
            res.put("message", "获取最新消息失败: " + e.getMessage());
        }
        return res;
    }
    
    /**
     * 标记消息已读
     */
    @PostMapping("/markRead")
    public Map<String, Object> markMessagesAsRead(@RequestBody Map<String, String> request) {
        String userId = request.get("userId");
        String targetUserId = request.get("targetUserId");
        
        Map<String, Object> res = new HashMap<>();
        try {
            messageService.markChatAsRead(userId, targetUserId);
            res.put("success", true);
        } catch (Exception e) {
            res.put("success", false);
            res.put("message", "标记已读失败: " + e.getMessage());
        }
        return res;
    }
}
