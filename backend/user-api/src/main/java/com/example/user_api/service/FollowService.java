package com.example.user_api.service;

import com.example.user_api.entity.Follow;
import com.example.user_api.entity.User;
import com.example.user_api.repository.FollowRepository;
import com.example.user_api.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

@Service
public class FollowService {

    @Autowired
    private FollowRepository followRepository;

    @Autowired
    private UserRepository userRepository;

    /**
     * 切换关注状态（关注/取消关注）
     * @param followerId 关注者ID
     * @param followingId 被关注者ID
     * @return true表示当前已关注，false表示已取消关注
     */
    @Transactional
    public boolean toggleFollow(Long followerId, Long followingId) {
        // 不能关注自己
        if (followerId.equals(followingId)) {
            throw new IllegalArgumentException("不能关注自己");
        }

        // 检查是否已经关注
        Optional<Follow> existingFollow = followRepository.findByFollowerIdAndFollowingId(followerId, followingId);

        if (existingFollow.isPresent()) {
            // 已关注，则取消关注
            followRepository.delete(existingFollow.get());
            
            // 更新用户的关注数和粉丝数
            updateUserCounts(followerId, followingId, false);
            
            return false; // 返回false表示已取消关注
        } else {
            // 未关注，则添加关注
            Follow follow = new Follow();
            follow.setFollowerId(followerId);
            follow.setFollowingId(followingId);
            followRepository.save(follow);
            
            // 更新用户的关注数和粉丝数
            updateUserCounts(followerId, followingId, true);
            
            return true; // 返回true表示已关注
        }
    }

    /**
     * 检查是否已关注
     */
    public boolean isFollowing(Long followerId, Long followingId) {
        return followRepository.existsByFollowerIdAndFollowingId(followerId, followingId);
    }

    /**
     * 获取关注数
     */
    public long getFollowingCount(Long userId) {
        return followRepository.countByFollowerId(userId);
    }

    /**
     * 获取粉丝数
     */
    public long getFollowerCount(Long userId) {
        return followRepository.countByFollowingId(userId);
    }

    /**
     * 获取关注列表（用户关注的人）
     */
    public List<User> getFollowingList(Long userId) {
        List<Follow> follows = followRepository.findByFollowerId(userId);
        List<User> users = new ArrayList<>();
        
        for (Follow follow : follows) {
            Optional<User> userOpt = userRepository.findById(follow.getFollowingId());
            userOpt.ifPresent(users::add);
        }
        
        return users;
    }

    /**
     * 获取粉丝列表（关注该用户的人）
     */
    public List<User> getFollowerList(Long userId) {
        List<Follow> follows = followRepository.findByFollowingId(userId);
        List<User> users = new ArrayList<>();
        
        for (Follow follow : follows) {
            Optional<User> userOpt = userRepository.findById(follow.getFollowerId());
            userOpt.ifPresent(users::add);
        }
        
        return users;
    }

    /**
     * 更新用户的关注数和粉丝数
     */
    private void updateUserCounts(Long followerId, Long followingId, boolean isFollow) {
        // 更新关注者的关注数
        Optional<User> followerOpt = userRepository.findById(followerId);
        if (followerOpt.isPresent()) {
            User follower = followerOpt.get();
            // 处理null值，如果为null则初始化为0
            Integer followingCount = follower.getFollowingCount();
            int count = (followingCount != null) ? followingCount : 0;
            follower.setFollowingCount(isFollow ? count + 1 : Math.max(0, count - 1));
            userRepository.save(follower);
        }

        // 更新被关注者的粉丝数
        Optional<User> followingOpt = userRepository.findById(followingId);
        if (followingOpt.isPresent()) {
            User following = followingOpt.get();
            // 处理null值，如果为null则初始化为0
            Integer followerCount = following.getFollowerCount();
            int count = (followerCount != null) ? followerCount : 0;
            following.setFollowerCount(isFollow ? count + 1 : Math.max(0, count - 1));
            userRepository.save(following);
        }
    }
}
