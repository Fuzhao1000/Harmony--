package com.example.user_api.service;

import com.example.user_api.entity.User;
import com.example.user_api.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.Optional;

@Service
public class UserService {

    @Autowired
    private UserRepository userRepository;

    private final BCryptPasswordEncoder encoder = new BCryptPasswordEncoder();

    // 登录
    public User login(String phone, String rawPassword) {
        User user = userRepository.findByPhone(phone);
        if (user == null) {
            return null;
        }

        // 密码校验（放这里才对）
        if (encoder.matches(rawPassword, user.getPassword())) {
            return user;
        }

        return null;
    }

    // 注册
    public boolean register(String phone, String rawPassword) {

        // 手机号重复不能注册
        if (userRepository.existsByPhone(phone)) {
            return false;
        }

        User user = new User();
        user.setPhone(phone);
        user.setPassword(encoder.encode(rawPassword)); // BCrypt 加密
        user.setName("默认用户");

        userRepository.save(user);
        return true;
    }

    // 更新名字
    public boolean updateName(Long id, String name) {
        Optional<User> optional = userRepository.findById(id);
        if (optional.isEmpty()) {
            return false;
        }
        User user = optional.get();
        user.setName(name);
        userRepository.save(user);
        return true;
    }
    
    // 根据ID获取用户
    public User getUserById(Long id) {
        return userRepository.findById(id).orElse(null);
    }
}
