package com.example.user_api.controller;

import com.example.user_api.entity.Favorite;
import com.example.user_api.entity.Post;
import com.example.user_api.repository.FavoriteRepository;
import com.example.user_api.repository.PostRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.*;

@RestController
@RequestMapping("/api/favorite")
public class FavoriteController {

    @Autowired
    private FavoriteRepository favoriteRepository;

    @Autowired
    private PostRepository postRepository;

    // 收藏 或 取消收藏
    @PostMapping("/toggle")
    public Map<String, Object> toggleFavorite(@RequestBody Map<String, Object> req) {

        String userId = req.get("userId").toString();
        Long postId = Long.parseLong(req.get("postId").toString());

        Optional<Favorite> f = favoriteRepository.findByUserIdAndPostId(userId, postId);

        Map<String, Object> res = new HashMap<>();

        if (f.isPresent()) {
            // 已收藏 → 取消收藏
            favoriteRepository.delete(f.get());
            res.put("favorited", false);
        } else {
            // 未收藏 → 收藏
            Favorite fav = new Favorite();
            fav.setUserId(userId);
            fav.setPostId(postId);
            fav.setCreateTime(System.currentTimeMillis());
            favoriteRepository.save(fav);
            res.put("favorited", true);
        }

        res.put("success", true);
        return res;
    }

    // 获取用户收藏数据
    @GetMapping("/list")
    public Map<String, Object> list(@RequestParam String userId) {
        System.out.println("收到 userId = " + userId);
        List<Favorite> favs = favoriteRepository.findByUserId(userId);

        System.out.println("查询到的收藏记录 = " + favs);
        List<Long> ids = null;
        if (favs != null) {
            ids = favs.stream()
                    .map(Favorite::getPostId)
                    .toList();
        }

        Map<String, Object> result = new HashMap<>();
        result.put("success", true);
        result.put("favoritePostIds", ids);
        return result;
    }

}
