package com.example.user_api.controller;

import com.example.user_api.entity.Comment;
import com.example.user_api.entity.Post;
import com.example.user_api.repository.CommentRepository;
import com.example.user_api.repository.PostRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/comment")
public class CommentController {

    @Autowired
    private CommentRepository commentRepository;

    @Autowired
    private PostRepository postRepository;

    /**
     * 获取某个帖子的评论列表
     */
    @GetMapping("/list")
    public Map<String, Object> list(@RequestParam Long postId) {

        Map<String, Object> resp = new HashMap<>();

        List<Comment> comments =
                commentRepository.findByPostIdOrderByCreateTimeAsc(postId);

        resp.put("success", true);
        resp.put("comments", comments);
        return resp;
    }

    /**
     * 发表评论
     */
    @PostMapping("/add")
    public Map<String, Object> add(@RequestParam Long postId,
                                   @RequestParam Long userId,
                                   @RequestParam String content) {

        Map<String, Object> resp = new HashMap<>();

        if (content == null || content.trim().isEmpty()) {
            resp.put("success", false);
            resp.put("msg", "评论内容不能为空");
            return resp;
        }

        Comment comment = new Comment();
        comment.setPostId(postId);
        comment.setUserId(userId);
        comment.setContent(content);
        comment.setCreateTime(System.currentTimeMillis());

        commentRepository.save(comment);

        // 2️⃣ 同步更新帖子评论数 ⭐⭐⭐
        Post post = postRepository.findById(postId).orElse(null);
        if (post != null) {
            post.setComments(post.getComments() + 1);
            postRepository.save(post);
        }

        resp.put("success", true);
        resp.put("commentId", comment.getId());
        resp.put("comments", post != null ? post.getComments() : 0);
        return resp;
    }

    /**
     * 删除评论（只能删自己的）
     */
    @PostMapping("/delete")
    public Map<String, Object> delete(@RequestParam Long id,
                                      @RequestParam Long userId) {

        Map<String, Object> resp = new HashMap<>();

        commentRepository.deleteByIdAndUserId(id, userId);

        resp.put("success", true);
        return resp;
    }
}
