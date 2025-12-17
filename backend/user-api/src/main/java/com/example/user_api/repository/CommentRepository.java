package com.example.user_api.repository;

import com.example.user_api.entity.Comment;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface CommentRepository extends JpaRepository<Comment, Long> {

    // 查某个帖子的所有评论（按时间升序）
    List<Comment> findByPostIdOrderByCreateTimeAsc(Long postId);

    // 删除评论（仅本人）
    void deleteByIdAndUserId(Long id, Long userId);
}
