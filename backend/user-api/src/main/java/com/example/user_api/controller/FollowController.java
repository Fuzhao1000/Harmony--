package com.example.user_api.controller;

import com.example.user_api.entity.User;
import com.example.user_api.service.FollowService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/follow")
public class FollowController {

    @Autowired
    private FollowService followService;

    /**
     * 切换关注状态
     */
    @PostMapping("/toggle")
    public Map<String, Object> toggleFollow(@RequestParam Long followerId, @RequestParam Long followingId) {
        Map<String, Object> result = new HashMap<>();
        
        try {
            boolean isFollowing = followService.toggleFollow(followerId, followingId);
            
            result.put("success", true);
            result.put("isFollowing", isFollowing);
            result.put("message", isFollowing ? "关注成功" : "取消关注");
            
            // 返回更新后的关注数和粉丝数
            result.put("followerFollowingCount", followService.getFollowingCount(followerId));
            result.put("followingFollowerCount", followService.getFollowerCount(followingId));
            
        } catch (Exception e) {
            result.put("success", false);
            result.put("message", e.getMessage());
        }
        
        return result;
    }

    /**
     * 检查是否已关注
     */
    @GetMapping("/check")
    public Map<String, Object> checkFollow(@RequestParam Long followerId, @RequestParam Long followingId) {
        Map<String, Object> result = new HashMap<>();
        
        boolean isFollowing = followService.isFollowing(followerId, followingId);
        
        result.put("success", true);
        result.put("isFollowing", isFollowing);
        
        return result;
    }

    /**
     * 获取用户的关注数和粉丝数
     */
    @GetMapping("/stats")
    public Map<String, Object> getFollowStats(@RequestParam Long userId) {
        Map<String, Object> result = new HashMap<>();
        
        long followingCount = followService.getFollowingCount(userId);
        long followerCount = followService.getFollowerCount(userId);
        
        result.put("success", true);
        result.put("followingCount", followingCount);
        result.put("followerCount", followerCount);
        
        return result;
    }

    /**
     * 获取关注列表
     */
    @GetMapping("/following-list")
    public Map<String, Object> getFollowingList(@RequestParam Long userId) {
        Map<String, Object> result = new HashMap<>();
        
        try {
            List<User> users = followService.getFollowingList(userId);
            List<Map<String, Object>> userList = new ArrayList<>();
            
            for (User user : users) {
                Map<String, Object> userMap = new HashMap<>();
                userMap.put("id", user.getId());
                userMap.put("name", user.getName());
                userMap.put("followingCount", user.getFollowingCount() != null ? user.getFollowingCount() : 0);
                userMap.put("followerCount", user.getFollowerCount() != null ? user.getFollowerCount() : 0);
                userList.add(userMap);
            }
            
            result.put("success", true);
            result.put("users", userList);
        } catch (Exception e) {
            result.put("success", false);
            result.put("message", e.getMessage());
        }
        
        return result;
    }

    /**
     * 获取粉丝列表
     */
    @GetMapping("/follower-list")
    public Map<String, Object> getFollowerList(@RequestParam Long userId) {
        Map<String, Object> result = new HashMap<>();
        
        try {
            List<User> users = followService.getFollowerList(userId);
            List<Map<String, Object>> userList = new ArrayList<>();
            
            for (User user : users) {
                Map<String, Object> userMap = new HashMap<>();
                userMap.put("id", user.getId());
                userMap.put("name", user.getName());
                userMap.put("followingCount", user.getFollowingCount() != null ? user.getFollowingCount() : 0);
                userMap.put("followerCount", user.getFollowerCount() != null ? user.getFollowerCount() : 0);
                userList.add(userMap);
            }
            
            result.put("success", true);
            result.put("users", userList);
        } catch (Exception e) {
            result.put("success", false);
            result.put("message", e.getMessage());
        }
        
        return result;
    }
}
