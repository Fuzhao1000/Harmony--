package com.example.user_api.controller;

import com.example.user_api.entity.Favorite;
import com.example.user_api.entity.Post;
import com.example.user_api.repository.PostRepository;
import com.example.user_api.service.PostService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import com.example.user_api.repository.FavoriteRepository;

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


        // 构造成前端需要的格式
        List<Map<String, Object>> result = posts.stream().map(p -> {
            Map<String, Object> m = new HashMap<>();
            m.put("id", p.getId());
            m.put("user", p.getUser());
            m.put("content", p.getContent());
            m.put("baname", p.getBaname());
            m.put("createTime", p.getCreateTime());

            m.put("likes", p.getLikes());
            m.put("comments", p.getComments());

            // ⭐⭐ 关键：加入 favorited 字段！
            m.put("favorited", favPostIds.contains(p.getId()));

            return m;
        }).toList();

        Map<String, Object> res = new HashMap<>();
        res.put("success", true);
        res.put("posts", posts);
        return res;
    }

    /**
     * 根据吧名获取帖子
     * 如：/api/post/listByBar?baname=学习吧
     */
    @GetMapping("/listByBar")
    public Map<String, Object> listByBar(@RequestParam String baname) {

        List<Post> posts = postService.findByBaname(baname);

        Map<String, Object> res = new HashMap<>();
        res.put("success", true);
        res.put("posts", posts);
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

        resp.put("success", true);
        resp.put("posts", posts);

        System.out.println("⭐ favList userId = " + userId);
        System.out.println("⭐ favList favs = " + favs);
        System.out.println("⭐ favList postIds = " + postIds);

        return resp;
    }

}
