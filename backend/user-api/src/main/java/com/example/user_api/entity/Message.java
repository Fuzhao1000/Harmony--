package com.example.user_api.entity;

import jakarta.persistence.*;

@Entity
@Table(name = "messages")
public class Message {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(nullable = false)
    private String senderId;  // 发送者ID
    
    @Column(nullable = false)
    private String receiverId;  // 接收者ID
    
    @Column(nullable = false, length = 1000)
    private String content;  // 消息内容
    
    @Column(nullable = false)
    private Long createTime;  // 发送时间
    
    private Boolean isRead = false;  // 是否已读
    
    @Enumerated(EnumType.STRING)
    private MessageType type = MessageType.TEXT;  // 消息类型
    
    public enum MessageType {
        TEXT,     // 文本消息
        IMAGE,    // 图片消息
        SYSTEM    // 系统消息
    }
    
    // 构造函数
    public Message() {}
    
    public Message(String senderId, String receiverId, String content) {
        this.senderId = senderId;
        this.receiverId = receiverId;
        this.content = content;
        this.createTime = System.currentTimeMillis();
    }
    
    // Getters and Setters
    public Long getId() {
        return id;
    }
    
    public void setId(Long id) {
        this.id = id;
    }
    
    public String getSenderId() {
        return senderId;
    }
    
    public void setSenderId(String senderId) {
        this.senderId = senderId;
    }
    
    public String getReceiverId() {
        return receiverId;
    }
    
    public void setReceiverId(String receiverId) {
        this.receiverId = receiverId;
    }
    
    public String getContent() {
        return content;
    }
    
    public void setContent(String content) {
        this.content = content;
    }
    
    public Long getCreateTime() {
        return createTime;
    }
    
    public void setCreateTime(Long createTime) {
        this.createTime = createTime;
    }
    
    public Boolean getIsRead() {
        return isRead;
    }
    
    public void setIsRead(Boolean isRead) {
        this.isRead = isRead;
    }
    
    public MessageType getType() {
        return type;
    }
    
    public void setType(MessageType type) {
        this.type = type;
    }
}
