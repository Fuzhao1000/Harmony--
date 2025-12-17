package com.example.user_api.entity;

import jakarta.persistence.*;

@Entity
@Table(name = "posts")
public class Post {

    @Id

    private Long id;
    private String user;
    private String content;
    private String baname;   // 吧名（用于前端匹配图片）
    private Long createTime;
    private String image;
    private long likes;
    private long comments;

    public Post() {}

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getUser() {
        return user;
    }

    public void setUser(String user) {
        this.user = user;
    }



    public String getContent() {
        return content;
    }

    public void setContent(String content) {
        this.content = content;
    }

    public String getBaname() {
        return baname;
    }

    public void setBaname(String baname) {
        this.baname = baname;
    }

    public Long getCreateTime() {
        return createTime;
    }

    public void setCreateTime(Long createTime) {
        this.createTime = createTime;
    }

    public long getComments() {
        return comments;
    }

    public void setComments(long comments) {
        this.comments = comments;
    }

    public long getLikes() {
        return likes;
    }

    public void setLikes(long likes) {
        this.likes = likes;
    }

}
