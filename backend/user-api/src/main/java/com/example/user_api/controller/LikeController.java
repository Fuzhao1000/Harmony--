package com.example.user_api.controller;

import com.example.user_api.entity.Like;
import com.example.user_api.entity.Post;
import com.example.user_api.repository.LikeRepository;
import com.example.user_api.repository.PostRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import org.springframework.transaction.annotation.Transactional;
import javax.sql.DataSource;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/like")
public class LikeController {

    @Autowired
    private LikeRepository likeRepository;

    @Autowired
    private PostRepository postRepository;

    @Autowired
    private DataSource dataSource;
    /**
     * 点赞/取消点赞
     * userId: 用户 ID
     * postId: 帖子 ID
     */
    @PostMapping("/toggleLike")
    @Transactional
    public Map<String, Object> toggleLike(@RequestParam Long userId,
                                          @RequestParam Long postId) {

        Map<String, Object> resp = new HashMap<>();

        System.out.println("=== toggleLike 请求 ===");
        System.out.println("userId = " + userId);
        System.out.println("postId = " + postId);

        // 检查帖子是否存在
        Post post = postRepository.findById(postId).orElse(null);
        if (post == null) {
            resp.put("success", false);
            resp.put("msg", "帖子不存在 postId=" + postId);
            return resp;
        }

        // 是否已经点赞
        boolean liked = likeRepository.existsByUserIdAndPostId(userId, postId);
        System.out.println("是否已点赞 = " + liked);

        System.out.println("Datasource: " + dataSource);
        if (liked) {
            // 取消点赞
            likeRepository.deleteByUserIdAndPostId(userId, postId);

            long newLikes = Math.max(0, post.getLikes() - 1);
            post.setLikes(newLikes);
            postRepository.save(post);

            resp.put("liked", false);
            resp.put("likes", newLikes);

            System.out.println("已取消点赞，新点赞数 = " + newLikes);

        } else {
            // 点赞
            Like like = new Like();
            like.setUserId(userId);
            like.setPostId(postId);
            like.setCreateTime(System.currentTimeMillis());
            System.out.println("准备保存 Like 对象: userId=" + like.getUserId()
                    + ", postId=" + like.getPostId() + ", createTime=" + like.getCreateTime());

            likeRepository.save(like);

            long newLikes = post.getLikes() + 1;
            post.setLikes(newLikes);
            postRepository.save(post);

            resp.put("liked", true);
            resp.put("likes", newLikes);

            System.out.println("点赞成功，新点赞数 = " + newLikes);
        }

        resp.put("success", true);
        return resp;
    }

    @GetMapping("/list")
    public Map<String, Object> list(@RequestParam Long userId) {
        Map<String, Object> resp = new HashMap<>();

        List<Like> likes = likeRepository.findByUserId(userId);
        List<Long> likedPostIds = likes.stream()
                .map(Like::getPostId)
                .toList();

        resp.put("success", true);
        resp.put("likedPostIds", likedPostIds);

        return resp;
    }


}
