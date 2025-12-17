package com.example.user_api.service;

import com.example.user_api.entity.Favorite;

import java.util.List;

public interface FavoriteService {

    boolean toggleFavorite(String userId, Long postId);

    boolean isFavorite(String userId, Long postId);

    List<Favorite> getFavoritesByUser(String userId);
}
