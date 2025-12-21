package com.example.user_api.controller;

import com.example.user_api.entity.Favorite;
import com.example.user_api.entity.Post;
import com.example.user_api.entity.User;
import com.example.user_api.repository.PostRepository;
import com.example.user_api.repository.UserRepository;
import com.example.user_api.service.PostService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import com.example.user_api.repository.FavoriteRepository;
import com.example.user_api.repository.LikeRepository;
import com.example.user_api.entity.Like;

import javax.print.DocFlavor;
import java.util.*;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/post")
public class PostController {

    @Autowired
    private PostService postService;
    @Autowired
    private FavoriteRepository favoriteRepository;
    @Autowired
    private PostRepository postRepository;
    @Autowired
    private LikeRepository likeRepository;
    @Autowired
    private UserRepository userRepository;

    /**
     * 发布帖子
     */
    @PostMapping("/publish")
    public Map<String, Object> publish(@RequestBody Post post) {

        // 设置发布时间
        post.setCreateTime(System.currentTimeMillis());

        Post saved = postService.publish(post);

        Map<String, Object> res = new HashMap<>();
        res.put("success", true);
        res.put("id", saved.getId());
        return res;
    }

    /**
     * 编辑帖子
     */
    @PutMapping("/update")
    public Map<String, Object> updatePost(@RequestBody Post post, @RequestParam Long userId) {
        Map<String, Object> res = new HashMap<>();
        
        try {
            // 查找原帖子
            Optional<Post> existingPost = postRepository.findById(post.getId());
            
            if (!existingPost.isPresent()) {
                res.put("success", false);
                res.put("message", "帖子不存在");
                return res;
            }
            
            Post originalPost = existingPost.get();
            
            // 验证是否是帖子作者
            if (!Objects.equals(originalPost.getUserId(), userId)) {
                res.put("success", false);
                res.put("message", "无权编辑此帖子");
                return res;
            }
            
            // 更新帖子内容
            originalPost.setContent(post.getContent());
            if (post.getBaname() != null) {
                originalPost.setBaname(post.getBaname());
            }
            
            Post updated = postRepository.save(originalPost);
            
            res.put("success", true);
            res.put("post", updated);
            return res;
            
        } catch (Exception e) {
            res.put("success", false);
            res.put("message", "更新失败: " + e.getMessage());
            return res;
        }
    }

    /**
     * 删除帖子
     */
    @DeleteMapping("/delete")
    public Map<String, Object> deletePost(@RequestParam Long postId, @RequestParam Long userId) {
        Map<String, Object> res = new HashMap<>();
        
        try {
            Optional<Post> existingPost = postRepository.findById(postId);
            
            if (!existingPost.isPresent()) {
                res.put("success", false);
                res.put("message", "帖子不存在");
                return res;
            }
            
            Post post = existingPost.get();
            
            // 验证是否是帖子作者
            if (!Objects.equals(post.getUserId(), userId)) {
                res.put("success", false);
                res.put("message", "无权删除此帖子");
                return res;
            }
            
            // 删除帖子
            postRepository.deleteById(postId);
            
            res.put("success", true);
            res.put("message", "删除成功");
            return res;
            
        } catch (Exception e) {
            res.put("success", false);
            res.put("message", "删除失败: " + e.getMessage());
            return res;
        }
    }

    /**
     * 获取所有帖子（按时间倒序）
     */
    @GetMapping("/list")
    public Map<String, Object> list(@RequestParam("userId") String userId) {

        List<Post> posts = postService.findAll();

        // 用户已收藏的 postId 列表
        Set<Long> favPostIds = Optional.ofNullable(favoriteRepository.findByUserId(userId))
                .orElse(Collections.emptyList())
                .stream()
                .map(Favorite::getPostId)
                .collect(Collectors.toSet());

        // 获取所有用户ID
        Set<Long> userIds = posts.stream()
                .map(Post::getUserId)
                .filter(Objects::nonNull)
                .collect(Collectors.toSet());
        
        // 批量查询用户信息
        Map<Long, String> userIdToNameMap = userRepository.findAllById(userIds)
                .stream()
                .collect(Collectors.toMap(User::getId, User::getName));

        // 构造成前端需要的格式
        List<Map<String, Object>> result = posts.stream().map(p -> {
            Map<String, Object> m = new HashMap<>();
            m.put("id", p.getId());
            m.put("userId", p.getUserId());  // ★ 添加userId字段用于前端权限判断
            m.put("user", userIdToNameMap.getOrDefault(p.getUserId(), "未知用户"));  // 通过userId查询用户名
            m.put("content", p.getContent());
            m.put("baname", p.getBaname());
            m.put("createTime", p.getCreateTime());
            m.put("likes", p.getLikes());
            m.put("comments", p.getComments());
            m.put("favorited", favPostIds.contains(p.getId()));
            return m;
        }).toList();

        Map<String, Object> res = new HashMap<>();
        res.put("success", true);
        res.put("posts", result);
        return res;
    }

    /**
     * 根据吧名获取帖子
     * 如：/api/post/listByBar?baname=学习吧&userId=1
     */
    @GetMapping("/listByBar")
    public Map<String, Object> listByBar(@RequestParam String baname, @RequestParam(required = false) Long userId) {

        List<Post> posts = postService.findByBaname(baname);

        // 如果提供了userId，获取点赞和收藏信息
        Set<Long> likedPostIds = new HashSet<>();
        Set<Long> favPostIds = new HashSet<>();
        
        if (userId != null) {
            // 获取用户点赞的帖子ID列表
            likedPostIds = likeRepository.findByUserId(userId)
                .stream()
                .map(Like::getPostId)
                .collect(Collectors.toSet());
            
            // 获取用户收藏的帖子ID列表
            favPostIds = favoriteRepository.findByUserId(String.valueOf(userId))
                .stream()
                .map(Favorite::getPostId)
                .collect(Collectors.toSet());
        }
        
        // 获取所有用户ID
        Set<Long> userIds = posts.stream()
                .map(Post::getUserId)
                .filter(Objects::nonNull)
                .collect(Collectors.toSet());
        
        // 批量查询用户信息
        Map<Long, String> userIdToNameMap = userRepository.findAllById(userIds)
                .stream()
                .collect(Collectors.toMap(User::getId, User::getName));

        // 构造返回数据，包含点赞和收藏状态
        List<Map<String, Object>> result = new ArrayList<>();
        for (Post p : posts) {
            Map<String, Object> m = new HashMap<>();
            m.put("id", p.getId());
            m.put("userId", p.getUserId());  // ★ 添加userId字段用于前端权限判断
            m.put("user", userIdToNameMap.getOrDefault(p.getUserId(), "未知用户"));  // 通过userId查询用户名
            m.put("content", p.getContent());
            m.put("baname", p.getBaname());
            m.put("createTime", p.getCreateTime());
            m.put("likes", p.getLikes());
            m.put("comments", p.getComments());
            
            if (userId != null) {
                m.put("liked", likedPostIds.contains(p.getId()));
                m.put("favorited", favPostIds.contains(p.getId()));
            }
            
            result.add(m);
        }

        Map<String, Object> res = new HashMap<>();
        res.put("success", true);
        res.put("posts", result);
        return res;
    }
    @GetMapping("/favList")
    public Map<String, Object> favList(@RequestParam String userId) {

        Map<String, Object> resp = new HashMap<>();

        // 1. 查询收藏记录
        List<Favorite> favs = favoriteRepository.findByUserId(userId);

        // 2. 提取收藏的 postId
        List<Long> postIds = favs.stream()
                .map(Favorite::getPostId)
                .toList();

        // 3. 查询帖子
        List<Post> posts = postRepository.findAllById(postIds);
        
        // 4. 获取所有用户ID并批量查询用户信息
        Set<Long> userIds = posts.stream()
                .map(Post::getUserId)
                .filter(Objects::nonNull)
                .collect(Collectors.toSet());
        
        Map<Long, String> userIdToNameMap = userRepository.findAllById(userIds)
                .stream()
                .collect(Collectors.toMap(User::getId, User::getName));
        
        // 5. 构造返回结果，包含用户名
        List<Map<String, Object>> result = posts.stream().map(p -> {
            Map<String, Object> m = new HashMap<>();
            m.put("id", p.getId());
            m.put("userId", p.getUserId());  // ★ 添加userId字段用于前端权限判断
            m.put("user", userIdToNameMap.getOrDefault(p.getUserId(), "未知用户"));
            m.put("content", p.getContent());
            m.put("baname", p.getBaname());
            m.put("createTime", p.getCreateTime());
            m.put("likes", p.getLikes());
            m.put("comments", p.getComments());
            return m;
        }).toList();

        resp.put("success", true);
        resp.put("posts", result);

        return resp;
    }

    /**
     * 获取所有吧的统计信息
     * 返回每个吧的帖子数量
     */
    @GetMapping("/barStats")
    public Map<String, Object> getBarStats() {
        List<Post> allPosts = postService.findAll();
        
        // 按吧名分组统计帖子数量
        Map<String, Long> barPostCounts = allPosts.stream()
            .collect(Collectors.groupingBy(Post::getBaname, Collectors.counting()));
        
        // 构造返回结果
        List<Map<String, Object>> stats = new ArrayList<>();
        for (Map.Entry<String, Long> entry : barPostCounts.entrySet()) {
            Map<String, Object> stat = new HashMap<>();
            stat.put("baname", entry.getKey());
            stat.put("postCount", entry.getValue());
            stat.put("memberCount", 0); // 暂时返回0，后续可以实现
            stats.add(stat);
        }
        
        Map<String, Object> res = new HashMap<>();
        res.put("success", true);
        res.put("stats", stats);
        return res;
    }

}
