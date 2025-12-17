package com.example.user_api.service.impl;

import com.example.user_api.entity.Favorite;
import com.example.user_api.repository.FavoriteRepository;
import com.example.user_api.service.FavoriteService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class FavoriteServiceImpl implements FavoriteService {

    @Autowired
    FavoriteRepository favoriteRepository;

    @Override
    public boolean toggleFavorite(String userId, Long postId) {

        boolean exists = favoriteRepository.existsByUserIdAndPostId(userId, postId);

        if (exists) {
            // 已收藏 → 取消收藏
            favoriteRepository.deleteByUserIdAndPostId(userId, postId);
            return false; // 取消收藏后状态
        } else {
            // 未收藏 → 新增收藏
            Favorite fav = new Favorite();
            fav.setUserId(userId);
            fav.setPostId(postId);
            fav.setCreateTime(System.currentTimeMillis());
            favoriteRepository.save(fav);
            return true; // 收藏后状态
        }
    }

    @Override
    public boolean isFavorite(String userId, Long postId) {
        return favoriteRepository.existsByUserIdAndPostId(userId, postId);
    }

    @Override
    public List<Favorite> getFavoritesByUser(String userId) {
        return favoriteRepository.findByUserId(userId);
    }
}
