package com.example.user_api.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "friends")
public class Friend {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(nullable = false)
    private String userId;  // 用户ID
    
    @Column(nullable = false)
    private String friendId;  // 好友ID
    
    @Column(nullable = false)
    private String friendName;  // 好友名称
    
    private String friendAvatar;  // 好友头像URL
    
    @Column(nullable = false)
    private Long createTime;  // 添加时间
    
    @Enumerated(EnumType.STRING)
    private FriendStatus status = FriendStatus.PENDING;  // 好友状态
    
    public enum FriendStatus {
        PENDING,   // 待确认
        ACCEPTED,  // 已接受
        REJECTED   // 已拒绝
    }
    
    // 构造函数
    public Friend() {}
    
    public Friend(String userId, String friendId, String friendName, String friendAvatar) {
        this.userId = userId;
        this.friendId = friendId;
        this.friendName = friendName;
        this.friendAvatar = friendAvatar;
        this.createTime = System.currentTimeMillis();
    }
    
    // Getters and Setters
    public Long getId() {
        return id;
    }
    
    public void setId(Long id) {
        this.id = id;
    }
    
    public String getUserId() {
        return userId;
    }
    
    public void setUserId(String userId) {
        this.userId = userId;
    }
    
    public String getFriendId() {
        return friendId;
    }
    
    public void setFriendId(String friendId) {
        this.friendId = friendId;
    }
    
    public String getFriendName() {
        return friendName;
    }
    
    public void setFriendName(String friendName) {
        this.friendName = friendName;
    }
    
    public String getFriendAvatar() {
        return friendAvatar;
    }
    
    public void setFriendAvatar(String friendAvatar) {
        this.friendAvatar = friendAvatar;
    }
    
    public Long getCreateTime() {
        return createTime;
    }
    
    public void setCreateTime(Long createTime) {
        this.createTime = createTime;
    }
    
    public FriendStatus getStatus() {
        return status;
    }
    
    public void setStatus(FriendStatus status) {
        this.status = status;
    }
}
