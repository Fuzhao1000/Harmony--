package com.example.user_api.service;

import com.example.user_api.entity.Friend;
import com.example.user_api.repository.FriendRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.*;
import java.util.stream.Collectors;

@Service
public class FriendService {
    
    @Autowired
    private FriendRepository friendRepository;
    
    /**
     * 添加好友请求
     */
    public Friend addFriend(String userId, String friendId, String friendName, String friendAvatar) {
        // 检查是否已经存在好友关系
        Optional<Friend> existing = friendRepository.findByUserIdAndFriendId(userId, friendId);
        if (existing.isPresent()) {
            return existing.get();
        }
        
        Friend friend = new Friend(userId, friendId, friendName, friendAvatar);
        friend.setStatus(Friend.FriendStatus.ACCEPTED);  // 简化流程，直接接受
        
        // 同时创建双向好友关系
        friendRepository.save(friend);
        
        // 创建反向好友关系
        Friend reverseFriend = new Friend(friendId, userId, "", "");
        reverseFriend.setStatus(Friend.FriendStatus.ACCEPTED);
        friendRepository.save(reverseFriend);
        
        return friend;
    }
    
    /**
     * 获取用户的好友列表
     */
    public List<Map<String, Object>> getFriendList(String userId) {
        List<Friend> friends = friendRepository.findByUserIdAndStatus(userId, Friend.FriendStatus.ACCEPTED);
        
        return friends.stream().map(friend -> {
            Map<String, Object> map = new HashMap<>();
            map.put("id", friend.getId());
            map.put("friendId", friend.getFriendId());
            map.put("friendName", friend.getFriendName());
            map.put("friendAvatar", friend.getFriendAvatar());
            map.put("createTime", friend.getCreateTime());
            return map;
        }).collect(Collectors.toList());
    }
    
    /**
     * 删除好友
     */
    public boolean deleteFriend(String userId, String friendId) {
        Optional<Friend> friend = friendRepository.findByUserIdAndFriendId(userId, friendId);
        if (friend.isPresent()) {
            friendRepository.delete(friend.get());
            
            // 同时删除反向关系
            Optional<Friend> reverseFriend = friendRepository.findByUserIdAndFriendId(friendId, userId);
            reverseFriend.ifPresent(f -> friendRepository.delete(f));
            
            return true;
        }
        return false;
    }
    
    /**
     * 检查是否是好友
     */
    public boolean isFriend(String userId, String friendId) {
        Optional<Friend> friend = friendRepository.findByUserIdAndFriendId(userId, friendId);
        return friend.isPresent() && friend.get().getStatus() == Friend.FriendStatus.ACCEPTED;
    }
}
