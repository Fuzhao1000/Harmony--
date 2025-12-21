package com.example.user_api.controller;

import com.example.user_api.service.FriendService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.*;

@RestController
@RequestMapping("/api/friend")
public class FriendController {
    
    @Autowired
    private FriendService friendService;
    
    /**
     * 添加好友
     */
    @PostMapping("/add")
    public Map<String, Object> addFriend(@RequestBody Map<String, String> request) {
        String userId = request.get("userId");
        String friendId = request.get("friendId");
        String friendName = request.get("friendName");
        String friendAvatar = request.get("friendAvatar");
        
        Map<String, Object> res = new HashMap<>();
        try {
            friendService.addFriend(userId, friendId, friendName, friendAvatar);
            res.put("success", true);
            res.put("message", "添加好友成功");
        } catch (Exception e) {
            res.put("success", false);
            res.put("message", "添加好友失败: " + e.getMessage());
        }
        return res;
    }
    
    /**
     * 获取好友列表
     */
    @GetMapping("/list")
    public Map<String, Object> getFriendList(@RequestParam String userId) {
        Map<String, Object> res = new HashMap<>();
        try {
            List<Map<String, Object>> friends = friendService.getFriendList(userId);
            res.put("success", true);
            res.put("friends", friends);
        } catch (Exception e) {
            res.put("success", false);
            res.put("message", "获取好友列表失败: " + e.getMessage());
        }
        return res;
    }
    
    /**
     * 删除好友
     */
    @DeleteMapping("/delete")
    public Map<String, Object> deleteFriend(@RequestParam String userId, @RequestParam String friendId) {
        Map<String, Object> res = new HashMap<>();
        boolean success = friendService.deleteFriend(userId, friendId);
        res.put("success", success);
        res.put("message", success ? "删除好友成功" : "删除好友失败");
        return res;
    }
    
    /**
     * 检查是否是好友
     */
    @GetMapping("/check")
    public Map<String, Object> checkFriend(@RequestParam String userId, @RequestParam String friendId) {
        Map<String, Object> res = new HashMap<>();
        boolean isFriend = friendService.isFriend(userId, friendId);
        res.put("success", true);
        res.put("isFriend", isFriend);
        return res;
    }
}
