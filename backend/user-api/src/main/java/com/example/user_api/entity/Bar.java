package com.example.user_api.entity;

import jakarta.persistence.*;

@Entity
@Table(name = "bars")
public class Bar {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String baname;

    private int memberCount;
    private int postCount;

    public Bar() {}
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getName() { return baname; }
    public void setName(String name) { this.baname = name; }
    public Integer getMemberCount() { return memberCount; }
    public void setMemberCount(Integer memberCount) { this.memberCount = memberCount; }

    public Integer getPostCount() { return postCount; }
    public void setPostCount(Integer postCount) { this.postCount = postCount; }
}
