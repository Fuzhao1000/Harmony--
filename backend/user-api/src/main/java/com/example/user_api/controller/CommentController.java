package com.example.user_api.controller;

import com.example.user_api.entity.Comment;
import com.example.user_api.entity.CommentLike;
import com.example.user_api.entity.Post;
import com.example.user_api.entity.User;
import com.example.user_api.repository.CommentRepository;
import com.example.user_api.repository.CommentLikeRepository;
import com.example.user_api.repository.PostRepository;
import com.example.user_api.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.util.ArrayList;
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

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private CommentLikeRepository commentLikeRepository;

    /**
     * 获取某个帖子的评论列表
     */
    @GetMapping("/list")
    public Map<String, Object> list(@RequestParam Long postId, 
                                     @RequestParam(required = false) Long userId) {

        Map<String, Object> resp = new HashMap<>();

        List<Comment> comments =
                commentRepository.findByPostIdOrderByCreateTimeAsc(postId);

        // 构建包含用户名和点赞信息的评论列表
        List<Map<String, Object>> commentList = new ArrayList<>();
        for (Comment c : comments) {
            Map<String, Object> commentMap = new HashMap<>();
            commentMap.put("id", c.getId());
            commentMap.put("postId", c.getPostId());
            commentMap.put("userId", c.getUserId());
            commentMap.put("content", c.getContent());
            commentMap.put("createTime", c.getCreateTime());
            
            // 查询用户名
            User user = userRepository.findById(c.getUserId()).orElse(null);
            commentMap.put("userName", user != null ? user.getName() : "匿名用户");
            
            // 查询点赞数
            long likes = commentLikeRepository.countByCommentId(c.getId());
            commentMap.put("likes", likes);
            
            // 查询当前用户是否已点赞
            boolean liked = false;
            if (userId != null) {
                CommentLike commentLike = commentLikeRepository.findByCommentIdAndUserId(c.getId(), userId);
                liked = (commentLike != null);
            }
            commentMap.put("liked", liked);
            
            commentList.add(commentMap);
        }

        resp.put("success", true);
        resp.put("comments", commentList);
        return resp;
    }

    /**
     * 发表评论 - 支持URL参数和JSON两种方式
     */
    @PostMapping("/add")
    public Map<String, Object> add(
            @RequestParam(required = false) Long postId,
            @RequestParam(required = false) Long userId,
            @RequestParam(required = false) String content,
            @RequestBody(required = false) Map<String, Object> params) {

        Map<String, Object> resp = new HashMap<>();

        System.out.println("收到评论请求");
        System.out.println("URL参数 - postId: " + postId + ", userId: " + userId + ", content: " + content);
        System.out.println("请求体参数: " + params);

        try {
            // 优先使用URL参数，如果没有则使用请求体参数
            Long finalPostId = postId;
            Long finalUserId = userId;
            String finalContent = content;
            
            if (params != null && !params.isEmpty()) {
                if (finalPostId == null && params.containsKey("postId")) {
                    finalPostId = Long.parseLong(params.get("postId").toString());
                }
                if (finalUserId == null && params.containsKey("userId")) {
                    finalUserId = Long.parseLong(params.get("userId").toString());
                }
                if (finalContent == null && params.containsKey("content")) {
                    finalContent = params.get("content").toString();
                }
            }

            System.out.println("最终参数 - postId: " + finalPostId + ", userId: " + finalUserId + ", content: " + finalContent);

            if (finalContent == null || finalContent.trim().isEmpty()) {
                resp.put("success", false);
                resp.put("message", "评论内容不能为空");
                return resp;
            }

            Comment comment = new Comment();
            comment.setPostId(finalPostId);
            comment.setUserId(finalUserId);
            comment.setContent(finalContent);
            comment.setCreateTime(System.currentTimeMillis());

            commentRepository.save(comment);
            System.out.println("评论保存成功, ID: " + comment.getId());

            // 同步更新帖子评论数
            Post post = postRepository.findById(finalPostId).orElse(null);
            if (post != null) {
                post.setComments(post.getComments() + 1);
                postRepository.save(post);
                System.out.println("帖子评论数更新为: " + post.getComments());
            }

            resp.put("success", true);
            resp.put("commentId", comment.getId());
            resp.put("comments", post != null ? post.getComments() : 0);
            
            System.out.println("评论添加成功");
            return resp;
            
        } catch (Exception e) {
            System.err.println("评论添加失败: " + e.getMessage());
            e.printStackTrace();
            resp.put("success", false);
            resp.put("message", "服务器错误: " + e.getMessage());
            return resp;
        }
    }

    /**
     * 切换评论点赞
     */
    @PostMapping("/toggleLike")
    public Map<String, Object> toggleLike(@RequestParam Long userId,
                                          @RequestParam Long commentId) {

        Map<String, Object> resp = new HashMap<>();

        // 查询是否已点赞
        CommentLike existingLike = commentLikeRepository.findByCommentIdAndUserId(commentId, userId);

        if (existingLike != null) {
            // 已点赞 -> 取消点赞
            commentLikeRepository.deleteByCommentIdAndUserId(commentId, userId);
            resp.put("liked", false);
        } else {
            // 未点赞 -> 添加点赞
            CommentLike like = new CommentLike();
            like.setCommentId(commentId);
            like.setUserId(userId);
            like.setCreateTime(System.currentTimeMillis());
            commentLikeRepository.save(like);
            resp.put("liked", true);
        }

        // 返回最新的点赞数
        long likes = commentLikeRepository.countByCommentId(commentId);
        resp.put("likes", likes);
        resp.put("success", true);

        return resp;
    }

    /**
     * 删除评论（只能删自己的）
     */
    @Transactional
    @PostMapping("/delete")
    public Map<String, Object> delete(@RequestParam Long commentId,
                                      @RequestParam Long userId) {

        Map<String, Object> resp = new HashMap<>();

        commentRepository.deleteByIdAndUserId(commentId, userId);

        resp.put("success", true);
        return resp;
    }
}
