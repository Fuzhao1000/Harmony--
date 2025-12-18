package com.example.user_api.repository;

import com.example.user_api.entity.CommentLike;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

public interface CommentLikeRepository extends JpaRepository<CommentLike, Long> {

    // 查询某用户是否点赞了某评论
    CommentLike findByCommentIdAndUserId(Long commentId, Long userId);

    // 统计某评论的点赞数
    long countByCommentId(Long commentId);

    // 删除某用户对某评论的点赞
    @Transactional
    void deleteByCommentIdAndUserId(Long commentId, Long userId);

    // 获取某用户点赞的所有评论ID列表
    List<CommentLike> findByUserId(Long userId);
}
