package com.example.user_api.entity;

import jakarta.persistence.*;

@Entity
@Table(name = "likes",
        uniqueConstraints = @UniqueConstraint(columnNames = {"user_id", "post_id"}))
//@Getter @Setter @NoArgsConstructor
public class Like {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(name = "post_id", nullable = false)
    private Long postId;

    @Column(name = "create_time", nullable = false)
    private Long createTime;

    public Like() {}

    public void setUserId(Long userId) {
        this.userId = userId;
    }

    public void setPostId(Long postId) {
        this.postId = postId;
    }

    public void setCreateTime(Long createTime) {
        this.createTime = createTime;
    }

    public Long getPostId() {
        return postId;
    }

    public long getUserId() {
        return userId;
    }

    public long getCreateTime() {
        return createTime;
    }

    public long getId() {
        return id;
    }
}
