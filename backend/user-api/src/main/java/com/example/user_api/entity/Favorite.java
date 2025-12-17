package com.example.user_api.entity;

import jakarta.persistence.*;

@Entity
@Table(name = "favorites", uniqueConstraints = {
        @UniqueConstraint(columnNames = {"user_id", "post_id"})
})
public class Favorite {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id")   // ⭐⭐ 必须写
    private String userId;

    @Column(name = "post_id")   // ⭐⭐ 必须写
    private Long postId;

    @Column(name = "create_time") // 可选写
    private Long createTime;

    public Long getId() {
        return id;
    }

    public String getUserId() {
        return userId;
    }

    public void setUserId(String userId) {
        this.userId = userId;   // ⭐ 正常赋值
    }

    public Long getPostId() {
        return postId;
    }

    public void setPostId(Long postId) {
        this.postId = postId;   // ⭐ 正常赋值
    }

    public Long getCreateTime() {
        return createTime;
    }

    public void setCreateTime(Long createTime) {
        this.createTime = createTime;  // ⭐ 正常赋值
    }

    // getter setter略
}
